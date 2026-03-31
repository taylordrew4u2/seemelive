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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Show.date, ascending: true)],
        predicate: NSPredicate(format: "date >= %@", Date() as NSDate),
        animation: .default
    ) private var upcomingShows: FetchedResults<Show>

    @State private var isPresentingEditor = false
    @State private var showToEdit: Show?
    @State private var isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    @State private var fabScale: CGFloat = 1.0
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var isPresentingDateSizeSheet = false
    @AppStorage("showDateTextSize") private var showDateTextSize: Double = 12

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
            .sheet(isPresented: $isPresentingEditor, onDismiss: {
                if showToEdit != nil || !upcomingShows.isEmpty {
                    showToastBriefly("Gig saved! 🎉")
                }
                showToEdit = nil
            }) {
                ShowEditorView(showToEdit: showToEdit)
                    .environment(\.managedObjectContext, viewContext)
            }
            .task {
                await PublicCloudSyncService.shared.flushQueue(using: viewContext)
                if isFirstLaunch {
                    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingDateSizeSheet = true
                    } label: {
                        Image(systemName: "textformat.size")
                    }
                    .accessibilityLabel("Adjust date text size")
                }
            }
            .sheet(isPresented: $isPresentingDateSizeSheet) {
                DateTextSizeSheet(showDateTextSize: $showDateTextSize)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "music.mic")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color.accentColor.opacity(0.7))
            }

            Text("No Upcoming Events")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)

            Text("Tap + to add your first show")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Show List

    private var showListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(upcomingShows) { show in
                    NavigationLink {
                        ShowDetailView(show: show) {
                            showToEdit = show
                            isPresentingEditor = true
                        }
                    } label: {
                        ShowCardView(show: show)
                    }
                    .buttonStyle(.plain)
                    
                    if show != upcomingShows.last {
                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
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
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(
                    Circle()
                        .fill(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 16, x: 0, y: 8)
                )
        }
        .scaleEffect(fabScale)
        .accessibilityLabel("Add Show")
    }

    // MARK: - Toast

    private func toastView(message: String) -> some View {
        Text(message)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.black.opacity(0.8))
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 5)
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

struct ShowCardView: View {
    @ObservedObject var show: Show
    @AppStorage("showDateTextSize") private var showDateTextSize: Double = 12

    var body: some View {
        HStack(spacing: 12) {
            // Date badge
            VStack(spacing: 2) {
                Text(show.date?.formatted(.dateTime.month(.abbreviated)) ?? "")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                    .textCase(.uppercase)
                
                Text(show.date?.formatted(.dateTime.day()) ?? "")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(width: 52, height: 52)
            .background(Color.accentColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(show.dateFormatted)
                    .font(.system(size: showDateTextSize))
                    .foregroundStyle(.secondary)
                
                Text(show.titleOrEmpty)
                    .font(.system(size: 17))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if !show.venueOrEmpty.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Text(show.venueOrEmpty)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer(minLength: 0)
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Border Modifier

extension View {
    func borderBottom(_ color: Color, width: CGFloat) -> some View {
        self.overlay(
            VStack {
                Spacer()
                Rectangle()
                    .fill(color)
                    .frame(height: width)
            }
        )
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
