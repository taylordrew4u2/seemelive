//
//  ShareLinkSheetView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI
import PhotosUI

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
    @State private var bgPhotoItem: PhotosPickerItem?
    @State private var bgPhotoThumb: UIImage?

    private var accentHex: String {
        let ui = UIColor(accentColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }

    // Accent color presets
    private static let accentPresets: [String] = [
        "#CC7057", "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#00C7BE", "#007AFF", "#5856D6", "#AF52DE", "#FF2D55",
        "#A2845E", "#FFFFFF", "#8E8E93"
    ]

    // MARK: Body
    var body: some View {
        mainNavigation
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
            .applyOptionChangeHandlers(options: $options, regenerate: regenerateImage)
            .onChange(of: performerName)           { regenerateImage() }
            .onChange(of: accentColor)             { regenerateImage() }
    }

    private var mainNavigation: some View {
        NavigationStack {
            scrollContent
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
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                shareButtonSection
                artistNameSection
                platformSizeSection
                backgroundSection
                accentColorSection
                customTextSection
                headerStyleSection
                fontStyleSection
                dateFormatSection
                fineTuningSection
                cardStyleSection
                gridColumnsSection
                togglesSection
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
    }

    private var artistNameSection: some View {
        sectionCard(title: "Artist Name", icon: "person.fill") {
            TextField("e.g. Taylor Drew", text: $performerName)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
        }
    }

    private var platformSizeSection: some View {
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
    }

    private var backgroundSection: some View {
        sectionCard(title: "Background", icon: "paintpalette.fill") {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(BackgroundStyle.allCases.filter { $0 != .custom }) { style in
                        let selected = options.backgroundStyle == style
                        Button {
                            options.backgroundStyle = style
                        } label: {
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

                backgroundPhotoRow
            }
        }
    }

    private var backgroundPhotoRow: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $bgPhotoItem, matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 14))
                    Text(options.customBackground.photoData != nil ? "Change Image" : "Upload Background")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(options.backgroundStyle == .custom ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    options.backgroundStyle == .custom
                        ? AnyShapeStyle(Color.accentColor)
                        : AnyShapeStyle(Color.secondary.opacity(0.1)),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .onChange(of: bgPhotoItem) { _, newItem in
                Task { await loadBackgroundPhoto(from: newItem) }
            }

            if let thumb = bgPhotoThumb {
                Image(uiImage: thumb)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.accentColor, lineWidth: 1.5)
                    )

                Button {
                    options.customBackground.photoData = nil
                    bgPhotoThumb = nil
                    bgPhotoItem = nil
                    if options.backgroundStyle == .custom {
                        options.backgroundStyle = .gradient
                    }
                    regenerateImage()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    private var accentColorSection: some View {
        sectionCard(title: "Accent Color", icon: "circle.fill") {
            VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Self.accentPresets, id: \.self) { hex in
                            Button {
                                if let c = Color(hex: hex) { accentColor = c }
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex) ?? .gray)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle().stroke(.white.opacity(0.3), lineWidth: 0.5)
                                    )
                                    .overlay(
                                        accentHex.uppercased() == hex.uppercased()
                                            ? Circle().stroke(Color.primary, lineWidth: 2.5)
                                                .frame(width: 38, height: 38) : nil
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(spacing: 12) {
                    ColorPicker("", selection: $accentColor, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 36, height: 36)
                    Text("Custom color")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    private var customTextSection: some View {
        sectionCard(title: "Custom Text", icon: "character.cursor.ibeam") {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    TextField("Badge text", text: $options.badgeText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 14))
                        .submitLabel(.done)
                }

                HStack(spacing: 8) {
                    Image(systemName: "text.below.photo")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    TextField("Subtitle text", text: $options.subtitleText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 14))
                        .submitLabel(.done)
                }
            }
        }
    }

    private var headerStyleSection: some View {
        sectionCard(title: "Header Style", icon: "text.alignleft") {
            HStack(spacing: 8) {
                ForEach(HeaderStyle.allCases) { style in
                    let selected = options.headerStyle == style
                    Button { options.headerStyle = style } label: {
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
                }
            }
        }
    }

    private var fontStyleSection: some View {
        sectionCard(title: "Font", icon: "textformat") {
            HStack(spacing: 8) {
                ForEach(FontStyle.allCases) { style in
                    let selected = options.fontStyle == style
                    Button { options.fontStyle = style } label: {
                        VStack(spacing: 4) {
                            Image(systemName: style.icon)
                                .font(.system(size: 14))
                            Text(style.rawValue)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(selected ? Color.accentColor : Color.secondary.opacity(0.1))
                        .foregroundStyle(selected ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var dateFormatSection: some View {
        sectionCard(title: "Date Format", icon: "calendar.badge.clock") {
            HStack(spacing: 6) {
                ForEach(DateFormatStyle.allCases) { style in
                    let selected = options.dateFormatStyle == style
                    Button { options.dateFormatStyle = style } label: {
                        VStack(spacing: 3) {
                            Image(systemName: style.icon)
                                .font(.system(size: 13))
                            Text(style.rawValue)
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selected ? Color.accentColor : Color.secondary.opacity(0.1))
                        .foregroundStyle(selected ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var fineTuningSection: some View {
        sectionCard(title: "Fine Tuning", icon: "slider.horizontal.3") {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Overlay Darkness")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(options.scrimIntensity * 100))%")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $options.scrimIntensity, in: 0...1.0, step: 0.05)
                        .tint(Color.accentColor)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Card Spacing")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(options.gridGap < 0.3 ? "None" : options.gridGap > 1.5 ? "Wide" : "Normal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $options.gridGap, in: 0...2.0, step: 0.1)
                        .tint(Color.accentColor)
                }
            }
        }
    }

    private var cardStyleSection: some View {
        sectionCard(title: "Card Style", icon: "rectangle.on.rectangle") {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(CardStyle.allCases) { style in
                        let selected = options.cardStyle == style
                        Button { options.cardStyle = style } label: {
                            VStack(spacing: 4) {
                                Image(systemName: style.icon)
                                    .font(.system(size: 16))
                                Text(style.rawValue)
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(selected ? Color.accentColor : Color.secondary.opacity(0.1))
                            .foregroundStyle(selected ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if options.cardStyle == .rounded || options.cardStyle == .sharp {
                    HStack(spacing: 10) {
                        Image(systemName: "circle.dotted")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Slider(value: $options.cardOpacity, in: 0.1...1.0, step: 0.05)
                            .tint(Color.accentColor)
                        Image(systemName: "circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text("\(Int(options.cardOpacity * 100))%")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 36)
                    }
                }
            }
        }
    }

    private var gridColumnsSection: some View {
        sectionCard(title: "Grid Columns", icon: "square.grid.2x2") {
            HStack(spacing: 8) {
                ForEach([0, 1, 2, 3, 4], id: \.self) { col in
                    let selected = options.columns == col
                    Button { options.columns = col } label: {
                        Text(col == 0 ? "Auto" : "\(col)")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selected ? Color.accentColor : Color.secondary.opacity(0.1))
                            .foregroundStyle(selected ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var togglesSection: some View {
        sectionCard(title: "Include", icon: "checklist") {
            VStack(spacing: 0) {
                Toggle(isOn: $options.showDate) {
                    Label("Date & Time", systemImage: "calendar")
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
                Toggle(isOn: $options.showPrice) {
                    Label("Price", systemImage: "dollarsign.circle")
                        .font(.subheadline)
                }
                .tint(Color.accentColor)
                Divider().padding(.vertical, 6)
                Toggle(isOn: $options.showTickets) {
                    Label("Ticket Link", systemImage: "ticket")
                        .font(.subheadline)
                }
                .tint(Color.accentColor)
                Divider().padding(.vertical, 6)
                Toggle(isOn: $options.showNotes) {
                    Label("Notes", systemImage: "note.text")
                        .font(.subheadline)
                }
                .tint(Color.accentColor)
                Divider().padding(.vertical, 6)
                Toggle(isOn: $options.showBadge) {
                    Label("App Badge", systemImage: "tag.fill")
                        .font(.subheadline)
                }
                .tint(Color.accentColor)
            }
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

    private func loadBackgroundPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run {
                options.customBackground.kind = .photo
                options.customBackground.photoData = data
                options.backgroundStyle = .custom
                if let img = UIImage(data: data) {
                    bgPhotoThumb = img
                }
                regenerateImage()
            }
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

// MARK: - onChange helper to reduce body complexity

private struct OptionChangeHandlers: ViewModifier {
    @Binding var options: ExportOptions
    let regenerate: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: options.sizePreset)      { regenerate() }
            .onChange(of: options.backgroundStyle) { regenerate() }
            .onChange(of: options.showDate)        { regenerate() }
            .onChange(of: options.showVenue)       { regenerate() }
            .onChange(of: options.showBadge)       { regenerate() }
            .onChange(of: options.showPrice)       { regenerate() }
            .onChange(of: options.showNotes)       { regenerate() }
            .onChange(of: options.showTickets)     { regenerate() }
            .onChange(of: options.cardStyle)       { regenerate() }
            .onChange(of: options.columns)         { regenerate() }
            .onChange(of: options.cardOpacity)     { regenerate() }
            .onChange(of: options.headerStyle)     { regenerate() }
            .onChange(of: options.fontStyle)       { regenerate() }
            .onChange(of: options.badgeText)       { regenerate() }
            .onChange(of: options.subtitleText)    { regenerate() }
            .onChange(of: options.dateFormatStyle) { regenerate() }
            .onChange(of: options.scrimIntensity)  { regenerate() }
            .onChange(of: options.gridGap)         { regenerate() }
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
