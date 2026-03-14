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
    @State private var textColor: Color?      = nil  // nil = auto
    @State private var useAutoTextColor: Bool = true
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

    private var textColorHex: String? {
        guard !useAutoTextColor, let tc = textColor else { return nil }
        let ui = UIColor(tc)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }

    // Text color presets
    private static let textColorPresets: [String] = [
        "#FFFFFF", "#F5F5F5", "#E0E0E0", "#BDBDBD",
        "#1A1A1A", "#333333", "#666666", "#999999"
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
            .onChange(of: textColor)               { regenerateImage() }
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
                artistNameSection
                platformSizeSection
                textColorSection
                customTextSection
                headerStyleSection
                fontStyleSection
                dateFormatSection
                fineTuningSection
                gridColumnsSection
                rowCountSection
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
                        PresetButtonLabel(
                            icon: preset.icon,
                            title: preset.rawValue,
                            subtitle: "\(Int(preset.size.width))x\(Int(preset.size.height))"
                        )
                        .background(selected ? Color.accentColor : Color.secondary.opacity(0.1))
                        .foregroundStyle(selected ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.2), value: options.sizePreset)
                }
            }
        }
    }

    private var textColorSection: some View {
        sectionCard(title: "Text Color", icon: "textformat") {
            VStack(spacing: 12) {
                // Auto toggle
                Toggle(isOn: $useAutoTextColor) {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14))
                        Text("Auto (based on background)")
                            .font(.system(size: 14))
                    }
                }
                .tint(Color.accentColor)
                .onChange(of: useAutoTextColor) {
                    if useAutoTextColor {
                        textColor = nil
                    } else if textColor == nil {
                        textColor = .white
                    }
                    regenerateImage()
                }

                if !useAutoTextColor {
                    // Preset colors
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(Self.textColorPresets, id: \.self) { hex in
                                Button {
                                    if let c = Color(hex: hex) { textColor = c }
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex) ?? .gray)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle().stroke(.gray.opacity(0.4), lineWidth: 1)
                                        )
                                        .overlay(
                                            textColorSelectionRing(hex: hex)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        ColorPicker("", selection: Binding(
                            get: { textColor ?? .white },
                            set: { textColor = $0 }
                        ), supportsOpacity: false)
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
    }

    @ViewBuilder
    private func textColorSelectionRing(hex: String) -> some View {
        if let currentHex = textColorHex, currentHex.uppercased() == hex.uppercased() {
            Circle()
                .stroke(Color.accentColor, lineWidth: 2.5)
                .frame(width: 38, height: 38)
        }
    }

    private var customTextSection: some View {
        sectionCard(title: "Custom Text", icon: "character.cursor.ibeam") {
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

    private var headerStyleSection: some View {
        sectionCard(title: "Header Style", icon: "text.alignleft") {
            HStack(spacing: 8) {
                ForEach(HeaderStyle.allCases) { style in
                    let selected = options.headerStyle == style
                    Button { options.headerStyle = style } label: {
                        SimplePresetButtonLabel(icon: style.icon, title: style.rawValue)
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
                        SimplePresetButtonLabel(icon: style.icon, title: style.rawValue, iconSize: 14, titleSize: 10)
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

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Show Padding")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(options.showPadding < 0.6 ? "Tight" : options.showPadding > 1.4 ? "Loose" : "Normal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $options.showPadding, in: 0.2...2.0, step: 0.1)
                        .tint(Color.accentColor)
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

    private var rowCountSection: some View {
        sectionCard(title: "Max Shows", icon: "list.number") {
            HStack(spacing: 8) {
                ForEach([0, 3, 5, 8, 10, 15], id: \.self) { count in
                    let selected = options.maxRows == count
                    Button { options.maxRows = count } label: {
                        Text(count == 0 ? "All" : "\(count)")
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
            TogglesList(options: $options)
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
        opts.textColorHex = textColorHex
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

// MARK: - Helper Subviews to reduce inline complexity

private struct PresetButtonLabel: View {
    let icon: String
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

private struct SimplePresetButtonLabel: View {
    let icon: String
    let title: String
    let iconSize: CGFloat
    let titleSize: CGFloat

    init(icon: String, title: String, iconSize: CGFloat = 16, titleSize: CGFloat = 11) {
        self.icon = icon
        self.title = title
        self.iconSize = iconSize
        self.titleSize = titleSize
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
            Text(title)
                .font(.system(size: titleSize, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
    }
}

private struct TogglesList: View {
    @Binding var options: ExportOptions

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            toggleRow(isOn: $options.showDate, title: "Date & Time")
            toggleRow(isOn: $options.showVenue, title: "Venue")
        }
    }

    private func toggleRow(isOn: Binding<Bool>, title: String) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.subheadline)
        }
        .tint(Color.accentColor)
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
            .onChange(of: options.dateFormatStyle) { regenerate() }
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

 
