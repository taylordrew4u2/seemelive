//
//  Show+Extensions.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import Foundation
import CoreData

// MARK: - Convenience Accessors
/// These computed properties provide safe, non-optional access to Show
/// attributes, making SwiftUI bindings and display code cleaner.

extension Show {
    var titleOrEmpty: String   { title ?? "" }
    var venueOrEmpty: String   { venue ?? "" }
    var roleOrEmpty: String    { role ?? "" }
    var notesOrEmpty: String   { notes ?? "" }
    var ticketLinkOrEmpty: String { ticketLink ?? "" }
    var dateOrNow: Date        { date ?? Date() }
    var userIDOrEmpty: String  { userID ?? "" }

    var priceFormatted: String {
        price > 0 ? String(format: "$%.2f", price) : "Free"
    }

    /// Formatted date string like "Sat, Mar 15 · 8:00 PM"
    var dateFormatted: String {
        let d = dateOrNow
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE, MMM d"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return "\(dayFormatter.string(from: d)) · \(timeFormatter.string(from: d))"
    }

    /// Short relative date label, e.g. "Tomorrow", "In 3 days"
    var relativeDateLabel: String {
        let calendar = Calendar.current
        let now = Date()
        let d = dateOrNow
        if calendar.isDateInToday(d) { return "Today" }
        if calendar.isDateInTomorrow(d) { return "Tomorrow" }
        let days = calendar.dateComponents([.day], from: now, to: d).day ?? 0
        if days > 0 && days <= 7 { return "In \(days) days" }
        return ""
    }

    /// True if the show has a valid ticket link
    var hasTicketLink: Bool {
        guard let link = ticketLink, !link.isEmpty,
              URL(string: link) != nil else { return false }
        return true
    }
}
