//
//  ShareImageEditorView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/5/26.
//

import SwiftUI
import PhotosUI

// MARK: - Share Image Editor View
/// A full-screen flyer editor with customization and export.

struct ShareImageEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let shows: [Show]
    let performerName: String

    // MARK: - Local State
    @State private var options: ExportOptions = ExportOptions()
    @State private var cachedImage: UIImage = UIImage()
    @State private var renderTask: Task<Void, Never>?
    @State private var isRendering: Bool = false
    @State private var debounceTask: Task<Void, Never>?

    // Background
    @State private var bgKind: CustomBackground.Kind = .gradient
    @State private var solidColor: Color = Color(hex: "#1A0A00") ?? .black
    @State private var gradFrom: Color = Color(hex: "#1A0A00") ?? .black
    @State private var gradTo: Color = Color(hex: "#3D1C00") ?? .brown
    @State private var bgPhotoItem: PhotosPickerItem?
    @State private var bgPhotoData: Data?
    @State private var bgPhotoThumb: UIImage?

    // Text overlays
    @State private var overlays: [TextOverlay] = []
    @State private var selectedOverlayID: UUID?
    @State private var newOverlayText: String = ""
    @State private var showAddTextSheet = false
    @State private var showTextStyleSheet = false
    @State private var editingOverlayIndex: Int?

    // Colors
    @State private var accentColor: Color = Color("AccentColor")
    @State private var textColor: Color = .white

    // Bottom panel
    @State private var activePanel: EditorPanel = .layout

    private enum EditorPanel: String, CaseIterable {
        case layout = "Layout"
        case background = "Background"
        case content = "Content"
        case text = "Add Text"

        var icon: String {
            switch self {
            case .layout:     return "square.grid.2x2"
            case .background: return "paintpalette"
            case .content:    return "checklist"
            case .text:       return "textformat"
            }
        }
    }

    // Preset colors
    private static let presetColors: [String] = [
        "#FFFFFF", "#000000", "#EB2429", "#FF9500", "#FFCC00",
        "#34C759", "#007AFF", "#AF52DE", "#FF2D55", "#CC7057"
    ]

    private static let gradientPresets: [(from: String, to: String, label: String)] = [
        ("#1A0A00", "#3D1C00", "Warm"),
        ("#0F0C29", "#302B63", "Purple"),
        ("#000000", "#434343", "Dark"),
        ("#2C3E50", "#4CA1AF", "Ocean"),
        ("#FF416C", "#FF4B2B", "Sunset"),
        ("#141E30", "#243B55", "Royal")
    ]
    
    private static let fontWeights: [(weight: String, label: String)] = [
        ("light", "Light"),
        ("regular", "Regular"),
        ("medium", "Medium"),
        ("semibold", "Semibold"),
        ("bold", "Bold"),
        ("heavy", "Heavy"),
        ("black", "Black")
    ]
    
    private static let fontNames: [(name: String, label: String)] = [
        ("System", "Default"),
        ("Georgia", "Serif"),
        ("Courier New", "Mono"),
        ("Futura", "Modern"),
        ("Didot", "Elegant"),
        ("Marker Felt", "Casual"),
        ("Copperplate", "Classic")
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Canvas preview
                    canvasPreview
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Export button
                    exportButton
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    // Tab bar
                    panelTabBar
                        .padding(.top, 8)

                    // Panel content
                    panelContent
                        .frame(height: 180)
                        .animation(.easeInOut(duration: 0.2), value: activePanel)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Create Flyer")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear { regeneratePreview() }
        // Background changes
        .onChange(of: bgKind) { regeneratePreviewDebounced() }
        .onChange(of: solidColor) { regeneratePreviewDebounced() }
        .onChange(of: gradFrom) { regeneratePreviewDebounced() }
        .onChange(of: gradTo) { regeneratePreviewDebounced() }
        .onChange(of: bgPhotoData) { regeneratePreview() }
        // Accent color
        .onChange(of: accentColor) { regeneratePreviewDebounced() }
        // Text overlays
        .onChange(of: overlays.count) { regeneratePreview() }
        // Layout & content options
        .onChange(of: options.sizePreset) { regeneratePreview() }
        .onChange(of: options.layoutTemplate) { regeneratePreview() }
        .onChange(of: options.showVenue) { regeneratePreview() }
        .onChange(of: options.showDate) { regeneratePreview() }
        .onChange(of: options.showTime) { regeneratePreview() }
        .onChange(of: options.showHeader) { regeneratePreview() }
        .onChange(of: options.cardStyle) { regeneratePreview() }
        .onChange(of: options.fontStyle) { regeneratePreview() }
        .sheet(isPresented: $showAddTextSheet) {
            AddTextSheet(text: $newOverlayText) { finishedText in
                guard !finishedText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                let overlay = TextOverlay(text: finishedText)
                overlays.append(overlay)
                selectedOverlayID = overlay.id
                newOverlayText = ""
                regeneratePreview()
            }
            .presentationDetents([.height(200)])
        }
        .sheet(isPresented: $showTextStyleSheet) {
            if let idx = editingOverlayIndex, idx < overlays.count {
                TextStyleSheet(
                    overlay: $overlays[idx],
                    presetColors: Self.presetColors,
                    fontWeights: Self.fontWeights,
                    fontNames: Self.fontNames,
                    onUpdate: { regeneratePreviewDebounced() }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Export Button

    private var exportButton: some View {
        Button(action: shareImage) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .bold))
                Text("Export Flyer")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.accentColor)
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 12, y: 5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Canvas Preview

    private var canvasPreview: some View {
        let aspect = options.sizePreset.size.width / options.sizePreset.size.height

        return GeometryReader { geo in
            let availW = geo.size.width
            let availH = geo.size.height
            let fitW = min(availW, availH * aspect)
            let fitH = fitW / aspect

            ZStack {
                Image(uiImage: cachedImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                    .opacity(isRendering ? 0.7 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isRendering)
                
                // Loading indicator
                if isRendering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }

                // Draggable text overlays
                ForEach(Array(overlays.enumerated()), id: \.element.id) { idx, overlay in
                    DraggableTextLabel(
                        overlay: $overlays[idx],
                        canvasSize: CGSize(width: fitW, height: fitH),
                        isSelected: selectedOverlayID == overlay.id,
                        onTap: { selectedOverlayID = overlay.id },
                        onDragEnd: { regeneratePreviewDebounced() },
                        onDelete: {
                            overlays.remove(at: idx)
                            selectedOverlayID = nil
                            regeneratePreview()
                        }
                    )
                }
            }
            .frame(width: fitW, height: fitH)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Panel Tab Bar

    private var panelTabBar: some View {
        HStack(spacing: 0) {
            ForEach(EditorPanel.allCases, id: \.rawValue) { panel in
                Button {
                    withAnimation(.spring(response: 0.3)) { activePanel = panel }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: panel.icon)
                            .font(.system(size: 20, weight: .semibold))
                        Text(panel.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(activePanel == panel ? Color.accentColor : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.06))
    }

    // MARK: - Panel Content

    @ViewBuilder
    private var panelContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch activePanel {
                case .layout:
                    layoutPanel
                case .background:
                    backgroundPanel
                case .content:
                    contentPanel
                case .text:
                    textPanel
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }

    // MARK: - Layout Panel

    private var layoutPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Template selector
            VStack(alignment: .leading, spacing: 10) {
                Text("TEMPLATE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(LayoutTemplate.allCases) { template in
                            templateCard(template)
                        }
                    }
                }
            }

            // Size selector
            VStack(alignment: .leading, spacing: 10) {
                Text("SIZE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SocialSizePreset.allCases) { preset in
                            sizeButton(preset)
                        }
                    }
                }
            }
        }
    }

    private func templateCard(_ template: LayoutTemplate) -> some View {
        let isSelected = options.layoutTemplate == template
        return Button {
            options.layoutTemplate = template
            regeneratePreview()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: template.icon)
                    .font(.system(size: 24, weight: .medium))
                    .frame(width: 56, height: 56)
                    .background(isSelected ? Color.accentColor : Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                Text(template.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                
                Text(template.description)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80)
            .foregroundStyle(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func sizeButton(_ preset: SocialSizePreset) -> some View {
        let isSelected = options.sizePreset == preset
        return Button {
            options.sizePreset = preset
            regeneratePreview()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: preset.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(preset.rawValue)
                    .font(.system(size: 10, weight: .semibold))
            }
            .frame(width: 70, height: 50)
            .background(isSelected ? Color.accentColor : Color.white.opacity(0.08))
            .foregroundStyle(isSelected ? .white : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Background Panel

    private var backgroundPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Background type
            HStack(spacing: 10) {
                bgTypeButton("Solid", icon: "circle.fill", kind: .solidColor)
                bgTypeButton("Gradient", icon: "paintpalette.fill", kind: .gradient)
                bgTypeButton("Photo", icon: "photo.fill", kind: .photo)
            }

            // Background options based on type
            switch bgKind {
            case .solidColor:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Self.presetColors, id: \.self) { hex in
                            colorCircle(hex: hex, isSelected: colorHex(solidColor) == hex) {
                                solidColor = Color(hex: hex) ?? .black
                            }
                        }
                        ColorPicker("", selection: $solidColor, supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 36, height: 36)
                    }
                }

            case .gradient:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Self.gradientPresets, id: \.label) { preset in
                            gradientButton(preset)
                        }
                    }
                }

            case .photo:
                HStack(spacing: 12) {
                    PhotosPicker(selection: $bgPhotoItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text(bgPhotoData != nil ? "Change" : "Choose Photo")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    if let thumb = bgPhotoThumb {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .onChange(of: bgPhotoItem) { _, newItem in
                    Task { await loadBGPhoto(from: newItem) }
                }
            }

            // Accent color
            VStack(alignment: .leading, spacing: 8) {
                Text("ACCENT COLOR")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Self.presetColors, id: \.self) { hex in
                            colorCircle(hex: hex, isSelected: colorHex(accentColor) == hex) {
                                accentColor = Color(hex: hex) ?? .white
                                options.accentHex = hex
                                regeneratePreview()
                            }
                        }
                    }
                }
            }
        }
    }

    private func bgTypeButton(_ label: String, icon: String, kind: CustomBackground.Kind) -> some View {
        let isActive = bgKind == kind
        return Button {
            bgKind = kind
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isActive ? Color.accentColor : Color.white.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundStyle(isActive ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func colorCircle(hex: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(Color(hex: hex) ?? .gray)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle().stroke(.white.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    isSelected ? Circle().stroke(Color.accentColor, lineWidth: 3).frame(width: 42, height: 42) : nil
                )
        }
        .buttonStyle(.plain)
    }

    private func gradientButton(_ preset: (from: String, to: String, label: String)) -> some View {
        Button {
            gradFrom = Color(hex: preset.from) ?? .black
            gradTo = Color(hex: preset.to) ?? .gray
        } label: {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: preset.from) ?? .black, Color(hex: preset.to) ?? .gray],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                Text(preset.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content Panel

    private var contentPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SHOW / HIDE")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1)
            
            VStack(spacing: 12) {
                contentToggle(title: "Show Title", subtitle: "Event name", isOn: Binding(
                    get: { true },
                    set: { _ in }
                ), icon: "text.alignleft", disabled: true)
                
                contentToggle(title: "Show Venue", subtitle: "Location name", isOn: Binding(
                    get: { options.showVenue },
                    set: { options.showVenue = $0; regeneratePreview() }
                ), icon: "mappin.circle")
                
                contentToggle(title: "Show Date", subtitle: "Day & month badge", isOn: Binding(
                    get: { options.showDate },
                    set: { options.showDate = $0; regeneratePreview() }
                ), icon: "calendar")
                
                contentToggle(title: "Show Time", subtitle: "Event time", isOn: Binding(
                    get: { options.showTime },
                    set: { options.showTime = $0; regeneratePreview() }
                ), icon: "clock")
            }
        }
    }

    private func contentToggle(title: String, subtitle: String, isOn: Binding<Bool>, icon: String, disabled: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(disabled ? .secondary : Color.accentColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(disabled ? Color.secondary : Color.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.accentColor)
                .disabled(disabled)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Text Panel

    private var textPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Add new text button
            Button {
                showAddTextSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add Custom Text")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Add your name, tagline, or any text")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(Color.accentColor)
                .padding(14)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            if overlays.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "text.badge.plus")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No text added yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("Tap above to add your name or tagline")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // List of overlays with edit buttons
                ForEach(Array(overlays.enumerated()), id: \.element.id) { idx, overlay in
                    overlayEditRow(idx: idx, overlay: overlay)
                }
            }
        }
    }

    private func overlayEditRow(idx: Int, overlay: TextOverlay) -> some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                // Preview badge
                Text(overlay.text.prefix(3).uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Color(hex: overlay.colorHex) ?? .white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                // Text and info
                VStack(alignment: .leading, spacing: 2) {
                    Text(overlay.text)
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(1)
                        .foregroundStyle(.white)
                    Text("\(overlay.fontName) • \(overlay.fontWeight.capitalized)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Edit button
                Button {
                    editingOverlayIndex = idx
                    showTextStyleSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor.opacity(0.15), in: Circle())
                }
                .buttonStyle(.plain)
                
                // Delete button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        overlays.remove(at: idx)
                        if selectedOverlayID == overlay.id { selectedOverlayID = nil }
                        regeneratePreview()
                    }
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selectedOverlayID == overlay.id ? Color.accentColor.opacity(0.15) : Color.white.opacity(0.06))
            )
            .onTapGesture { 
                selectedOverlayID = overlay.id 
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    // MARK: - Helpers

    private func colorHex(_ color: Color) -> String {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    private func buildCustomBG() -> CustomBackground {
        var bg = CustomBackground()
        bg.kind = bgKind
        bg.solidHex = colorHex(solidColor)
        bg.gradientFromHex = colorHex(gradFrom)
        bg.gradientToHex = colorHex(gradTo)
        bg.photoData = bgPhotoData
        return bg
    }

    private func regeneratePreviewDebounced() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms debounce
            guard !Task.isCancelled else { return }
            regeneratePreview()
        }
    }

    private func regeneratePreview() {
        renderTask?.cancel()
        isRendering = true
        
        var opts = options
        opts.backgroundStyle = .custom
        opts.customBackground = buildCustomBG()
        opts.textOverlays = overlays
        opts.accentHex = colorHex(accentColor)
        
        let now = Date()
        let upcomingShows = shows.filter { ($0.date ?? now) >= now }
        let snapshots = upcomingShows.map { ShowSnapshot(from: $0) }
        let name = performerName.isEmpty ? "My Shows" : performerName
        
        renderTask = Task { @MainActor in
            let img = await Task.detached(priority: .userInitiated) {
                ShareImageGenerator.generate(snapshots: snapshots, performerName: name, options: opts)
            }.value
            
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                cachedImage = img
                isRendering = false
            }
        }
    }

    private func shareImage() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let image = cachedImage
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var top = root
        while let p = top.presentedViewController { top = p }
        if let pop = vc.popoverPresentationController {
            pop.sourceView = top.view
            pop.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        top.present(vc, animated: true)
    }

    private func loadBGPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            let thumb = await Task.detached(priority: .userInitiated) {
                if let img = UIImage(data: data) {
                    return img.preparingThumbnail(of: CGSize(width: 300, height: 300))
                }
                return nil
            }.value

            await MainActor.run {
                bgPhotoData = data
                bgPhotoThumb = thumb
                regeneratePreview()
            }
        }
    }
}

