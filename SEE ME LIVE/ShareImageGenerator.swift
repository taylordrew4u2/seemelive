//
//  ShareImageGenerator.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import UIKit

// MARK: - Social Size Preset

enum SocialSizePreset: String, CaseIterable, Identifiable {
    case instagramStory = "IG Story"
    case instagramPost  = "IG Post"
    case tiktok         = "TikTok"
    case twitter        = "X / Twitter"
    case facebook       = "Facebook"
    case ogCard         = "Link Preview"

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .instagramStory, .tiktok: return CGSize(width: 1080, height: 1920)
        case .instagramPost:           return CGSize(width: 1080, height: 1080)
        case .twitter:                 return CGSize(width: 1600, height: 900)
        case .facebook:                return CGSize(width: 1200, height: 628)
        case .ogCard:                  return CGSize(width: 1200, height: 630)
        }
    }

    var icon: String {
        switch self {
        case .instagramStory, .instagramPost: return "camera.fill"
        case .tiktok:                         return "music.note"
        case .twitter:                        return "message.fill"
        case .facebook:                       return "person.2.fill"
        case .ogCard:                         return "link"
        }
    }

    var isVertical: Bool { size.height >= size.width }
}

// MARK: - Image Layout

enum ImageLayout: String, CaseIterable, Identifiable {
    case list = "List"
    case grid = "Grid"
    var id: String { rawValue }
    var icon: String { self == .list ? "list.bullet" : "square.grid.2x2" }
}

// MARK: - Background Style

enum BackgroundStyle: String, CaseIterable, Identifiable {
    case gradient = "Gradient"
    case dark     = "Dark"
    case light    = "Light"
    case flyer    = "Flyer"
    case custom   = "Custom"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .gradient: return "paintpalette.fill"
        case .dark:     return "moon.fill"
        case .light:    return "sun.max.fill"
        case .flyer:    return "photo.fill"
        case .custom:   return "wand.and.stars"
        }
    }
}

// MARK: - Custom Background Descriptor

struct CustomBackground {
    enum Kind { case solidColor, gradient, photo }
    var kind: Kind = .solidColor
    var solidHex: String = "#1A0A00"
    var gradientFromHex: String = "#1A0A00"
    var gradientToHex: String = "#3D1C00"
    var photoData: Data? = nil
}

// MARK: - Text Overlay Descriptor

struct TextOverlay: Identifiable {
    let id = UUID()
    var text: String
    var fontName: String = "System"       // "System" maps to SF Pro
    var fontSize: CGFloat = 0.08          // fraction of canvas width
    var fontWeight: String = "bold"       // "regular", "semibold", "bold", "heavy", "black"
    var colorHex: String = "#FFFFFF"
    var positionX: CGFloat = 0.5          // 0…1 fraction of canvas width (centre)
    var positionY: CGFloat = 0.10         // 0…1 fraction of canvas height (centre)
    var rotation: Double = 0             // degrees
}

// MARK: - Export Options

struct ExportOptions {
    var sizePreset:      SocialSizePreset = .instagramPost
    var backgroundStyle: BackgroundStyle  = .gradient
    var accentHex:       String           = "#CC7057"
    var showCount:       Int              = 4
    var showVenue:       Bool             = true
    var showDate:        Bool             = true
    var showBadge:       Bool             = true
    var showBottomBar:   Bool             = true

    // Custom editor additions
    var customBackground: CustomBackground = CustomBackground()
    var textOverlays: [TextOverlay] = []
}

// MARK: - Show Snapshot (thread-safe)

/// A Sendable value-type snapshot of a Show's display properties.
/// Use this to pass show data to background rendering tasks safely.
struct ShowSnapshot: Sendable {
    let title: String
    let role: String
    let venue: String
    let date: Date
    let price: Double
    let ticketLink: String
    let notes: String
    let flyerImageData: Data?

    var titleOrEmpty: String   { title }
    var venueOrEmpty: String   { venue }
    var roleOrEmpty: String    { role }
    var notesOrEmpty: String   { notes }
    var dateOrNow: Date        { date }

    var priceFormatted: String {
        price > 0 ? String(format: "$%.2f", price) : "Free"
    }

