//
//  HomeScreenView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI
import CoreData

// MARK: - Home Screen View
/// Beautiful vintage Rolodex-style home screen with rustic aesthetics.

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

    private let userID = UserIdentityService.shared.userID

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Vintage Header
                        headerSection
                            .padding(.top, 8)

                        // MARK: - Quick Actions
                        quickActionsSection

                        // MARK: - Shows or Empty State
                        if upcomingShows.isEmpty {
                            emptyStateSection
                        } else {
                            showsSection
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                }

                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        fabButton
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isPresentingEditor) {
                ShowEditorView(showToEdit: showToEdit)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareLinkSheetView(userID: userID)
                    .environment(\.managedObjectContext, viewContext)
            }
            .task {
                await PublicCloudSyncService.shared.flushQueue(using: viewContext)
            }
            .refreshable {
                await PublicCloudSyncService.shared.flushQueue(using: viewContext)
            }
        }
    }

    // MARK: - Vintage Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("SEE ME LIVE")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(Color.accentColor)
                    
                    Text("Performance Calendar")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                }
                
                Spacer()
                
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                        )
                }
            }
            
            Divider()
                .background(Color.accentColor.opacity(0.3))
            
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                Text(formattedDateRange)
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.accentColor.opacity(0.1), radius: 8, y: 4)
        )
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showToEdit = nil
            isPresentingEditor = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add New Show")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                    Text("Quick entry")
                        .font(.system(size: 12, design: .serif))
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor,
                                Color.accentColor.opacity(0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 10, y: 5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Shows Section

    private var showsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming Shows")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(Color.accentColor)
                
                Spacer()
                
                Text("\(upcomingShows.count)")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.accentColor)
                    )
            }
            
            ForEach(upcomingShows) { show in
                NavigationLink {
                    ShowDetailView(show: show) {
                        showToEdit = show
                        isPresentingEditor = true
                    }
                } label: {
                    RolodexCardView(show: show)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 60)

            Image(systemName: "book.closed.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor.opacity(0.4))

            VStack(spacing: 8) {
                Text("No Shows Yet")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.accentColor)

                Text("Tap the + button below to add your first performance")
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer(minLength: 60)
        }
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showToEdit = nil
            isPresentingEditor = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 12, y: 6)
                )
        }
    }

    // MARK: - Helpers

    private var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }
}

// MARK: - Rolodex Card View

private struct RolodexCardView: View {
    @ObservedObject var show: Show
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top tab (like a Rolodex card divider)
            HStack {
                Text(show.titleOrEmpty)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(Color.accentColor)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor.opacity(0.5))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentColor.opacity(0.08))
            )
            
            // Card content
            VStack(alignment: .leading, spacing: 12) {
                // Date & Time
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 20)
                    Text(show.dateFormatted)
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(.primary)
                }
                
                // Venue
                if !show.venueOrEmpty.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 20)
                        Text(show.venueOrEmpty)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }
                
                // Price & Ticket
                HStack(spacing: 16) {
                    if show.price > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.accentColor)
                            Text(show.priceFormatted)
                                .font(.system(size: 13, weight: .medium, design: .serif))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if show.hasTicketLink {
                        HStack(spacing: 6) {
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.accentColor)
                            Text("Tickets")
                                .font(.system(size: 13, weight: .medium, design: .serif))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Relative date badge
                if !show.relativeDateLabel.isEmpty {
                    Text(show.relativeDateLabel)
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                        )
                }
            }
            .padding(18)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.accentColor.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
        )
    }
}

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    HomeScreenView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