// MARK: - Draggable Text Label

private struct DraggableTextLabel: View {
    @Binding var overlay: TextOverlay
    let canvasSize: CGSize
    let isSelected: Bool
    let onTap: () -> Void
    let onDragEnd: () -> Void
    let onDelete: () -> Void

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        let cx = overlay.positionX * canvasSize.width
        let cy = overlay.positionY * canvasSize.height

        ZStack(alignment: .topTrailing) {
            Text(overlay.text)
                .font(resolvedFont)
                .foregroundStyle(Color(hex: overlay.colorHex) ?? .white)
                .rotationEffect(.degrees(overlay.rotation))
                .padding(8)
                .background(
                    isSelected ?
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.accentColor, lineWidth: 2)
                        )
                    : nil
                )
            
            if isSelected {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white, .red)
                }
                .offset(x: 8, y: -8)
            }
        }
        .position(x: cx + dragOffset.width, y: cy + dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let newX = (cx + value.translation.width) / canvasSize.width
                    let newY = (cy + value.translation.height) / canvasSize.height
                    overlay.positionX = max(0.05, min(0.95, newX))
                    overlay.positionY = max(0.05, min(0.95, newY))
                    dragOffset = .zero
                    onDragEnd()
                }
        )
        .onTapGesture { onTap() }
    }

    private var resolvedFont: Font {
        let size = overlay.fontSize * canvasSize.width * 0.4
        let weight: Font.Weight = {
            switch overlay.fontWeight.lowercased() {
            case "ultralight": return .ultraLight
            case "thin": return .thin
            case "light": return .light
            case "regular": return .regular
            case "medium": return .medium
            case "semibold": return .semibold
            case "bold": return .bold
            case "heavy": return .heavy
            case "black": return .black
            default: return .bold
            }
        }()
        if overlay.fontName == "System" {
            return .system(size: size, weight: weight)
        } else {
            return .custom(overlay.fontName, size: size)
        }
    }
}

