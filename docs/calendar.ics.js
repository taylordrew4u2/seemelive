/**
 * Calendar ICS Feed Generator
 * 
 * This file can be deployed as a serverless function or static generator
 * to create an iCalendar feed from the CloudKit public database.
 * 
 * Usage: Deploy to Vercel or similar, then access:
 *   https://yourdomain.com/api/calendar.ics?user=USER_ID
 */

const CloudKit = require('cloudkit');

// Configure CloudKit (requires environment variables)
const container = CloudKit.configure({
    containers: [{
        containerIdentifier: 'iCloud.comedy.SEE-ME-LIVE',
        apiTokenAuth: {
            apiToken: process.env.CLOUDKIT_API_TOKEN || '973fea23642dcde5150a44716fa5b34bc7b1d4502f37851654e926d675fe7132'
        },
        environment: 'production'
    }]
});

/**
 * Generates an iCalendar (ICS) file from CloudKit records
 */
async function generateCalendarFeed(userID) {
    const db = container.publicCloudDatabase;
    
    try {
        const query = {
            recordType: 'PublicShow',
            filterBy: [{
                fieldName: 'userID',
                comparator: 'EQUALS',
                fieldValue: { value: userID }
            }],
            sortBy: [{ fieldName: 'date', ascending: true }]
        };

        const response = await db.performQuery(query);
        const records = response.records || [];

        // Generate ICS file
        let ics = `BEGIN:VCALENDAR\r\n`;
        ics += `VERSION:2.0\r\n`;
        ics += `PRODID:-//SEE ME LIVE//Calendar//EN\r\n`;
        ics += `CALSCALE:GREGORIAN\r\n`;
        ics += `METHOD:PUBLISH\r\n`;
        ics += `X-WR-CALNAME:SEE ME LIVE - Upcoming Shows\r\n`;
        ics += `X-WR-TIMEZONE:UTC\r\n`;
        ics += `REFRESH-INTERVAL;VALUE=DURATION:PT1H\r\n`;

        records.forEach(record => {
            const f = record.fields;
            const title = f.title?.value || 'Show';
            const venue = f.venue?.value || '';
            const date = f.date?.value ? new Date(f.date.value) : new Date();
            const notes = f.notes?.value || '';
            const role = f.role?.value || '';

            // Format date for ICS (YYYYMMDDTHHMMSSZ)
            const dateStr = date.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z';
            
            // Create event
            ics += `BEGIN:VEVENT\r\n`;
            ics += `UID:${record.recordID.recordName}@seemelive.local\r\n`;
            ics += `DTSTAMP:${new Date().toISOString().replace(/[-:]/g, '').split('.')[0]}Z\r\n`;
            ics += `DTSTART:${dateStr}\r\n`;
            ics += `SUMMARY:${escapeICS(title)}${role ? ` (${escapeICS(role)})` : ''}\r\n`;
            
            if (venue) {
                ics += `LOCATION:${escapeICS(venue)}\r\n`;
            }
            
            if (notes) {
                ics += `DESCRIPTION:${escapeICS(notes)}\r\n`;
            }

            // Add ticket link as URL property
            if (f.ticketLink?.value) {
                ics += `URL:${f.ticketLink.value}\r\n`;
            }

            ics += `END:VEVENT\r\n`;
        });

        ics += `END:VCALENDAR\r\n`;

        return ics;

    } catch (error) {
        console.error('Error fetching CloudKit data:', error);
        throw error;
    }
}

/**
 * Escapes special characters for ICS format
 */
function escapeICS(str) {
    if (!str) return '';
    return str
        .replace(/\\/g, '\\\\')
        .replace(/;/g, '\\;')
        .replace(/,/g, '\\,')
        .replace(/\n/g, '\\n');
}

/**
 * Vercel Serverless Function Handler
 */
module.exports = async (req, res) => {
    const { user } = req.query;

    if (!user) {
        return res.status(400).json({ error: 'Missing user parameter' });
    }

    try {
        const icsContent = await generateCalendarFeed(user);
        
        res.setHeader('Content-Type', 'text/calendar; charset=utf-8');
        res.setHeader('Content-Disposition', `attachment; filename="seemelive-${user}.ics"`);
        res.status(200).send(icsContent);
    } catch (error) {
        res.status(500).json({ error: 'Failed to generate calendar feed' });
    }
};
