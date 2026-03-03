//
//  ContentView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI
import CoreData
import UIKit

// MARK: - Content View
/// Main screen: shows a list of upcoming gigs sorted by date,
/// a share button, and a floating "+" action button.

struct ContentView: View {
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
    @State private var isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    @State private var fabScale: CGFloat = 1.0
    @State private var toastMessage: String?
    @State private var showToast = false

    private let userID = UserIdentityService.shared.userID

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color("AppBackground")
                    .ignoresSafeArea()

                if upcomingShows.isEmpty {
                    emptyStateView
                } else {
                    showListView
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

                // Toast overlay
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
            .navigationTitle("My Gigs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Share My Gigs")
                }
            }
            .sheet(isPresented: $isPresentingEditor, onDismiss: {
                if showToEdit != nil || !upcomingShows.isEmpty {
                    showToastBriefly("Gig saved! 🎉")
                }
            }) {
                ShowEditorView(showToEdit: showToEdit)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareLinkSheetView(userID: userID)
            }
            .task {
                await PublicCloudSyncService.shared.flushQueue(using: viewContext)
                if isFirstLaunch {
                    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            // Stage illustration using SF Symbols
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 140, height: 140)
                Image(systemName: "music.mic.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.pulse, options: .repeating)
            }

            Text("No gigs yet")
                .font(.title.bold())

            Text("Tap the + button to add your first show.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Show List

    private var showListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(upcomingShows) { show in
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
            .padding(.bottom, 100) // space for FAB
        }
        .refreshable {
            await PublicCloudSyncService.shared.flushQueue(using: viewContext)
        }
    }

    // MARK: - Floating Action Button

    private var fabButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
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
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 8, y: 4)
                )
        }
        .scaleEffect(fabScale)
        .onAppear {
            if isFirstLaunch {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    fabScale = 1.12
                }
            }
        }
        .accessibilityLabel("Add Show")
    }

    // MARK: - Toast

    private func toastView(message: String) -> some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.green)
                    .shadow(radius: 4)
            )
    }

    private func showToastBriefly(_ message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.4)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showToast = false
            }
        }
    }

    // MARK: - Delete

    private func deleteShows(offsets: IndexSet) {
        withAnimation {
            offsets.map { upcomingShows[$0] }.forEach { show in
                PublicCloudSyncService.shared.markForDelete(show: show)
                CalendarService.shared.deleteEvent(for: show)
                viewContext.delete(show)
            }
            PersistenceController.shared.save(context: viewContext)
            Task {
                await PublicCloudSyncService.shared.flushQueue(using: viewContext)
            }
        }
    }
}

// MARK: - Show Card View

private struct ShowCardView: View {
    @ObservedObject var show: Show

    var body: some View {
        HStack(spacing: 14) {
            // Flyer Thumbnail
            FlyerThumbnailView(data: show.flyerImageData)

            // Info
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
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.8))
                        )
                }
            }

            Spacer(minLength: 0)

            // Right indicators
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

// MARK: - Card Button Style (subtle scale on press)

private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Flyer Thumbnail

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

// MARK: - Share Sheet (System)

struct SystemShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - URL Identifiable Conformance

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}
