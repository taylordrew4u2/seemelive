//
//  HTMLExportService.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import Foundation
import UIKit

// MARK: - HTML Export Service
/// Generates a beautiful, static HTML page with all upcoming shows.

enum HTMLExportService {
    
    /// Generates a beautiful HTML page with all shows
    static func generateHTML(shows: [Show], performerName: String = "My") -> String {
        let showsHTML = shows.map { show in
            generateShowCard(show: show)
        }.joined(separator: "\n")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let generatedDate = dateFormatter.string(from: Date())
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>SEE ME LIVE - Performance Calendar</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    background: linear-gradient(135deg, #F4EAE2 0%, #E8DDD4 100%);
                    color: #3B2F2F;
                    line-height: 1.6;
                    padding: 20px;
                    min-height: 100vh;
                }
                
                .container {
                    max-width: 800px;
                    margin: 0 auto;
                }
                
                /* Header */
                header {
                    text-align: center;
                    padding: 40px 20px;
                    background: #FCF2F0;
                    border-radius: 16px;
                    box-shadow: 0 4px 20px rgba(154, 101, 68, 0.15);
                    margin-bottom: 40px;
                    border: 2px solid rgba(154, 101, 68, 0.2);
                }
                
                header h1 {
                    font-size: 2.5rem;
                    font-weight: 800;
                    color: #9A6544;
                    margin-bottom: 10px;
                    font-family: Georgia, serif;
                    letter-spacing: -0.5px;
                }
                
                header p {
                    font-size: 1.1rem;
                    color: #7A6B5D;
                    font-weight: 500;
                }
                
                .subtitle {
                    font-size: 0.9rem;
                    color: #9A8A7A;
                    margin-top: 15px;
                    font-style: italic;
                }
                
                /* Show Cards */
                .show-card {
                    background: #FCF2F0;
                    border-radius: 12px;
                    padding: 0;
                    margin-bottom: 24px;
                    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
                    border: 2px solid rgba(154, 101, 68, 0.15);
                    overflow: hidden;
                    transition: transform 0.2s ease, box-shadow 0.2s ease;
                }
                
                .show-card:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 4px 20px rgba(154, 101, 68, 0.2);
                }
                
                .card-header {
                    background: rgba(154, 101, 68, 0.08);
                    padding: 16px 20px;
                    border-bottom: 1px solid rgba(154, 101, 68, 0.15);
                }
                
                .card-title {
                    font-size: 1.5rem;
                    font-weight: 700;
                    color: #9A6544;
                    font-family: Georgia, serif;
                    margin-bottom: 0;
                }
                
                .card-body {
                    padding: 20px;
                }
                
                .info-row {
                    display: flex;
                    align-items: flex-start;
                    margin-bottom: 14px;
                    gap: 12px;
                }
                
                .info-row:last-child {
                    margin-bottom: 0;
                }
                
                .info-icon {
                    font-size: 1.1rem;
                    color: #9A6544;
                    min-width: 24px;
                    text-align: center;
                }
                
                .info-content {
                    flex: 1;
                    font-size: 1rem;
                    color: #3B2F2F;
                }
                
                .info-label {
                    font-weight: 600;
                    color: #7A6B5D;
                    font-size: 0.85rem;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                    margin-bottom: 4px;
                }
                
                .badge {
                    display: inline-block;
                    background: #9A6544;
                    color: white;
                    padding: 6px 14px;
                    border-radius: 20px;
                    font-size: 0.75rem;
                    font-weight: 700;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                    margin-top: 10px;
                }
                
                .ticket-button {
                    display: inline-block;
                    background: #9A6544;
                    color: white;
                    padding: 12px 24px;
                    border-radius: 8px;
                    text-decoration: none;
                    font-weight: 600;
                    font-size: 0.95rem;
                    margin-top: 16px;
                    transition: background 0.2s ease;
                    box-shadow: 0 2px 8px rgba(154, 101, 68, 0.3);
                }
                
                .ticket-button:hover {
                    background: #8A5534;
                    box-shadow: 0 4px 12px rgba(154, 101, 68, 0.4);
                }
                
