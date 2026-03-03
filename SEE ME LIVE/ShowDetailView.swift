//
//  ShowDetailView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI
import CoreData

// MARK: - Show Detail View
/// Full-screen detail for a single show. Features a large header image,
/// info cards in a grid, a ticket button, notes section, and edit/delete actions.

struct ShowDetailView: View {
    @ObservedObject var show: Show
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let onEdit: () -> Void

    @State private var showDeleteConfirmation = false
    @State private var showFullScreenImage = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: Header Image
                headerImage

                VStack(alignment: .leading, spacing: 20) {
                    // MARK: Title & Role
                    VStack(alignment: .leading, spacing: 6) {
                        Text(show.titleOrEmpty)
                            .font(.largeTitle.bold())
                            .foregroundStyle(.primary)

                        if !show.roleOrEmpty.isEmpty {
                            Text(show.roleOrEmpty)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 20)

                    // MARK: Info Cards Grid
                    infoCardsGrid

                    // MARK: Ticket Button
                    if show.hasTicketLink,
                       let link = show.ticketLink,
                       let url = URL(string: link) {
                        Link(destination: url) {
                            HStack(spacing: 10) {
                                Image(systemName: "ticket.fill")
                                    .font(.body.bold())
                                Text("Get Tickets")
                                    .fontWeight(.bold)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.accentColor)
                                    .shadow(color: Color.accentColor.opacity(0.3),
                                            radius: 8, y: 4)
                            )
                        }
                        .buttonStyle(CardPressStyle())
                    }

                    // MARK: Notes
                    if !show.notesOrEmpty.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Notes", systemImage: "note.text")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            Text(show.notesOrEmpty)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color("CardBackground"))
                        )
                    }

                    // MARK: Action Buttons
                    HStack(spacing: 12) {
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("CardBackground"))
                                )
                        }
                        .buttonStyle(CardPressStyle())

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                )
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(CardPressStyle())
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Color("AppBackground"))
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this show?",
                            isPresented: $showDeleteConfirmation,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteShow() }
        } message: {
            Text("This will remove the show from your calendar and public listing.")
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            fullScreenImageViewer
        }
    }

    // MARK: - Header Image

    @ViewBuilder
    private var headerImage: some View {
        if let data = show.flyerImageData, let uiImage = UIImage(data: data) {
            Button {
                showFullScreenImage = true
            } label: {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .clipped()
                    .overlay(
                        // Gradient overlay at bottom for text readability
                        LinearGradient(
                            colors: [.clear, .clear, Color("AppBackground").opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .buttonStyle(.plain)
        } else {
            // Gradient placeholder
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.6), Color.accentColor.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(spacing: 10) {
                    Image(systemName: "music.mic.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.white.opacity(0.8))
                    Text(show.titleOrEmpty)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 240)
        }
    }

    // MARK: - Info Cards Grid

    private var infoCardsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            // Venue
            if !show.venueOrEmpty.isEmpty {
                InfoCard(
                    icon: "mappin.and.ellipse",
                    label: "Venue",
                    value: show.venueOrEmpty
                )
            }

            // Date & Time
            InfoCard(
                icon: "calendar",
                label: "Date & Time",
                value: show.dateFormatted
            )

            // Price
            InfoCard(
                icon: "tag.fill",
                label: "Price",
                value: show.priceFormatted
            )

            // Role
            if !show.roleOrEmpty.isEmpty {
                InfoCard(
                    icon: "person.fill",
                    label: "Role",
                    value: show.roleOrEmpty
                )
            }
        }
    }

    // MARK: - Full-Screen Image Viewer

    private var fullScreenImageViewer: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let data = show.flyerImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showFullScreenImage = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .white.opacity(0.3))
                    }
                    .padding(20)
                }
                Spacer()
            }
        }
    }

    // MARK: - Delete

    private func deleteShow() {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.warning)
        PublicCloudSyncService.shared.markForDelete(show: show)
        CalendarService.shared.deleteEvent(for: show)
        viewContext.delete(show)
        PersistenceController.shared.save(context: viewContext)
        Task {
            await PublicCloudSyncService.shared.flushQueue(using: viewContext)
        }
        dismiss()
    }
}

// MARK: - Info Card

private struct InfoCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.accentColor)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CardBackground"))
        )
    }
}

// MARK: - Card Press Style

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        ShowDetailView(
            show: {
                let ctx = PersistenceController.preview.container.viewContext
                let s = Show(context: ctx)
                s.title = "Comedy Night"
                s.venue = "The Laugh Factory"
                s.role = "Headliner"
                s.date = Date()
                s.price = 25
                s.ticketLink = "https://example.com"
                s.notes = "Doors open at 7 PM. Bring your friends and get ready for an unforgettable evening of laughs!"
                s.userID = "preview"
                s.createdAt = Date()
                s.updatedAt = Date()
                return s
            }(),
            onEdit: {}
        )
    }
}
