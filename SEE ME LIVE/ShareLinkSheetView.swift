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
    @State private var accentColor: Color     = Color(red: 204/255, green: 112/255, blue: 87/255)
    @State private var renderTask: Task<Void, Never>? = nil
    @State private var showEditor = false

    private var accentHex: String {
        let ui = UIColor(accentColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }

    // MARK: Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // ── SHARE BUTTON ──────────────────────────────────
                    Button(action: shareJPEG) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20, weight: .bold))
                            Text("Share My Shows")
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

                    // ── ARTIST NAME ───────────────────────────────────
                    sectionCard(title: "Artist Name", icon: "person.fill") {
                        TextField("e.g. Taylor Drew", text: $performerName)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                    }

                    // ── PLATFORM SIZE ─────────────────────────────────
                    sectionCard(title: "Platform Size", icon: "aspectratio.fill") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(SocialSizePreset.allCases) { preset in
                                let selected = options.sizePreset == preset
                                Button { options.sizePreset = preset } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: preset.icon)
                                            .font(.system(size: 18))
                                        Text(preset.rawValue)
                                            .font(.system(size: 11, weight: .semibold))
                                            .multilineTextAlignment(.center)
                                        Text("\(Int(preset.size.width))x\(Int(preset.size.height))")
                                            .font(.system(size: 9))
                                            .foregroundStyle(selected ? .white.opacity(0.8) : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selected ? Color.accentColor : Color.secondary.opacity(0.1))
                                    .foregroundStyle(selected ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .animation(.spring(response: 0.2), value: options.sizePreset)
                            }
                        }
                    }

                    // ── BACKGROUND ────────────────────────────────────
                    sectionCard(title: "Background", icon: "paintpalette.fill") {
                        HStack(spacing: 8) {
                            ForEach(BackgroundStyle.allCases.filter { $0 != .custom }) { style in
                                let selected = options.backgroundStyle == style
                                Button { options.backgroundStyle = style } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: style.icon)
                                            .font(.system(size: 16))
                                        Text(style.rawValue)
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(selected ? Color.accentColor : Color.secondary.opacity(0.1))
                                    .foregroundStyle(selected ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .animation(.spring(response: 0.2), value: options.backgroundStyle)
                            }
                        }
                    }

                    // ── ACCENT COLOR ──────────────────────────────────
                    sectionCard(title: "Accent Color", icon: "circle.fill") {
                        HStack(spacing: 12) {
                            ColorPicker("", selection: $accentColor, supportsOpacity: false)
                                .labelsHidden()
                                .frame(width: 44, height: 44)
                            Text("Color used for name, badge and bar text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }

                    // ── TOGGLES ───────────────────────────────────────
                    sectionCard(title: "Include", icon: "checklist") {
                        VStack(spacing: 0) {
                            Toggle(isOn: $options.showDate) {
                                Label("Date", systemImage: "calendar")
                                    .font(.subheadline)
                            }
                            .tint(Color.accentColor)
                            Divider().padding(.vertical, 6)
                            Toggle(isOn: $options.showVenue) {
                                Label("Venue", systemImage: "mappin.circle")
                                    .font(.subheadline)
                            }
                            .tint(Color.accentColor)
                            Divider().padding(.vertical, 6)
                            Toggle(isOn: $options.showBadge) {
                                Label("App Badge", systemImage: "tag.fill")
                                    .font(.subheadline)
                            }
                            .tint(Color.accentColor)
                            Divider().padding(.vertical, 6)
                            Toggle(isOn: $options.showBottomBar) {
                                Label("Bottom Bar", systemImage: "rectangle.bottomhalf.filled")
                                    .font(.subheadline)
                            }
                            .tint(Color.accentColor)
                        }
                    }

                    // ── PREVIEW ───────────────────────────────────
                    sectionCard(title: "Preview", icon: "photo") {
                        Image(uiImage: cachedImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .frame(maxWidth: .infinity)
                    }

                    // ── EDIT IMAGE ────────────────────────────────
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
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color("AppBackground"))
            .navigationTitle("Share My Shows")
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $showEditor) {
            ShareImageEditorView(
                shows: shows,
                performerName: performerName.isEmpty ? "My Shows" : performerName,
                options: $options
            )
        }
        .onChange(of: showEditor) { _, isShowing in
            if !isShowing { regenerateImage() }
        }
        .onAppear { regenerateImage() }
        .onChange(of: performerName)           { regenerateImage() }
        .onChange(of: options.sizePreset)      { regenerateImage() }
        .onChange(of: options.backgroundStyle) { regenerateImage() }
        .onChange(of: options.showDate)        { regenerateImage() }
        .onChange(of: options.showVenue)       { regenerateImage() }
        .onChange(of: options.showBadge)       { regenerateImage() }
        .onChange(of: options.showBottomBar)   { regenerateImage() }
        .onChange(of: accentColor)             { regenerateImage() }
    }

    // MARK: - Helpers

    private func regenerateImage() {
        renderTask?.cancel()
        let name  = performerName.isEmpty ? "My Shows" : performerName
        var opts  = options
        opts.accentHex = accentHex
        // Snapshot Show managed objects on the main thread (safe).
        let snapshots = shows.map { ShowSnapshot(from: $0) }
        renderTask = Task.detached(priority: .userInitiated) {
            guard !Task.isCancelled else { return }
            let img = ShareImageGenerator.generate(snapshots: snapshots, performerName: name, options: opts)
            guard !Task.isCancelled else { return }
            await MainActor.run { cachedImage = img }
        }
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

#Preview {
    ShareLinkSheetView(userID: "preview", shows: [])
}
