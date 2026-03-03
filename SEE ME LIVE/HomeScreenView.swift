//
//  HomeScreenView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI
import CoreData

// MARK: - Home Screen View
/// Beautiful main home screen with stats, upcoming shows, and quick actions.

struct HomeScreenView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Show.date, ascending: true)],
        predicate: NSPredicate(format: "date >= %@", Date() as NSDate),
        animation: .default
    ) private var upcomingShows: FetchedResults<Show>

    @State private var isPresentingEditor = false
    @State private var showToEdit: Show?
    @State private var showShareSheet = false
    @State private var toastMessage: String?
    @State private var showToast = false

    private let userID = UserIdentityService.shared.userID

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Header with greeting
                        headerSection

                        // MARK: - Quick Actions
                        quickActionsSection

                        // MARK: - Stats
                        if !upcomingShows.isEmpty {
                            statsSection
                        }

                        // MARK: - Upcoming Shows
                        if upcomingShows.isEmpty {
                            emptyStateSection
                        } else {
                            upcomingShowsSection
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }

                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        fabButton
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 20)
                }

                // Toast
                if showToast, let message = toastMessage {
                    VStack {
                        Spacer()
                        toastView(message: message)
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                    }
                    .accessibilityLabel("Share My Gigs")
                }
            }
            .sheet(isPresented: $isPresentingEditor) {
                ShowEditorView(showToEdit: showToEdit)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareLinkSheetView(userID: userID)
            }
            .task {
                await PublicCloudSyncService.shared.flushQueue(using: viewContext)
            }
            .refreshable {
                await PublicCloudSyncService.shared.flushQueue(using: viewContext)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SEE ME LIVE")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(greetingMessage)
                .font(.system(size: 32, weight: .bold, design: .default))
                .foregroundStyle(.primary)

            Text(formattedDateRange)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.accentColor.opacity(0.1),
                            Color.accentColor.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            // Add Show Button
            Button {
                showToEdit = nil
                isPresentingEditor = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Add Show")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.accentColor)
                )
                .foregroundStyle(.white)
            }

            // Share Button
            Button {
                showShareSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.title3)
                    Text("Share")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color("CardBackground")))
                )
                .foregroundStyle(Color.accentColor)
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 12) {
            // Next Show
            StatCardView(
                icon: "calendar.circle.fill",
                title: "Next Show",
                value: upcomingShows.first.map { $0.relativeDateLabel }.joined(),
                color: Color.accentColor
            )

            // Total Shows
            StatCardView(
                icon: "music.mic.circle.fill",
                title: "Total Shows",
                value: "\(upcomingShows.count)",
                color: .blue
            )
        }
    }

    // MARK: - Upcoming Shows Section

    private var upcomingShowsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Shows")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(Array(upcomingShows.prefix(3))) { show in
                NavigationLink {
                    ShowDetailView(show: show) {
                        showToEdit = show
                        isPresentingEditor = true
                    }
                } label: {
                    ShowCardView(show: show)
                }
                .buttonStyle(CardButtonStyle())
            }

            if upcomingShows.count > 3 {
                NavigationLink {
                    AllShowsListView(shows: Array(upcomingShows))
                } label: {
                    HStack {
                        Text("View All \(upcomingShows.count) Shows")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("CardBackground"))
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "music.mic.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 8) {
                Text("No Shows Yet")
                    .font(.title3.bold())

                Text("Tap the + button to add your first performance and get started!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 40)
        }
        .frame(minHeight: 300)
    }

    // MARK: - FAB Button

    private var fabButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showToEdit = nil
            isPresentingEditor = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 10, y: 5)
                )
        }
    }

    // MARK: - Toast

    private func toastView(message: String) -> some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.green))
    }

    // MARK: - Helpers

    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning 🌅"
        case 12..<17: return "Good Afternoon 🎤"
        case 17..<21: return "Good Evening 🌆"
        default: return "Late Night Vibes 🌙"
        }
    }

    private var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let today = Date()
        guard let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today) else {
            return formatter.string(from: today)
        }
        return "\(formatter.string(from: today)) — \(formatter.string(from: nextWeek))"
    }
}

// MARK: - Stat Card View

private struct StatCardView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CardBackground"))
        )
    }
}

// MARK: - Show Card View (Reused)

private struct ShowCardView: View {
    @ObservedObject var show: Show

    var body: some View {
        HStack(spacing: 14) {
            FlyerThumbnailView(data: show.flyerImageData)

            VStack(alignment: .leading, spacing: 4) {
                Text(show.titleOrEmpty)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if !show.venueOrEmpty.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                            .foregroundStyle(Color.accentColor)
                        Text(show.venueOrEmpty)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Text(show.dateFormatted)
                    .font(.caption)
                    .foregroundStyle(Color.accentColor.opacity(0.85))
                    .fontWeight(.medium)

                if !show.relativeDateLabel.isEmpty {
                    Text(show.relativeDateLabel)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor.opacity(0.8)))
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 6) {
                if show.hasTicketLink {
                    Image(systemName: "ticket.fill")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
    }
}

private struct FlyerThumbnailView: View {
    let data: Data?

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.accentColor.opacity(0.1)
                    Image(systemName: "music.note")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor.opacity(0.5))
                }
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - All Shows List View (for "View All" button)

private struct AllShowsListView: View {
    @Environment(\.dismiss) private var dismiss
    let shows: [Show]
    @State private var showToEdit: Show?
    @State private var isPresentingEditor = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(shows) { show in
                        NavigationLink {
                            ShowDetailView(show: show) {
                                showToEdit = show
                                isPresentingEditor = true
                            }
                        } label: {
                            ShowCardView(show: show)
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color("AppBackground"))
            .navigationTitle("All Shows")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HomeScreenView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
