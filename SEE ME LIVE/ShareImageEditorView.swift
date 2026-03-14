//
//  ShareImageEditorView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/5/26.
//

import SwiftUI
import PhotosUI

// MARK: - Share Image Editor View
/// A full-screen canvas editor for customising the share image.
/// Supports custom backgrounds (solid colour, gradient, photo),
/// draggable text overlays with font/size/colour controls.

struct ShareImageEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let shows: [Show]
    let performerName: String
    @Binding var options: ExportOptions

    // MARK: - Local State
    @State private var cachedImage: UIImage = UIImage()
    @State private var renderTask: Task<Void, Never>?

    // Background
    @State private var bgKind: CustomBackground.Kind = .solidColor
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

    // Bottom panel
    @State private var activePanel: EditorPanel = .background

    // Canvas geometry
    @State private var canvasSize: CGSize = .zero

    private enum EditorPanel: String, CaseIterable {
        case background = "Background"
        case text = "Text"
        case style = "Style"

        var icon: String {
            switch self {
            case .background: return "paintpalette"
            case .text:       return "textformat"
            case .style:      return "slider.horizontal.3"
            }
        }
    }

    // MARK: - Available Fonts

    private static let availableFonts: [(name: String, display: String)] = [
        ("System", "SF Pro"),
        ("AvenirNext-Bold", "Avenir Next"),
        ("Georgia-Bold", "Georgia"),
        ("Futura-Bold", "Futura"),
        ("Menlo-Bold", "Menlo"),
        ("GillSans-Bold", "Gill Sans"),
        ("Rockwell-Bold", "Rockwell"),
        ("Palatino-Bold", "Palatino"),
        ("Copperplate-Bold", "Copperplate"),
        ("AmericanTypewriter-Bold", "Typewriter")
    ]

    private static let fontWeights: [(name: String, display: String)] = [
        ("regular", "Regular"),
        ("medium", "Medium"),
        ("semibold", "Semibold"),
        ("bold", "Bold"),
        ("heavy", "Heavy"),
        ("black", "Black")
    ]

    private static let presetColors: [String] = [
        "#FFFFFF", "#000000", "#FF3B30", "#FF9500", "#FFCC00",
        "#34C759", "#007AFF", "#AF52DE", "#FF2D55", "#CC7057"
    ]

    private static let gradientPresets: [(from: String, to: String, label: String)] = [
        ("#1A0A00", "#3D1C00", "Warm Brown"),
        ("#0F0C29", "#302B63", "Deep Purple"),
        ("#000000", "#434343", "Charcoal"),
        ("#1A1A2E", "#16213E", "Midnight"),
        ("#2C3E50", "#4CA1AF", "Ocean"),
        ("#141E30", "#243B55", "Royal"),
        ("#232526", "#414345", "Slate"),
        ("#FF416C", "#FF4B2B", "Sunset")
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Canvas ──
                    canvasPreview
                        .padding(.horizontal, 12)
                        .padding(.top, 8)

                    Spacer(minLength: 8)

                    // ── Tab Bar ──
                    panelTabBar
                        .padding(.top, 4)

                    // ── Active Panel ──
                    panelContent
                        .frame(height: 220)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeInOut(duration: 0.2), value: activePanel)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .principal) {
                    Text("Edit Image")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { applyAndDismiss() }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear { loadInitialState(); regeneratePreview() }
        .onChange(of: bgKind) { regeneratePreview() }
        .onChange(of: solidColor) { regeneratePreview() }
        .onChange(of: gradFrom) { regeneratePreview() }
        .onChange(of: gradTo) { regeneratePreview() }
        .onChange(of: bgPhotoData) { regeneratePreview() }
        .onChange(of: overlays.count) { regeneratePreview() }
        .sheet(isPresented: $showAddTextSheet) {
            AddTextOverlaySheet(text: $newOverlayText) { finishedText in
                guard !finishedText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                let overlay = TextOverlay(text: finishedText)
                overlays.append(overlay)
                selectedOverlayID = overlay.id
                newOverlayText = ""
                regeneratePreview()
            }
            .presentationDetents([.height(200)])
        }
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
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                // Draggable text overlays on canvas
                ForEach(Array(overlays.enumerated()), id: \.element.id) { idx, overlay in
                    DraggableTextLabel(
                        overlay: $overlays[idx],
                        canvasSize: CGSize(width: fitW, height: fitH),
                        isSelected: selectedOverlayID == overlay.id,
                        onTap: { selectedOverlayID = overlay.id },
                        onDragEnd: { regeneratePreview() }
                    )
                }
            }
            .frame(width: fitW, height: fitH)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { canvasSize = CGSize(width: fitW, height: fitH) }
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
                            .font(.system(size: 18, weight: .semibold))
                        Text(panel.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(activePanel == panel ? Color.accentColor : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
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
            switch activePanel {
            case .background: backgroundPanel
            case .text:       textPanel
            case .style:      stylePanel
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Background Panel

    private var backgroundPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Kind picker
            HStack(spacing: 8) {
                bgKindButton("Solid", icon: "circle.fill", kind: .solidColor)
                bgKindButton("Gradient", icon: "paintpalette.fill", kind: .gradient)
                bgKindButton("Photo", icon: "photo.fill", kind: .photo)
            }

            switch bgKind {
            case .solidColor:
                HStack(spacing: 10) {
                    ForEach(Self.presetColors, id: \.self) { hex in
                        Button {
                            solidColor = Color(hex: hex) ?? .black
                        } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .black)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                                .overlay(
                                    colorHex(solidColor) == hex ?
                                    Circle().stroke(Color.accentColor, lineWidth: 2.5)
                                        .frame(width: 38, height: 38) : nil
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack(spacing: 12) {
                    ColorPicker("Custom", selection: $solidColor, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 44, height: 44)
                    Text("Pick any colour")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .gradient:
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(Self.gradientPresets, id: \.label) { preset in
                            Button {
                                gradFrom = Color(hex: preset.from) ?? .black
                                gradTo = Color(hex: preset.to) ?? .gray
                            } label: {
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: preset.from) ?? .black,
                                                         Color(hex: preset.to) ?? .gray],
                                                startPoint: .top, endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(.white.opacity(0.2), lineWidth: 1)
                                        )
                                    Text(preset.label)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("From")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        ColorPicker("", selection: $gradFrom, supportsOpacity: false)
                            .labelsHidden()
                    }
                    VStack(spacing: 4) {
                        Text("To")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        ColorPicker("", selection: $gradTo, supportsOpacity: false)
                            .labelsHidden()
                    }
                }

            case .photo:
                HStack(spacing: 16) {
                    PhotosPicker(selection: $bgPhotoItem, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text(bgPhotoData != nil ? "Change Photo" : "Choose Photo")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    if let thumb = bgPhotoThumb {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .onChange(of: bgPhotoItem) { _, newItem in
                    Task { await loadBGPhoto(from: newItem) }
                }
            }
        }
    }

    // MARK: - Text Panel

    private var textPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Add text button
            Button {
                showAddTextSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Add Text")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            if overlays.isEmpty {
                Text("Tap + Add Text to place custom text on your image.\nDrag text on the canvas to reposition.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }

            // Overlay list
            ForEach(Array(overlays.enumerated()), id: \.element.id) { idx, overlay in
                overlayRow(idx: idx, overlay: overlay)
            }
        }
    }

    private func overlayRow(idx: Int, overlay: TextOverlay) -> some View {
        let isSelected = selectedOverlayID == overlay.id

        return VStack(spacing: 8) {
            HStack {
                Text(overlay.text)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    overlays.remove(at: idx)
                    if selectedOverlayID == overlay.id { selectedOverlayID = nil }
                    regeneratePreview()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.white.opacity(0.06))
            )
            .onTapGesture { selectedOverlayID = overlay.id }

            if isSelected {
                selectedOverlayControls(idx: idx)
            }
        }
    }

    @ViewBuilder
    private func selectedOverlayControls(idx: Int) -> some View {
        VStack(spacing: 10) {
            // Font picker
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Self.availableFonts, id: \.name) { font in
                        let isActive = overlays[idx].fontName == font.name
                        Button {
                            overlays[idx].fontName = font.name
                            regeneratePreview()
                        } label: {
                            Text(font.display)
                                .font(.system(size: 12, weight: isActive ? .bold : .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isActive ? Color.accentColor : Color.white.opacity(0.08),
                                            in: Capsule())
                                .foregroundStyle(isActive ? .white : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Size slider
            HStack(spacing: 10) {
                Image(systemName: "textformat.size.smaller")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Slider(value: $overlays[idx].fontSize, in: 0.03...0.20, step: 0.005)
                    .tint(Color.accentColor)
                    .onChange(of: overlays[idx].fontSize) { regeneratePreview() }
                Image(systemName: "textformat.size.larger")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            // Weight + colour
            HStack(spacing: 12) {
                // Weight picker
                Menu {
                    ForEach(Self.fontWeights, id: \.name) { w in
                        Button {
                            overlays[idx].fontWeight = w.name
                            regeneratePreview()
                        } label: {
                            HStack {
                                Text(w.display)
                                if overlays[idx].fontWeight == w.name {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(Self.fontWeights.first { $0.name == overlays[idx].fontWeight }?.display ?? "Bold")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08), in: Capsule())
                    .foregroundStyle(.white)
                }

                // Colour
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(Self.presetColors, id: \.self) { hex in
                            Button {
                                overlays[idx].colorHex = hex
                                regeneratePreview()
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex) ?? .white)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle().stroke(.white.opacity(0.3), lineWidth: 0.5)
                                    )
                                    .overlay(
                                        overlays[idx].colorHex == hex ?
                                        Circle().stroke(Color.accentColor, lineWidth: 2)
                                            .frame(width: 29, height: 29) : nil
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    // MARK: - Style Panel

    private var stylePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: Binding(
                get: { options.showDate },
                set: { options.showDate = $0; regeneratePreview() }
            )) {
                Label("Date", systemImage: "calendar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            .tint(Color.accentColor)

            Toggle(isOn: Binding(
                get: { options.showVenue },
                set: { options.showVenue = $0; regeneratePreview() }
            )) {
                Label("Venue", systemImage: "mappin.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            .tint(Color.accentColor)
        }
    }

    // MARK: - Helpers

    private func bgKindButton(_ label: String, icon: String, kind: CustomBackground.Kind) -> some View {
        let isActive = bgKind == kind
        return Button {
            bgKind = kind
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? Color.accentColor : Color.white.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundStyle(isActive ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func colorHex(_ color: Color) -> String {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    private func loadInitialState() {
        let bg = options.customBackground
        bgKind = bg.kind
        solidColor = Color(hex: bg.solidHex) ?? .black
        gradFrom = Color(hex: bg.gradientFromHex) ?? .black
        gradTo = Color(hex: bg.gradientToHex) ?? .gray
        bgPhotoData = bg.photoData
        if let data = bg.photoData, let img = UIImage(data: data) {
            bgPhotoThumb = img
        }
        overlays = options.textOverlays
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

    private func regeneratePreview() {
        renderTask?.cancel()
        var opts = options
        opts.backgroundStyle = .custom
        opts.customBackground = buildCustomBG()
        opts.textOverlays = overlays
        
        // Snapshot Show managed objects on the main thread (safe).
        let snapshots = shows.map { ShowSnapshot(from: $0) }
        let name = performerName.isEmpty ? "My Shows" : performerName
        
        renderTask = Task { @MainActor in
            let img = await Task.detached(priority: .userInitiated) {
                ShareImageGenerator.generate(snapshots: snapshots, performerName: name, options: opts)
            }.value
            
            guard !Task.isCancelled else { return }
            cachedImage = img
        }
    }

    private func applyAndDismiss() {
        options.backgroundStyle = .custom
        options.customBackground = buildCustomBG()
        options.textOverlays = overlays
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        dismiss()
    }

    private func loadBGPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run {
                bgPhotoData = data
                if let img = UIImage(data: data) {
                    bgPhotoThumb = img
                }
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

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        let cx = overlay.positionX * canvasSize.width
        let cy = overlay.positionY * canvasSize.height

        Text(overlay.text)
            .font(resolvedFont)
            .foregroundStyle(Color(hex: overlay.colorHex) ?? .white)
            .rotationEffect(.degrees(overlay.rotation))
            .padding(6)
            .background(
                isSelected ?
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                : nil
            )
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
        let size = overlay.fontSize * canvasSize.width * 0.4  // scale down for preview
        let weight: Font.Weight = {
            switch overlay.fontWeight.lowercased() {
            case "ultralight": return .ultraLight
            case "thin":       return .thin
            case "light":      return .light
            case "regular":    return .regular
            case "medium":     return .medium
            case "semibold":   return .semibold
            case "bold":       return .bold
            case "heavy":      return .heavy
            case "black":      return .black
            default:           return .bold
            }
        }()
        if overlay.fontName == "System" {
            return .system(size: size, weight: weight)
        } else {
            return .custom(overlay.fontName, size: size)
        }
    }
}

// MARK: - Add Text Overlay Sheet

private struct AddTextOverlaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    let onAdd: (String) -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Enter text…", text: $text)
                    .font(.system(size: 18, weight: .medium))
                    .padding(14)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .focused($isFocused)

                Button {
                    onAdd(text)
                    dismiss()
                } label: {
                    Text("Add to Canvas")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            text.trimmingCharacters(in: .whitespaces).isEmpty ?
                            Color(.systemGray4) : Color.accentColor,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .foregroundStyle(.white)
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)

                Spacer()
            }
            .padding(16)
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

#Preview {
    ShareImageEditorView(
        shows: [],
        performerName: "Taylor Drew",
        options: .constant(ExportOptions())
    )
}
