//
//  CalendarService.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import EventKit
import UIKit

// MARK: - Calendar Service
/// Manages EventKit calendar events: create, update, and delete.
/// Stores the EKEvent identifier back in the Core Data `Show` so it can
/// be updated or removed later.

@MainActor
final class CalendarService {
    static let shared = CalendarService()

    private let store = EKEventStore()

    private init() {}

    // MARK: - Authorization

    /// Current authorization status for full-access calendar.
    nonisolated var isAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    /// Requests full-access calendar permission. Returns true if granted.
    func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            print("⚠️ Calendar access request failed: \(error)")
            return false
        }
    }

    // MARK: - Create / Update

    /// Creates or updates a calendar event for the given show.
    /// - Returns: The EKEvent identifier, or nil on failure.
    @discardableResult
    func createOrUpdateEvent(for show: Show) -> String? {
        guard isAuthorized else { return nil }

        let event: EKEvent
        if let existingID = show.calendarEventID,
           let existing = store.event(withIdentifier: existingID) {
            event = existing
        } else {
            event = EKEvent(eventStore: store)
            event.calendar = store.defaultCalendarForNewEvents
        }

        // Populate event fields.
        var title = show.title ?? "Show"
        if let role = show.role, !role.isEmpty {
            title += " (\(role))"
        }
        event.title = title
        event.location = show.venue
        event.startDate = show.date ?? Date()
        event.endDate = Calendar.current.date(byAdding: .hour, value: 2, to: event.startDate) ?? event.startDate

        if let link = show.ticketLink, let url = URL(string: link) {
            event.url = url
        }

        // Build notes string.
        var noteParts: [String] = []
        if show.price > 0 {
            noteParts.append(String(format: "Price: $%.2f", show.price))
        }
        if let notes = show.notes, !notes.isEmpty {
            noteParts.append(notes)
        }
        event.notes = noteParts.isEmpty ? nil : noteParts.joined(separator: "\n")

        // Reminder alarm (1 hour before).
        event.alarms?.forEach { event.removeAlarm($0) }
        if show.setReminder {
            event.addAlarm(EKAlarm(relativeOffset: -3600))
        }

        do {
            try store.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            print("⚠️ Failed to save calendar event: \(error)")
            return nil
        }
    }

    // MARK: - Delete

    /// Deletes the calendar event associated with the given show.
    func deleteEvent(for show: Show) {
        guard isAuthorized,
              let eventID = show.calendarEventID,
              let event = store.event(withIdentifier: eventID) else { return }
        do {
            try store.remove(event, span: .thisEvent)
        } catch {
            print("⚠️ Failed to delete calendar event: \(error)")
        }
    }
}
