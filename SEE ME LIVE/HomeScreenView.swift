//
//  HomeScreenView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI
import CoreData

// MARK: - Home Screen View

struct HomeScreenView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Show.date, ascending: true)],
        predicate: NSPredicate(format: "date >= %@", Date() as NSDate),
        animation: .default
    ) private var upcomingShows: FetchedResults<Show>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Show.date, ascending: true)],
        animation: .default
    ) private var allShows: FetchedResults<Show>

    @State private var isPresentingEditor = false
    @State private var showToEdit: Show?
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var isPresentingShareSheet = false
    @State private var headerAppeared = false

    private let userID = UserIdentityService.shared.userID

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("AppBackground").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Hero Header ──
                        heroHeader
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 32)

                        // ── Next Show Spotlight ──
                        if let next = upcomingShows.first {
                            spotlightCard(show: next)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 28)
                        }

                        // ── Quick Actions ──
                        quickActions
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)

                        // ── Upcoming Shows ──
                        if upcomingShows.count > 1 {
                            upcomingSection
                                .padding(.horizontal, 20)
                                .padding(.bottom, 32)
                        } else if upcomingShows.isEmpty {
                            emptyState
                                .padding(.horizontal, 20)
                                .padding(.bottom, 32)
                        }

                        Spacer(minLength: 100)
                    }
                }

                // ── Floating Action Button ──
                addButton
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 24)
                    .padding(.bottom, 34)

                // ── Toast ──
                if showToast, let msg = toastMessage {
                    toast(msg)
                        .padding(.bottom, 110)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isPresentingEditor, onDismiss: {
                showToEdit = nil
            }) {
                ShowEditorView(showToEdit: showToEdit)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $isPresentingShareSheet) {
                ShareLinkSheetView(userID: userID, shows: Array(allShows), initialTab: 0)
            }
            .task {
                await PublicCloudSyncService.shared.flushQueue(using: viewContext)
            }
            .refreshable {
                await PublicCloudSyncService.shared.flushQueue(using: viewContext)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                    headerAppeared = true
                }
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Hero Header
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formattedDate)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            Text(greetingMessage)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.primary)
                .tracking(-0.4)

            if !upcomingShows.isEmpty {
                Text("\(upcomingShows.count) upcoming \(upcomingShows.count == 1 ? "show" : "shows")")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(headerAppeared ? 1 : 0)
        .offset(y: headerAppeared ? 0 : 12)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Spotlight Card (Next Show)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func spotlightCard(show: Show) -> some View {
        NavigationLink {
            ShowDetailView(show: show) {
                showToEdit = show
                isPresentingEditor = true
            }
        } label: {
            VStack(spacing: 0) {
                // Top accent stripe
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 4)

                VStack(alignment: .leading, spacing: 16) {
                    // Badge row
                    HStack(spacing: 8) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 6, height: 6)
                            Text("NEXT UP")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(Color.accentColor)
                                .tracking(1.4)
                        }

                        Spacer()

                        if !show.relativeDateLabel.isEmpty {
                            Text(show.relativeDateLabel)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.accentColor.opacity(0.1))
                                )
                        }
                    }

                    // Main content
                    HStack(alignment: .top, spacing: 16) {
                        // Date block
                        VStack(spacing: 2) {
                            Text(monthAbbrev(from: show.dateOrNow))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                                .textCase(.uppercase)
                            Text(dayNumber(from: show.dateOrNow))
                                .font(.system(size: 38, weight: .light, design: .rounded))
                                .foregroundStyle(.primary)
                                .monospacedDigit()
                        }
                        .frame(width: 52)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(show.titleOrEmpty)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            if !show.venueOrEmpty.isEmpty {
                                HStack(spacing: 5) {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 10, weight: .semibold))
                                    Text(show.venueOrEmpty)
                                        .lineLimit(1)
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                            }

                            Text(timeString(from: show.dateOrNow))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.tertiary)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.quaternary)
                            .padding(.top, 6)
                    }
                }
                .padding(20)
            }
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.08),
                    radius: 20, x: 0, y: 8)
        }
        .buttonStyle(CardPress())
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Quick Actions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "plus",
                label: "New Show",
                tint: Color.accentColor
            ) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showToEdit = nil
                isPresentingEditor = true
            }

            QuickActionButton(
                icon: "square.and.arrow.up",
                label: "Share",
                tint: .purple
            ) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                isPresentingShareSheet = true
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Upcoming Section
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("UPCOMING")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                let remaining = Array(upcomingShows.dropFirst().prefix(6))
                ForEach(Array(remaining.enumerated()), id: \.element.objectID) { idx, show in
                    NavigationLink {
                        ShowDetailView(show: show) {
                            showToEdit = show
                            isPresentingEditor = true
                        }
                    } label: {
                        ShowRow(show: show)
                    }
                    .buttonStyle(RowPress())

                    if idx < remaining.count - 1 {
                        Divider()
                            .padding(.leading, 68)
                    }
                }

                if upcomingShows.count > 7 {
                    Divider().padding(.leading, 68)

                    NavigationLink {
                        AllShowsListView(shows: Array(upcomingShows))
                    } label: {
                        HStack {
                            Text("See All \(upcomingShows.count) Shows")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.accentColor.opacity(0.6))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(RowPress())
                }
            }
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06),
                    radius: 12, x: 0, y: 4)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Empty State
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var emptyState: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 60)

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 110, height: 110)
                Image(systemName: "music.mic")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color.accentColor.opacity(0.7))
            }

            VStack(spacing: 10) {
                Text("No Shows Yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Add your first gig to get started.\nYour lineup will appear here.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showToEdit = nil
                isPresentingEditor = true
            } label: {
                Text("Add Your First Show")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.accentColor)
                            .shadow(color: Color.accentColor.opacity(0.35), radius: 10, y: 5)
                    )
            }
            .buttonStyle(CardPress())

            Spacer(minLength: 60)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - FAB
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var addButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showToEdit = nil
            isPresentingEditor = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(
                    Circle()
                        .fill(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 16, x: 0, y: 8)
                )
        }
        .buttonStyle(FABStyle())
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Toast
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func toast(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
            Text(message)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.black.opacity(0.8))
                .shadow(color: .black.opacity(0.2), radius: 12, y: 5)
        )
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Helpers
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default:      return "Good Evening"
        }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    private func monthAbbrev(from date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM"; return f.string(from: date)
    }

    private func dayNumber(from date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: date)
    }

    private func timeString(from date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: date)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Show Row
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct ShowRow: View {
    let show: Show

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 1) {
                Text(monthAbbrev(from: show.dateOrNow))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                    .textCase(.uppercase)
                Text(dayNumber(from: show.dateOrNow))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(width: 44, height: 44)
            .background(Color.accentColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(show.titleOrEmpty)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if !show.venueOrEmpty.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin")
                                .font(.system(size: 9, weight: .semibold))
                            Text(show.venueOrEmpty)
                                .lineLimit(1)
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    }

                    Text(timeString(from: show.dateOrNow))
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func monthAbbrev(from date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM"; return f.string(from: date)
    }
    private func dayNumber(from date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: date)
    }
    private func timeString(from date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: date)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Quick Action Button
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct QuickActionButton: View {
    let icon: String
    let label: String
    let tint: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06),
                    radius: 12, x: 0, y: 4)
        }
        .buttonStyle(CardPress())
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Button Styles
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CardPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private struct RowPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.primary.opacity(0.04) : Color.clear)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

private struct FABStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - All Shows List View
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct AllShowsListView: View {
    let shows: [Show]
    @State private var showToEdit: Show?
    @State private var isPresentingEditor = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(shows.enumerated()), id: \.element.objectID) { idx, show in
                    NavigationLink {
                        ShowDetailView(show: show) {
                            showToEdit = show
                            isPresentingEditor = true
                        }
                    } label: {
                        ShowRow(show: show)
                    }
                    .buttonStyle(RowPress())

                    if idx < shows.count - 1 {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06),
                    radius: 12, x: 0, y: 4)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 44)
        }
        .background(Color("AppBackground").ignoresSafeArea())
        .navigationTitle("All Shows")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HomeScreenView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
