//
//  ShareLinkSheetView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI
import CoreData

// MARK: - Share Link Sheet View
/// Simple share sheet that shares a text list of your upcoming shows.

struct ShareLinkSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    let userID: String

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Show.date, ascending: true)],
        predicate: NSPredicate(format: "date >= %@", Date() as NSDate),
        animation: .default
    ) private var upcomingShows: FetchedResults<Show>

    @State private var copied = false

    private var shareText: String {
        var text = "🎤 SEE ME LIVE - Upcoming Shows\n\n"
        
        if upcomingShows.isEmpty {
            text += "No upcoming shows yet!"
        } else {
            for (index, show) in upcomingShows.enumerated() {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                
                text += "\(index + 1). \(show.titleOrEmpty)\n"
                text += "   📍 \(show.venueOrEmpty)\n"
                text += "   📅 \(formatter.string(from: show.dateOrNow))\n"
                
                if show.price > 0 {
                    text += "   💵 $\(String(format: "%.2f", show.price))\n"
                }
                
                if show.hasTicketLink {
                    text += "   🎟 \(show.ticketLinkOrEmpty)\n"
                }
                
                text += "\n"
            }
        }
        
        return text
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.accentColor)
                }

                // Title & Description
                VStack(spacing: 10) {
                    Text("Share Your Shows")
                        .font(.title.bold())

                    Text("Share a text list of all your upcoming performances")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Preview
                ScrollView {
                    Text(shareText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color("CardBackground"))
                                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                        )
                }
                .frame(maxHeight: 200)
                .padding(.horizontal, 24)

                // Action Buttons
                VStack(spacing: 14) {
                    // Copy Button
                    Button {
                        UIPasteboard.general.string = shareText
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        withAnimation(.spring(response: 0.3)) {
                            copied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { copied = false }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.body.bold())
                            Text(copied ? "Copied!" : "Copy List")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(copied ? Color.green : Color.accentColor, lineWidth: 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(copied ? Color.green.opacity(0.1) : Color.clear)
                                )
                        )
                        .foregroundStyle(copied ? .green : Color.accentColor)
                    }

                    // Share Button
                    ShareLink(item: shareText) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.body.bold())
                            Text("Share")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.accentColor)
                        )
                        .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(Color("AppBackground"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ShareLinkSheetView(userID: "preview-user")
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