                .notes {
                    background: rgba(154, 101, 68, 0.05);
                    padding: 14px;
                    border-radius: 8px;
                    border-left: 3px solid #9A6544;
                    margin-top: 14px;
                    font-size: 0.95rem;
                    color: #5A4A3A;
                    font-style: italic;
                }
                
                /* Empty State */
                .empty-state {
                    text-align: center;
                    padding: 80px 20px;
                    background: #FCF2F0;
                    border-radius: 12px;
                    border: 2px dashed rgba(154, 101, 68, 0.3);
                }
                
                .empty-state-icon {
                    font-size: 4rem;
                    margin-bottom: 20px;
                    opacity: 0.5;
                }
                
                .empty-state h2 {
                    color: #9A6544;
                    font-size: 1.8rem;
                    margin-bottom: 10px;
                    font-family: Georgia, serif;
                }
                
                .empty-state p {
                    color: #7A6B5D;
                    font-size: 1.1rem;
                }
                
                /* Footer */
                footer {
                    text-align: center;
                    padding: 40px 20px 20px;
                    color: #9A8A7A;
                    font-size: 0.9rem;
                }
                
                footer a {
                    color: #9A6544;
                    text-decoration: none;
                    font-weight: 600;
                }
                
                /* Responsive */
                @media (max-width: 600px) {
                    header h1 {
                        font-size: 2rem;
                    }
                    
                    .card-title {
                        font-size: 1.3rem;
                    }
                    
                    body {
                        padding: 12px;
                    }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <header>
                    <h1>🎤 SEE ME LIVE</h1>
                    <p>\(performerName) Performance Calendar</p>
                    <p class="subtitle">Generated \(generatedDate)</p>
                </header>
                
                <main>
                    \(showsHTML.isEmpty ? emptyStateHTML : showsHTML)
                </main>
                
                <footer>
                    <p>Created with <a href="#">SEE ME LIVE</a></p>
                </footer>
            </div>
        </body>
        </html>
        """
    }
    
    private static func generateShowCard(show: Show) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        let formattedDate = dateFormatter.string(from: show.dateOrNow)
        
        let priceHTML = show.price > 0 ? """
        <div class="info-row">
            <span class="info-icon">💵</span>
            <div class="info-content">
                <div class="info-label">Price</div>
                \(show.priceFormatted)
            </div>
        </div>
        """ : ""
        
        let ticketHTML = show.hasTicketLink ? """
        <a href="\(show.ticketLinkOrEmpty)" class="ticket-button" target="_blank" rel="noopener">
            🎟 Get Tickets
        </a>
        """ : ""
        
        let notesHTML = !show.notesOrEmpty.isEmpty ? """
        <div class="notes">
            \(show.notesOrEmpty.replacingOccurrences(of: "\n", with: "<br>"))
        </div>
        """ : ""
        
        let relativeDateBadge = !show.relativeDateLabel.isEmpty ? """
        <span class="badge">\(show.relativeDateLabel)</span>
        """ : ""
        
        return """
        <div class="show-card">
            <div class="card-header">
                <h2 class="card-title">\(show.titleOrEmpty)</h2>
            </div>
            <div class="card-body">
                <div class="info-row">
                    <span class="info-icon">📅</span>
                    <div class="info-content">
                        <div class="info-label">Date & Time</div>
                        \(formattedDate)
                        \(relativeDateBadge)
                    </div>
                </div>
                
                <div class="info-row">
                    <span class="info-icon">📍</span>
                    <div class="info-content">
                        <div class="info-label">Venue</div>
                        \(show.venueOrEmpty)
                    </div>
                </div>
                
                \(priceHTML)
                \(notesHTML)
                \(ticketHTML)
            </div>
        </div>
        """
    }
    
    private static var emptyStateHTML: String {
        """
        <div class="empty-state">
            <div class="empty-state-icon">🎭</div>
            <h2>No Upcoming Shows</h2>
            <p>Check back soon for new performances!</p>
        </div>
        """
    }
    
    /// Saves HTML to a temporary file and returns the URL
    static func saveHTMLToFile(html: String) -> URL? {
        let fileName = "SEE_ME_LIVE_\(Date().timeIntervalSince1970).html"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try html.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving HTML file: \(error)")
            return nil
        }
    }
}