    var dateFormatted: String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE, MMM d"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return "\(dayFormatter.string(from: date)) · \(timeFormatter.string(from: date))"
    }

    var hasTicketLink: Bool {
        guard !ticketLink.isEmpty else { return false }
        let trimmed = ticketLink.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed) != nil
        }
        return URL(string: "https://" + trimmed) != nil
    }

    /// Create a snapshot from a Core Data Show (must be called on the Show's context queue).
    init(from show: Show) {
        self.title = show.title ?? ""
        self.role = show.role ?? ""
        self.venue = show.venue ?? ""
        self.date = show.date ?? Date()
        self.price = show.price
        self.ticketLink = show.ticketLink ?? ""
        self.notes = show.notes ?? ""
        self.flyerImageData = show.flyerImageData
    }
}

// MARK: - Share Image Generator

enum ShareImageGenerator {

    /// Generate from Core Data Show objects (snapshots them on the calling thread).
    /// Call this from the main actor when Show objects are available.
    static func generate(shows: [Show], performerName: String, options: ExportOptions) -> UIImage {
        let snapshots = shows.map { ShowSnapshot(from: $0) }
        return generate(snapshots: snapshots, performerName: performerName, options: options)
    }

    /// Generate from thread-safe ShowSnapshot values. Safe to call from any thread.
    static func generate(snapshots: [ShowSnapshot], performerName: String, options: ExportOptions) -> UIImage {
        let baseSize = options.sizePreset.size
        let size = computeCanvasSize(baseSize: baseSize, snapshots: snapshots, options: options)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            draw(in: ctx.cgContext, size: size, snapshots: snapshots,
                 performerName: performerName, options: options)
        }
    }

    // Legacy shim
    static func generate(shows: [Show], performerName: String, layout: ImageLayout = .list) -> UIImage {
        return generate(shows: shows, performerName: performerName, options: ExportOptions())
    }

    // MARK: - Compute dynamic canvas size

    private static func computeCanvasSize(baseSize: CGSize, snapshots: [ShowSnapshot],
                                          options: ExportOptions) -> CGSize {
        let allShows = snapshots.sorted { $0.dateOrNow < $1.dateOrNow }
        let count = allShows.count
        guard count > 0 else { return baseSize }

        let w = baseSize.width
        let isVertical = baseSize.height >= baseSize.width

        let baseRowH = isVertical ? w * 0.13 : baseSize.height * 0.135
        let rowH = baseRowH * 1.6

        let headerH: CGFloat = isVertical ? baseSize.height * 0.55 : baseSize.height * 0.35
        let bottomH: CGFloat = options.showBottomBar ? baseSize.height * 0.07 : baseSize.height * 0.05

        let neededH = headerH + (CGFloat(count) * rowH) + bottomH
        let finalH = max(baseSize.height, neededH)
        return CGSize(width: w, height: finalH)
    }

    // MARK: - Main draw

    private static func draw(in ctx: CGContext, size: CGSize, snapshots: [ShowSnapshot],
                              performerName: String, options: ExportOptions) {
        let rect     = CGRect(origin: .zero, size: size)
        let allShows = snapshots.sorted { $0.dateOrNow < $1.dateOrNow }
        let featured = allShows.first
        let accent   = UIColor(hex: options.accentHex)

        drawBackground(ctx: ctx, rect: rect, featured: featured, style: options.backgroundStyle,
                       customBG: options.customBackground)

        let scrim: CGFloat = options.backgroundStyle == .light ? 0 : 0.5
        ctx.setFillColor(UIColor.black.withAlphaComponent(scrim).cgColor)
        ctx.fill(rect)

        let textColor: UIColor = options.backgroundStyle == .light ? UIColor(hex: "#1A1A1A") : .white
        let subColor: UIColor  = options.backgroundStyle == .light
            ? UIColor(hex: "#555555")
            : UIColor.white.withAlphaComponent(0.7)

        if options.sizePreset.isVertical {
            drawVertical(ctx: ctx, size: size, allShows: allShows, featured: featured,
                         performerName: performerName, options: options,
                         accent: accent, textColor: textColor, subColor: subColor)
        } else {
            drawHorizontal(ctx: ctx, size: size, allShows: allShows, featured: featured,
                           performerName: performerName, options: options,
                           accent: accent, textColor: textColor, subColor: subColor)
        }

        if options.showBottomBar {
            let barH = size.height * 0.07
            ctx.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
            ctx.fill(CGRect(x: 0, y: size.height - barH, width: size.width, height: barH))
            drawText("SEE ME LIVE  +  Tap for tickets",
                     at: CGPoint(x: size.width * 0.05, y: size.height - barH * 0.72),
                     font: .systemFont(ofSize: size.width * 0.022, weight: .semibold),
                     color: accent, maxWidth: size.width * 0.9, canvasHeight: size.height)
        }

        if !options.textOverlays.isEmpty {
            drawTextOverlays(options.textOverlays, in: size, ctx: ctx)
        }
    }

    // MARK: - Vertical (Story / TikTok / Square)

    private static func drawVertical(ctx: CGContext, size: CGSize, allShows: [ShowSnapshot],
                                     featured: ShowSnapshot?, performerName: String,
                                     options: ExportOptions, accent: UIColor,
                                     textColor: UIColor, subColor: UIColor) {
        let pad = size.width * 0.07

        if let data = featured?.flyerImageData, let flyer = UIImage(data: data) {
            let flyerRect = CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.45)
            ctx.saveGState()
            ctx.clip(to: flyerRect)
            drawImage(flyer, in: flyerRect)
            let fadeColors = [UIColor.black.withAlphaComponent(0).cgColor,
                              UIColor.black.withAlphaComponent(0.85).cgColor] as CFArray
            if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: fadeColors, locations: [0, 1]) {
                ctx.drawLinearGradient(grad,
                                       start: CGPoint(x: 0, y: size.height * 0.28),
                                       end:   CGPoint(x: 0, y: size.height * 0.45),
                                       options: [])
            }
            ctx.restoreGState()
        }

        var curY = size.height * 0.50
        if options.showBadge {
            drawText("SEE ME LIVE", at: CGPoint(x: pad, y: curY),
                     font: .systemFont(ofSize: size.width * 0.035, weight: .bold),
                     color: accent, maxWidth: size.width * 0.86, canvasHeight: size.height)
            curY += size.width * 0.05
        }
        let nameFont = UIFont.systemFont(ofSize: size.width * 0.10, weight: .heavy)
        drawText(performerName.isEmpty ? "Upcoming Shows" : performerName,
                 at: CGPoint(x: pad, y: curY),
                 font: nameFont, color: textColor,
                 maxWidth: size.width * 0.86, canvasHeight: size.height)
        curY += nameFont.lineHeight * 1.5

        drawShowRows(ctx: ctx, size: size, allShows: allShows, options: options,
                     startY: curY, pad: pad, textColor: textColor, subColor: subColor,
                     titleSz: size.width * 0.044, subSz: size.width * 0.031,
                     rowH: size.width * 0.13)
    }

    // MARK: - Horizontal (Twitter / Facebook / OG)

    private static func drawHorizontal(ctx: CGContext, size: CGSize, allShows: [ShowSnapshot],
                                       featured: ShowSnapshot?, performerName: String,
                                       options: ExportOptions, accent: UIColor,
                                       textColor: UIColor, subColor: UIColor) {
        let pad      = size.width * 0.05
        var contentW = size.width - pad * 2

        if let data = featured?.flyerImageData, let flyer = UIImage(data: data) {
            let tw = size.width * 0.27
            let th = size.height * 0.70
            let tx = size.width - pad - tw
            let ty = (size.height - th) / 2
            let tRect = CGRect(x: tx, y: ty, width: tw, height: th)
            ctx.saveGState()
            ctx.addPath(UIBezierPath(roundedRect: tRect, cornerRadius: 14).cgPath)
            ctx.clip()
            drawImage(flyer, in: tRect)
            ctx.restoreGState()
            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.2).cgColor)
            ctx.setLineWidth(2)
            UIBezierPath(roundedRect: tRect, cornerRadius: 14).stroke()
            contentW = tx - pad * 1.5
        }

        var curY = size.height * 0.13
        if options.showBadge {
            let bFont = UIFont.systemFont(ofSize: size.width * 0.022, weight: .bold)
            drawText("SEE ME LIVE", at: CGPoint(x: pad, y: curY),
                     font: bFont, color: accent, maxWidth: contentW, canvasHeight: size.height)
            curY += bFont.lineHeight * 1.3
        }
        let nameFont = UIFont.systemFont(ofSize: size.width * 0.062, weight: .heavy)
        drawText(performerName.isEmpty ? "Upcoming Shows" : performerName,
                 at: CGPoint(x: pad, y: curY),
                 font: nameFont, color: textColor, maxWidth: contentW, canvasHeight: size.height)
        curY += nameFont.lineHeight * 1.5

        drawShowRows(ctx: ctx, size: size, allShows: allShows, options: options,
                     startY: curY, pad: pad, textColor: textColor, subColor: subColor,
                     titleSz: size.width * 0.028, subSz: size.width * 0.020,
                     rowH: size.height * 0.135, maxX: pad + contentW)
    }

    // MARK: - Shared row drawing

    private static func drawShowRows(ctx: CGContext, size: CGSize, allShows: [ShowSnapshot],
                                     options: ExportOptions, startY: CGFloat, pad: CGFloat,
                                     textColor: UIColor, subColor: UIColor,
                                     titleSz: CGFloat, subSz: CGFloat, rowH: CGFloat,
                                     maxX: CGFloat? = nil) {
        let lineEnd = maxX ?? (size.width - pad)
        let detailSz = subSz * 0.9
        // Each row needs more height to fit additional detail lines
        let expandedRowH = rowH * 1.6

        if allShows.isEmpty {
            drawText("No shows yet", at: CGPoint(x: pad, y: startY),
                     font: .systemFont(ofSize: subSz, weight: .regular),
                     color: subColor, maxWidth: lineEnd - pad, canvasHeight: size.height)
            return
        }

        var y = startY
        // Draw EVERY show — no count limit, no clipping
        for show in allShows {
            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.15).cgColor)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: pad, y: y))
            ctx.addLine(to: CGPoint(x: lineEnd, y: y))
            ctx.strokePath()

            var ly = y + expandedRowH * 0.08

            // Row 1: Title (+ role if present)
            let titleStr: String
            if !show.roleOrEmpty.isEmpty {
                titleStr = "\(show.titleOrEmpty)  ·  \(show.roleOrEmpty)"
            } else {
                titleStr = show.titleOrEmpty
            }
            drawText(titleStr,
                     at: CGPoint(x: pad, y: ly),
                     font: .systemFont(ofSize: titleSz, weight: .bold),
                     color: textColor, maxWidth: lineEnd - pad, canvasHeight: size.height)
            ly += titleSz * 1.45

            // Row 2: Date & Venue
            var parts: [String] = []
            if options.showDate  { parts.append(show.dateFormatted) }
            if options.showVenue, !show.venueOrEmpty.isEmpty { parts.append(show.venueOrEmpty) }
            if !parts.isEmpty {
                drawText(parts.joined(separator: "  ·  "),
                         at: CGPoint(x: pad, y: ly),
                         font: .systemFont(ofSize: subSz, weight: .regular),
                         color: subColor, maxWidth: lineEnd - pad, canvasHeight: size.height)
                ly += subSz * 1.45
            }

            // Row 3: Price & Ticket Link
            var extraParts: [String] = []
            if show.price > 0 {
                extraParts.append(show.priceFormatted)
            } else {
                extraParts.append("Free")
            }
            if show.hasTicketLink {
                extraParts.append("🎟 Tickets Available")
            }
            if !extraParts.isEmpty {
                drawText(extraParts.joined(separator: "  ·  "),
                         at: CGPoint(x: pad, y: ly),
                         font: .systemFont(ofSize: detailSz, weight: .medium),
                         color: subColor.withAlphaComponent(0.85),
                         maxWidth: lineEnd - pad, canvasHeight: size.height)
                ly += detailSz * 1.45
            }

            // Row 4: Notes (truncated)
            if !show.notesOrEmpty.isEmpty {
                let truncatedNotes: String
                if show.notesOrEmpty.count > 60 {
                    truncatedNotes = String(show.notesOrEmpty.prefix(57)) + "..."
                } else {
                    truncatedNotes = show.notesOrEmpty
                }
                drawText(truncatedNotes,
                         at: CGPoint(x: pad, y: ly),
                         font: .italicSystemFont(ofSize: detailSz),
                         color: subColor.withAlphaComponent(0.7),
                         maxWidth: lineEnd - pad, canvasHeight: size.height)
            }

            y += expandedRowH
        }
    }

    // MARK: - Background

    private static func drawBackground(ctx: CGContext, rect: CGRect,
                                       featured: ShowSnapshot?, style: BackgroundStyle,
                                       customBG: CustomBackground? = nil) {
        switch style {
        case .custom:
            if let bg = customBG {
                switch bg.kind {
                case .solidColor:
                    ctx.setFillColor(UIColor(hex: bg.solidHex).cgColor)
                    ctx.fill(rect)
                case .gradient:
                    let space = CGColorSpaceCreateDeviceRGB()
                    let cgc = [UIColor(hex: bg.gradientFromHex).cgColor,
                               UIColor(hex: bg.gradientToHex).cgColor] as CFArray
                    if let grad = CGGradient(colorsSpace: space, colors: cgc, locations: [0, 1]) {
                        ctx.drawLinearGradient(grad, start: .zero,
                                               end: CGPoint(x: 0, y: rect.height), options: [])
                    }
                case .photo:
                    if let data = bg.photoData, let img = UIImage(data: data) {
                        UIGraphicsPushContext(ctx); img.draw(in: rect); UIGraphicsPopContext()
                    } else {
                        ctx.setFillColor(UIColor(hex: "#111111").cgColor); ctx.fill(rect)
                    }
                }
            } else {
                ctx.setFillColor(UIColor(hex: "#111111").cgColor); ctx.fill(rect)
            }
        case .flyer:
            if let data = featured?.flyerImageData, let img = UIImage(data: data) {
                UIGraphicsPushContext(ctx); img.draw(in: rect); UIGraphicsPopContext(); return
            }
            fallthrough
        case .gradient:
            let space = CGColorSpaceCreateDeviceRGB()
            let cgc = [UIColor(hex: "#1A0A00").cgColor, UIColor(hex: "#3D1C00").cgColor] as CFArray
            if let grad = CGGradient(colorsSpace: space, colors: cgc, locations: [0, 1]) {
                ctx.drawLinearGradient(grad, start: .zero,
                                       end: CGPoint(x: 0, y: rect.height), options: [])
            }
        case .dark:
            ctx.setFillColor(UIColor(hex: "#111111").cgColor); ctx.fill(rect)
        case .light:
            ctx.setFillColor(UIColor(hex: "#F5F5F0").cgColor); ctx.fill(rect)
        }
    }

    // MARK: - Text Overlays

    private static func drawTextOverlays(_ overlays: [TextOverlay], in size: CGSize, ctx: CGContext) {
        for overlay in overlays {
            let resolvedSize = overlay.fontSize * size.width
            let font: UIFont
            if overlay.fontName == "System" {
                font = UIFont.systemFont(ofSize: resolvedSize, weight: uiFontWeight(overlay.fontWeight))
            } else {
                font = UIFont(name: overlay.fontName, size: resolvedSize)
                    ?? UIFont.systemFont(ofSize: resolvedSize, weight: uiFontWeight(overlay.fontWeight))
            }
            let color = UIColor(hex: overlay.colorHex)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color
            ]
            let text = overlay.text as NSString
            let textSize = text.size(withAttributes: attrs)

            let cx = overlay.positionX * size.width
            let cy = overlay.positionY * size.height

            ctx.saveGState()
            ctx.translateBy(x: cx, y: cy)
            if overlay.rotation != 0 {
                ctx.rotate(by: overlay.rotation * .pi / 180)
            }

            let drawRect = CGRect(x: -textSize.width / 2, y: -textSize.height / 2,
                                  width: textSize.width, height: textSize.height)
            UIGraphicsPushContext(ctx)
            text.draw(in: drawRect, withAttributes: attrs)
            UIGraphicsPopContext()

            ctx.restoreGState()
        }
    }

    private static func uiFontWeight(_ name: String) -> UIFont.Weight {
        switch name.lowercased() {
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
    }

    // MARK: - Primitives

    private static func drawImage(_ image: UIImage, in rect: CGRect) {
        let a = image.size.width / image.size.height
        let b = rect.width / rect.height
        var r = rect
        if a > b { let h = rect.width / a;  r = CGRect(x: rect.minX, y: rect.midY-h/2, width: rect.width,  height: h) }
        else      { let w = rect.height * a; r = CGRect(x: rect.midX-w/2, y: rect.minY, width: w, height: rect.height) }
        image.draw(in: r)
    }

    private static func drawText(_ text: String, at origin: CGPoint, font: UIFont,
                                  color: UIColor, maxWidth: CGFloat, canvasHeight: CGFloat,
                                  lineSpacing: CGFloat = 0) {
        let ps = NSMutableParagraphStyle()
        ps.lineSpacing = lineSpacing; ps.lineBreakMode = .byWordWrapping
        NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: ps])
            .draw(in: CGRect(x: origin.x, y: origin.y, width: maxWidth, height: canvasHeight - origin.y))
    }
}

// MARK: - UIColor hex init

private extension UIColor {
    convenience init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(red:   CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8)  & 0xFF) / 255,
                  blue:  CGFloat( rgb        & 0xFF) / 255,
                  alpha: 1)
    }
}
