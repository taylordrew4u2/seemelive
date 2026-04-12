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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Show.date, ascending: false)],
        predicate: NSPredicate(format: "date < %@", Date() as NSDate),
        animation: .default
    ) private var pastShows: FetchedResults<Show>

    @State private var isPresentingEditor = false
    @State private var showToEdit: Show?
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var isPresentingDateSizeSheet = false
    @State private var isPresentingShareSheet = false
    @State private var headerAppeared = false
    @State private var calendarMonth: Date = Date()
    @State private var selectedCalendarDate: Date?
    @State private var isRefreshing = false
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var emptyStateAnimated = false
    @AppStorage("showDateTextSize") private var showDateTextSize: Double = 12

    // Adaptive animation states (splash-screen style)
    @State private var contentAppeared = false
    @State private var pulseGlow = false
    
    private var brand: Color { Color(red: 0.92, green: 0.14, blue: 0.16) }
    private let userID = UserIdentityService.shared.userID

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Filtered Shows (Search)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var filteredUpcomingShows: [Show] {
        guard !searchText.isEmpty else { return Array(upcomingShows) }
        return upcomingShows.filter { matchesSearch($0) }
    }

    private var filteredPastShows: [Show] {
        guard !searchText.isEmpty else { return Array(pastShows) }
        return pastShows.filter { matchesSearch($0) }
    }

    private func matchesSearch(_ show: Show) -> Bool {
        let query = searchText.lowercased()
        return show.titleOrEmpty.lowercased().contains(query) ||
               show.venueOrEmpty.lowercased().contains(query) ||
               show.roleOrEmpty.lowercased().contains(query) ||
               show.notesOrEmpty.lowercased().contains(query)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Skeleton Loading View
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var skeletonLoadingView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Skeleton Hero Header
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonView(width: 120, height: 14)
                    SkeletonView(width: 200, height: 34)
                    SkeletonView(width: 100, height: 15)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)

                // Skeleton Spotlight Card
                VStack(spacing: 0) {
                    SkeletonView(height: 4)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            SkeletonView(width: 80, height: 20)
                            Spacer()
                            SkeletonView(width: 60, height: 24)
                        }
                        HStack(alignment: .top, spacing: 16) {
                            SkeletonView(width: 52, height: 50)
                            VStack(alignment: .leading, spacing: 6) {
                                SkeletonView(width: 180, height: 20)
                                SkeletonView(width: 120, height: 13)
                                SkeletonView(width: 80, height: 13)
                            }
                            Spacer()
                        }
                    }
                    .padding(20)
                }
                .background(Color("CardBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.bottom, 28)

                // Skeleton Quick Actions
                HStack(spacing: 12) {
                    SkeletonView(height: 90)
                    SkeletonView(height: 90)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)

                // Skeleton Calendar
                VStack(alignment: .leading, spacing: 14) {
                    SkeletonView(width: 80, height: 12)
                        .padding(.leading, 4)
                    SkeletonView(height: 280)
                }
                .padding(.horizontal, 20)
            }
        }
        .scrollIndicators(.hidden)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Search Empty State
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var searchEmptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)

            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 90, height: 90)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Text("No Results")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)

                Text("No shows match \"\(searchText)\"")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 40)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Adaptive gradient background (splash-screen style)
                adaptiveBackground
                
                if isLoading {
                    skeletonLoadingView
                } else {
                    ScrollView {
                        VStack(spacing: 0) {

                            // ── Search Bar ──
                            if !allShows.isEmpty {
                                searchBar
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                                    .padding(.bottom, 12)
                                    .opacity(contentAppeared ? 1 : 0)
                                    .offset(y: contentAppeared ? 0 : -10)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: contentAppeared)
                            }

                            // ── Hero Header ──
                            heroHeader
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .padding(.bottom, 32)

                            // ── Next Show Spotlight ──
                            if let next = filteredUpcomingShows.first {
                                spotlightCard(show: next)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 28)
                                    .opacity(contentAppeared ? 1 : 0)
                                    .offset(y: contentAppeared ? 0 : 20)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: contentAppeared)
                            }

                            // ── Quick Actions ──
                            quickActions
                                .padding(.horizontal, 20)
                                .padding(.bottom, 32)
                                .opacity(contentAppeared ? 1 : 0)
                                .offset(y: contentAppeared ? 0 : 20)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: contentAppeared)

                            // ── Calendar ──
                            calendarSection
                                .padding(.horizontal, 20)
                                .padding(.bottom, 32)
                                .opacity(contentAppeared ? 1 : 0)
                                .offset(y: contentAppeared ? 0 : 20)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: contentAppeared)

                            // ── Upcoming Shows ──
                            if filteredUpcomingShows.count > 0 {
                                upcomingSection
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 32)
                                    .opacity(contentAppeared ? 1 : 0)
                                    .offset(y: contentAppeared ? 0 : 20)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: contentAppeared)
                            }

                            // ── Past Shows ──
                            if !filteredPastShows.isEmpty {
                                pastShowsSection
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 32)
                                    .opacity(contentAppeared ? 1 : 0)
                                    .offset(y: contentAppeared ? 0 : 20)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.35), value: contentAppeared)
                            }

                            // ── Empty State ──
                            if allShows.isEmpty {
                                emptyState
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 32)
                            }

                            // ── Search Empty State ──
                            if !searchText.isEmpty && filteredUpcomingShows.isEmpty && filteredPastShows.isEmpty {
                                searchEmptyState
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 32)
                            }

                            Spacer(minLength: 100)
                        }
                    }
                    .scrollIndicators(.hidden)
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
                if showToEdit != nil {
                    showToastBriefly("Show updated ✓")
                } else if !allShows.isEmpty {
                    showToastBriefly("Show saved 🎉")
                }
                showToEdit = nil
            }) {
                ShowEditorView(showToEdit: showToEdit)
                    .environment(\.managedObjectContext, viewContext)
            }
            .fullScreenCover(isPresented: $isPresentingShareSheet) {
                ShareImageEditorView(
                    shows: Array(allShows),
                    performerName: CalendarDisplayOptions.load().performerName
                )
            }
            .task {
                await performBackgroundSync()
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoading = false
                }
            }
            .refreshable {
                await withCheckedContinuation { continuation in
                    isRefreshing = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    
                    Task {
                        await performBackgroundSync()
                        
                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s minimum feedback
                        
                        await MainActor.run {
                            isRefreshing = false
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            continuation.resume()
                        }
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                    headerAppeared = true
                }
                // Trigger cascading content animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        contentAppeared = true
                        pulseGlow = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            isPresentingDateSizeSheet = true
                        } label: {
                            Label("Date Text Size", systemImage: "textformat.size")
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $isPresentingDateSizeSheet) {
                DateTextSizeSheet(showDateTextSize: $showDateTextSize)
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Adaptive Background
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var adaptiveBackground: some View {
        ZStack {
            // Base background
            Color("AppBackground").ignoresSafeArea()
            
            // Subtle gradient overlay (splash-screen style)
            LinearGradient(
                colors: [
                    brand.opacity(colorScheme == .dark ? 0.08 : 0.04),
                    Color("AppBackground").opacity(0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated glow orbs — drawingGroup + accessibilityHidden to prevent
            // excessive accessibility/layout notifications (rate-limit spam).
            Group {
                Circle()
                    .fill(brand.opacity(colorScheme == .dark ? 0.06 : 0.03))
                    .blur(radius: 80)
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -200)
                    .scaleEffect(pulseGlow ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: pulseGlow)
                
                Circle()
                    .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.05 : 0.025))
                    .blur(radius: 100)
                    .frame(width: 400, height: 400)
                    .offset(x: 120, y: 150)
                    .scaleEffect(pulseGlow ? 0.95 : 1.05)
                    .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true).delay(0.5), value: pulseGlow)
            }
            .drawingGroup()
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Search Bar
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search shows...", text: $searchText)
                .font(.system(size: 16))
                .foregroundStyle(.primary)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.04),
                radius: 8, x: 0, y: 2)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Hero Header
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formattedDate)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : 8)
                .animation(.easeOut(duration: 0.5).delay(0.05), value: headerAppeared)

            Text(greetingMessage)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.primary)
                .tracking(-0.4)
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: headerAppeared)

            if !upcomingShows.isEmpty {
                Text("\(upcomingShows.count) upcoming \(upcomingShows.count == 1 ? "show" : "shows")")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 2)
                    .opacity(headerAppeared ? 1 : 0)
                    .offset(y: headerAppeared ? 0 : 8)
                    .animation(.easeOut(duration: 0.5).delay(0.15), value: headerAppeared)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                icon: "doc.richtext",
                label: "Create Flyer",
                tint: .purple
            ) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                isPresentingShareSheet = true
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Calendar Section
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CALENDAR")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // Month navigation
                HStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            calendarMonth = Calendar.current.date(byAdding: .month, value: -1, to: calendarMonth) ?? calendarMonth
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, height: 36)
                    }

                    Spacer()

                    Text(monthYearString(from: calendarMonth))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            calendarMonth = Calendar.current.date(byAdding: .month, value: 1, to: calendarMonth) ?? calendarMonth
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Weekday headers
                let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
                HStack(spacing: 0) {
                    ForEach(Array(weekdays.enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)

                // Day grid
                let days = calendarDays(for: calendarMonth)
                let showDates = showDateSet()

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                    ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                        CalendarDayCell(
                            day: day,
                            hasShow: day != nil && showDates.contains(calendarDayKey(day!)),
                            isSelected: day != nil && selectedCalendarDate.map { Calendar.current.isDate($0, inSameDayAs: day!) } ?? false,
                            onSelect: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    if let d = day {
                                        if selectedCalendarDate.map({ Calendar.current.isDate($0, inSameDayAs: d) }) ?? false {
                                            selectedCalendarDate = nil
                                        } else {
                                            selectedCalendarDate = d
                                        }
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)

                // Shows on selected date
                if let selected = selectedCalendarDate {
                    let dayShows = showsOn(date: selected)
                    if !dayShows.isEmpty {
                        Divider()
                            .padding(.horizontal, 12)

                        VStack(spacing: 0) {
                            ForEach(Array(dayShows.enumerated()), id: \.element.objectID) { idx, show in
                                NavigationLink {
                                    ShowDetailView(show: show) {
                                        showToEdit = show
                                        isPresentingEditor = true
                                    }
                                } label: {
                                    ShowRow(show: show)
                                }
                                .buttonStyle(RowPress())

                                if idx < dayShows.count - 1 {
                                    Divider()
                                        .padding(.leading, 68)
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Text("No shows on this date")
                                .font(.system(size: 14))
                                .foregroundStyle(.tertiary)

                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                // Pre-set the date to the selected calendar date
                                showToEdit = nil
                                isPresentingEditor = true
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Add Show")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(Color.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 14)
                    }
                }
            }
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06),
                    radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Calendar Helpers

    private func monthYearString(from date: Date) -> String {
        Self.monthYearFormatter.string(from: date)
    }

    private func calendarDays(for month: Date) -> [Date?] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: month),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: month))
        else { return [] }

        let firstWeekday = cal.component(.weekday, from: firstOfMonth) // 1 = Sunday
        let leadingBlanks = firstWeekday - 1

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)

        for day in range {
            if let date = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        // Pad trailing to fill the last row
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func calendarDayKey(_ date: Date) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        return "\(y)-\(m)-\(d)"
    }

    private func showDateSet() -> Set<String> {
        var set = Set<String>()
        for show in allShows {
            if let d = show.date {
                set.insert(calendarDayKey(d))
            }
        }
        return set
    }

    private func showsOn(date: Date) -> [Show] {
        allShows.filter { show in
            guard let d = show.date else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Formatters
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    private static let monthAbbrevFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Upcoming Section
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("UPCOMING")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                    .padding(.leading, 4)
                Spacer()
                Text("\(filteredUpcomingShows.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.accentColor))
            }

            LazyVStack(spacing: 0) {
                ForEach(Array(filteredUpcomingShows.enumerated()), id: \.element.objectID) { idx, show in
                    NavigationLink {
                        ShowDetailView(show: show) {
                            showToEdit = show
                            isPresentingEditor = true
                        }
                    } label: {
                        ShowRow(show: show)
                    }
                    .buttonStyle(RowPress())
                    .contextMenu {
                        Button {
                            showToEdit = show
                            isPresentingEditor = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            deleteShow(show)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    if idx < filteredUpcomingShows.count - 1 {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06),
                    radius: 12, x: 0, y: 4)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Past Shows Section
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var pastShowsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("PAST SHOWS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                    .padding(.leading, 4)
                Spacer()
                Text("\(filteredPastShows.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
            }

            LazyVStack(spacing: 0) {
                ForEach(Array(filteredPastShows.enumerated()), id: \.element.objectID) { idx, show in
                    NavigationLink {
                        ShowDetailView(show: show) {
                            showToEdit = show
                            isPresentingEditor = true
                        }
                    } label: {
                        ShowRow(show: show)
                            .opacity(0.7)
                    }
                    .buttonStyle(RowPress())
                    .contextMenu {
                        Button {
                            showToEdit = show
                            isPresentingEditor = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            deleteShow(show)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    if idx < filteredPastShows.count - 1 {
                        Divider().padding(.leading, 68)
                    }
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
                // Animated pulse rings — drawingGroup to prevent rate-limit spam
                Group {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
                            .frame(width: 110 + CGFloat(i * 30), height: 110 + CGFloat(i * 30))
                            .scaleEffect(emptyStateAnimated ? 1.1 : 0.9)
                            .opacity(emptyStateAnimated ? 0.3 : 0.6)
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3),
                                value: emptyStateAnimated
                            )
                    }
                }
                .drawingGroup()
                .accessibilityHidden(true)
                .allowsHitTesting(false)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 110, height: 110)
                    .scaleEffect(emptyStateAnimated ? 1.0 : 0.95)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: emptyStateAnimated)
                
                Image(systemName: "music.mic")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color.accentColor.opacity(0.7))
                    .scaleEffect(emptyStateAnimated ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2), value: emptyStateAnimated)
            }
            .onAppear {
                emptyStateAnimated = true
            }

            VStack(spacing: 10) {
                Text("No Shows Yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                    .opacity(emptyStateAnimated ? 1 : 0)
                    .offset(y: emptyStateAnimated ? 0 : 10)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: emptyStateAnimated)

                Text("Add your first gig to get started.\nYour lineup will appear here.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .opacity(emptyStateAnimated ? 1 : 0)
                    .offset(y: emptyStateAnimated ? 0 : 10)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: emptyStateAnimated)
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
            .opacity(emptyStateAnimated ? 1 : 0)
            .offset(y: emptyStateAnimated ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: emptyStateAnimated)

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
        .accessibilityLabel("Add new show")
        .accessibilityHint("Opens the show editor to create a new show")
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
        Self.fullDateFormatter.string(from: Date())
    }

    private func monthAbbrev(from date: Date) -> String {
        Self.monthAbbrevFormatter.string(from: date)
    }

    private func dayNumber(from date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }

    private func timeString(from date: Date) -> String {
        Self.timeFormatter.string(from: date)
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

    private func performBackgroundSync() async {
        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        await PublicCloudSyncService.shared.flushQueue(using: bgContext)
    }

    private func deleteShow(_ show: Show) {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        PublicCloudSyncService.shared.markForDelete(show: show)
        CalendarService.shared.deleteEvent(for: show)
        viewContext.delete(show)
        PersistenceController.shared.save(context: viewContext)
        Task {
            let bgContext = PersistenceController.shared.container.newBackgroundContext()
            await PublicCloudSyncService.shared.flushQueue(using: bgContext)
        }
        showToastBriefly("Show deleted")
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Calendar Day Cell
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CalendarDayCell: View {
    let day: Date?
    let hasShow: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        if let day = day {
            let isToday = Calendar.current.isDateInToday(day)

            Button(action: onSelect) {
                VStack(spacing: 3) {
                    Text("\(Calendar.current.component(.day, from: day))")
                        .font(.system(size: 15, weight: isToday ? .bold : .regular))
                        .foregroundStyle(
                            isSelected ? .white :
                            isToday ? Color.accentColor :
                            .primary
                        )

                    Circle()
                        .fill(hasShow ? Color.accentColor : Color.clear)
                        .frame(width: 5, height: 5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
            }
            .buttonStyle(.plain)
        } else {
            Color.clear
                .frame(height: 40)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Show Row
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct ShowRow: View {
    let show: Show
    @AppStorage("showDateTextSize") private var showDateTextSize: Double = 12

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
                        .font(.system(size: showDateTextSize))
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
        ShowRow.monthAbbrevFormatter.string(from: date)
    }
    private func dayNumber(from date: Date) -> String {
        ShowRow.dayFormatter.string(from: date)
    }
    private func timeString(from date: Date) -> String {
        ShowRow.timeFormatter.string(from: date)
    }

    private static let monthAbbrevFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM"; return f
    }()
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f
    }()
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

#Preview {
    HomeScreenView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Skeleton View
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20
    
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: height / 3, style: .continuous)
            .fill(Color.secondary.opacity(0.12))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .overlay(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: height / 3, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * 0.6, 1))
                        .offset(x: isAnimating ? geo.size.width : -geo.size.width * 0.6)
                }
                .clipped()
            )
            .clipShape(RoundedRectangle(cornerRadius: height / 3, style: .continuous))
            .drawingGroup()
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}