// MARK: - Add Text Sheet

private struct AddTextSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    let onAdd: (String) -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Your name, tagline, etc.", text: $text)
                    .font(.system(size: 20, weight: .medium))
                    .padding(16)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .focused($isFocused)

                Button {
                    onAdd(text)
                    dismiss()
                } label: {
                    Text("Add to Flyer")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            text.trimmingCharacters(in: .whitespaces).isEmpty ?
                            Color(.systemGray4) : Color.accentColor,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .foregroundStyle(.white)
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Add Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear { isFocused = true }
    }
}

// MARK: - Text Style Sheet

private struct TextStyleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var overlay: TextOverlay
    let presetColors: [String]
    let fontWeights: [(weight: String, label: String)]
    let fontNames: [(name: String, label: String)]
    let onUpdate: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Live preview
                    previewSection
                    
                    // Text content
                    textSection
                    
                    // Font selection
                    fontSection
                    
                    // Size and weight
                    sizeWeightSection
                    
                    // Color
                    colorSection
                    
                    // Effects
                    effectsSection
                    
                    // Position
                    positionSection
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Style Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var previewSection: some View {
        VStack(spacing: 8) {
            Text("Preview")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.9), Color.gray.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(overlay.text)
                    .font(previewFont)
                    .foregroundStyle(Color(hex: overlay.colorHex) ?? .white)
                    .shadow(color: overlay.shadowEnabled ? .black.opacity(overlay.shadowOpacity) : .clear, radius: 4, y: 2)
                    .padding()
            }
            .frame(height: 100)
        }
    }
    
    private var previewFont: Font {
        let weight: Font.Weight = {
            switch overlay.fontWeight.lowercased() {
            case "light": return .light
            case "regular": return .regular
            case "medium": return .medium
            case "semibold": return .semibold
            case "bold": return .bold
            case "heavy": return .heavy
            case "black": return .black
            default: return .bold
            }
        }()
        if overlay.fontName == "System" {
            return .system(size: 28, weight: weight)
        } else {
            return .custom(overlay.fontName, size: 28)
        }
    }
    
    private var textSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TEXT")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            
            TextField("Your text", text: $overlay.text)
                .font(.system(size: 17))
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onChange(of: overlay.text) { onUpdate() }
        }
    }
    
    private var fontSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FONT")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(fontNames, id: \.name) { font in
                        Button {
                            overlay.fontName = font.name
                            onUpdate()
                        } label: {
                            Text(font.label)
                                .font(font.name == "System" ? .system(size: 14, weight: .semibold) : .custom(font.name, size: 14))
                                .foregroundStyle(overlay.fontName == font.name ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    overlay.fontName == font.name ? Color.accentColor : Color(.secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var sizeWeightSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Font size
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("SIZE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(overlay.fontSize * 100))%")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $overlay.fontSize, in: 0.04...0.20, step: 0.01)
                    .tint(Color.accentColor)
                    .onChange(of: overlay.fontSize) { onUpdate() }
            }
            
            // Font weight
            VStack(alignment: .leading, spacing: 8) {
                Text("WEIGHT")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(fontWeights, id: \.weight) { weight in
                            Button {
                                overlay.fontWeight = weight.weight
                                onUpdate()
                            } label: {
                                Text(weight.label)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(overlay.fontWeight == weight.weight ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        overlay.fontWeight == weight.weight ? Color.accentColor : Color(.secondarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("COLOR")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(presetColors, id: \.self) { hex in
                        Button {
                            overlay.colorHex = hex
                            onUpdate()
                        } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                                .overlay(
                                    overlay.colorHex == hex ?
                                    Circle()
                                        .stroke(Color.accentColor, lineWidth: 3)
                                        .frame(width: 44, height: 44)
                                    : nil
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    ColorPicker("", selection: Binding(
                        get: { Color(hex: overlay.colorHex) ?? .white },
                        set: { color in
                            let uiColor = UIColor(color)
                            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
                            uiColor.getRed(&r, green: &g, blue: &b, alpha: nil)
                            overlay.colorHex = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
                            onUpdate()
                        }
                    ), supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 36, height: 36)
                }
            }
        }
    }
    
    private var effectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EFFECTS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            
            // Shadow toggle
            HStack {
                Image(systemName: "shadow")
                    .font(.system(size: 16))
                    .foregroundStyle(overlay.shadowEnabled ? Color.accentColor : .secondary)
                    .frame(width: 24)
                
                Text("Shadow")
                    .font(.system(size: 15))
                
                Spacer()
                
                Toggle("", isOn: $overlay.shadowEnabled)
                    .labelsHidden()
                    .tint(Color.accentColor)
                    .onChange(of: overlay.shadowEnabled) { onUpdate() }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            if overlay.shadowEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Opacity")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(overlay.shadowOpacity * 100))%")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $overlay.shadowOpacity, in: 0.1...1.0)
                        .tint(Color.accentColor)
                        .onChange(of: overlay.shadowOpacity) { onUpdate() }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var positionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("POSITION")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            
            // Rotation
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "rotate.right")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Text("Rotation")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(overlay.rotation))°")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $overlay.rotation, in: -45...45, step: 1)
                    .tint(Color.accentColor)
                    .onChange(of: overlay.rotation) { onUpdate() }
            }
            
            // Quick position buttons
            HStack(spacing: 8) {
                ForEach(["Top", "Center", "Bottom"], id: \.self) { pos in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            switch pos {
                            case "Top": overlay.positionY = 0.12
                            case "Center": overlay.positionY = 0.5
                            case "Bottom": overlay.positionY = 0.88
                            default: break
                            }
                            onUpdate()
                        }
                    } label: {
                        Text(pos)
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("Drag the text on the preview to fine-tune position")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }
}

// MARK: - Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    ShareImageEditorView(
        shows: [],
        performerName: "Taylor Drew"
    )
}
