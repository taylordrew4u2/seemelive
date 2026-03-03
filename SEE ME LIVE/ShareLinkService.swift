//
//  ShareLinkService.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import Foundation

// MARK: - Share Link Service
/// Builds public-facing URLs for sharing the calendar.
/// The URL embeds the user's unique ID so the web page can query
/// the right records from the CloudKit public database.

enum ShareLinkService {
    /// Base URL of the GitHub Pages site. Change this to your own domain
    /// after deploying the public web page.
    private static let baseURL = "https://taylordrew4u2.github.io/seemelive"

    /// Returns a shareable web calendar URL containing the user's unique ID.
    /// This URL is stable and can be bookmarked or shared indefinitely.
    static func shareURL(for userID: String) -> URL {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [URLQueryItem(name: "user", value: userID)]
        return components.url!
    }

    /// Returns a shareable iCalendar (.ics) feed URL for the user's shows.
    /// This URL can be added to calendar apps (Apple Calendar, Google Calendar, etc.)
    /// and will always show the user's current shows.
    static func calendarFeedURL(for userID: String) -> URL {
        var components = URLComponents(string: baseURL)!
        components.path = baseURL.contains("/seemelive") ? "/seemelive/calendar.ics" : "/calendar.ics"
        components.queryItems = [URLQueryItem(name: "user", value: userID)]
        return components.url!
    }
}
