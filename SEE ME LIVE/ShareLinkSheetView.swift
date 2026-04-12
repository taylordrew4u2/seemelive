//
//  ShareLinkSheetView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI

// MARK: - Share Image Sheet

struct ShareLinkSheetView: View {
    @Environment(\.dismiss) private var dismiss

    let userID: String
    let shows: [Show]
    let initialTab: Int

    init(userID: String, shows: [Show] = [], initialTab: Int = 0) {
        self.userID     = userID
        self.shows      = shows
        self.initialTab = initialTab
    }

    // MARK: State
    @State private var performerName: String  = CalendarDisplayOptions.load().performerName
    @State private var options: ExportOptions = ExportOptions()
    @State private var cachedImage: UIImage   = UIImage()
    @State private var renderTask: Task<Void, Never>? = nil
    @State private var showEditor = false

    // MARK: Body
    var body: some View {
        mainNavigation
            .fullScreenCover(isPresented: $showEditor) {
                ShareImageEditorView(
                    shows: shows,
                    performerName: normalizedPerformerName(performerName)
                )
            }
            .onChange(of: showEditor) { _, isShowing in
                if !isShowing { regenerateImage() }
            }
            .onAppear { regenerateImage() }
            .applyOptionChangeHandlers(options: $options, regenerate: regenerateImage)
            .onChange(of: performerName)           { regenerateImage() }
    }

    private var mainNavigation: some View {
        NavigationStack {
            scrollContent
                .background(Color("AppBackground"))
                .navigationTitle("Create Flyer")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            var opts = CalendarDisplayOptions.load()
                            opts.performerName = performerName
                            opts.save()
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: shareJPEG) {
                            Image(systemName: "square.and.arrow.up").fontWeight(.semibold)
                        }
                    }
                }
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                shareButtonSection
                previewSection
                editImageButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Extracted Sections

    private var shareButtonSection: some View {
        Button(action: shareJPEG) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .bold))
                Text("Create Flyer")
                    .font(.system(size: 19, weight: .bold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(0.7)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.accentColor)
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 12, y: 5)
            )
        }
    }

    private var previewSection: some View {
        sectionCard(title: "Preview", icon: "photo") {
            Image(uiImage: cachedImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .frame(maxWidth: .infinity)
        }
    }

    private var editImageButton: some View {
        Button {
            showEditor = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 18, weight: .semibold))
                Text("Edit Image")
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Text("Background · Text · Font")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 10, y: 4)
            )
        }
    }

    // MARK: - Helpers

    private func regenerateImage() {
        renderTask?.cancel()
        let name  = normalizedPerformerName(performerName)
        let opts  = options
        // Snapshot Show managed objects on the main thread (safe).
        let now = Date()
        let upcomingShows = shows.filter { ($0.date ?? now) >= now }
        let snapshots = upcomingShows.map { ShowSnapshot(from: $0) }
        renderTask = Task.detached(priority: .userInitiated) {
            guard !Task.isCancelled else { return }
            let img = ShareImageGenerator.generate(snapshots: snapshots, performerName: name, options: opts)
            guard !Task.isCancelled else { return }
            await MainActor.run { cachedImage = img }
        }
    }

    private func normalizedPerformerName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "My" || trimmed == "My Shows" {
            return "Shows"
        }
        return trimmed
    }

    private func shareJPEG() {
        let image = cachedImage
        presentSheet(items: [image])
    }

    private func presentSheet(items: [Any]) {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root  = scene.windows.first?.rootViewController else { return }
        var top = root
        while let p = top.presentedViewController { top = p }
        if let pop = vc.popoverPresentationController {
            pop.sourceView = top.view
            pop.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        top.present(vc, animated: true)
    }

    @ViewBuilder
    private func sectionCard<C: View>(title: String, icon: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Color(hex:) helper

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let value = UInt64(h, radix: 16) else { return nil }
        self.init(red:   Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8)  & 0xFF) / 255,
                  blue:  Double( value        & 0xFF) / 255)
    }
}

// MARK: - onChange helper to reduce body complexity

private struct OptionChangeHandlers: ViewModifier {
    @Binding var options: ExportOptions
    let regenerate: () -> Void

    func body(content: Content) -> some View {
        let base = content
            .onChange(of: options.sizePreset)      { regenerate() }
            .onChange(of: options.showDate)        { regenerate() }
            .onChange(of: options.showVenue)       { regenerate() }

        let group2 = base
            .onChange(of: options.columns)         { regenerate() }
            .onChange(of: options.headerStyle)     { regenerate() }
            .onChange(of: options.fontStyle)       { regenerate() }
            .onChange(of: options.subtitleText)    { regenerate() }

        return group2
            .onChange(of: options.scrimIntensity)  { regenerate() }
            .onChange(of: options.gridGap)         { regenerate() }
            .onChange(of: options.showPadding)     { regenerate() }
            .onChange(of: options.maxRows)         { regenerate() }
    }
}

private extension View {
    func applyOptionChangeHandlers(options: Binding<ExportOptions>,
                                    regenerate: @escaping () -> Void) -> some View {
        modifier(OptionChangeHandlers(options: options, regenerate: regenerate))
    }
}

#Preview {
    ShareLinkSheetView(userID: "preview", shows: [])
}