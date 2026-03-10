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
    var fontName: String = "System"
    var fontSize: CGFloat = 0.08
    var fontWeight: String = "bold"
    var colorHex: String = "#FFFFFF"
    var positionX: CGFloat = 0.5
    var positionY: CGFloat = 0.10
    var rotation: Double = 0
}

// MARK: - Card Style

enum CardStyle: String, CaseIterable, Identifiable {
    case rounded  = "Rounded"
    case sharp    = "Sharp"
    case minimal  = "Minimal"
    case outlined = "Outlined"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .rounded:  return "rectangle.roundedtop"
        case .sharp:    return "rectangle"
        case .minimal:  return "rectangle.dashed"
        case .outlined: return "rectangle.inset.filled"
        }
    }
}

// MARK: - Header Style

enum HeaderStyle: String, CaseIterable, Identifiable {
    case left     = "Left"
    case centered = "Centered"
    case minimal  = "Minimal"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .left:     return "text.alignleft"
        case .centered: return "text.aligncenter"
        case .minimal:  return "minus"
        }
    }
}

// MARK: - Font Style

enum FontStyle: String, CaseIterable, Identifiable {
    case system  = "Default"
    case rounded = "Rounded"
    case serif   = "Serif"
    case mono    = "Mono"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .system:  return "textformat"
        case .rounded: return "textformat.abc"
        case .serif:   return "textformat.alt"
        case .mono:    return "chevron.left.forwardslash.chevron.right"
        }
    }
}

// MARK: - Date Format Style

enum DateFormatStyle: String, CaseIterable, Identifiable {
    case short    = "Short"      // Mar 15 · 8 PM
    case full     = "Full"       // Saturday, March 15
    case relative = "Relative"   // In 3 days
    case timeOnly = "Time Only"  // 8:00 PM
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .short:    return "calendar"
        case .full:     return "calendar.day.timeline.left"
        case .relative: return "clock.arrow.circlepath"
        case .timeOnly: return "clock"
        }
    }
}

// MARK: - Export Options

struct ExportOptions {
    var sizePreset:      SocialSizePreset = .instagramPost
    var backgroundStyle: BackgroundStyle  = .gradient
    var accentHex:       String           = "#CC7057"
    var showVenue:       Bool             = true
    var showDate:        Bool             = true
    var showBadge:       Bool             = true
    var showBottomBar:   Bool             = true
    var showPrice:       Bool             = true
    var showNotes:       Bool             = false
    var showTickets:     Bool             = true

    var cardStyle:       CardStyle        = .rounded
    var columns:         Int              = 0        // 0 = auto
    var cardOpacity:     Double           = 1.0      // 0…1
    var headerStyle:     HeaderStyle      = .left
    var fontStyle:       FontStyle        = .system

    // Customizable text
    var subtitleText:    String           = "Upcoming Schedule"
    var badgeText:       String           = "SEE ME LIVE"

    // Date formatting
    var dateFormatStyle: DateFormatStyle  = .short

    // Scrim (background overlay darkness)
    var scrimIntensity:  Double           = 0.55     // 0…1

    // Grid gap multiplier
    var gridGap:         Double           = 1.0      // 0.5…2.0

    var customBackground: CustomBackground = CustomBackground()
    var textOverlays: [TextOverlay] = []
}

// MARK: - Show Snapshot (thread-safe)

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

    var monthAbbrev: String {
        let f = DateFormatter(); f.dateFormat = "MMM"; return f.string(from: date).uppercased()
    }

    var dayNumber: String {
        let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: date)
    }

    var timeString: String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: date)
    }

    func formattedDate(style: DateFormatStyle) -> String {
        switch style {
        case .short:
            let df = DateFormatter(); df.dateFormat = "MMM d"
            let tf = DateFormatter(); tf.dateFormat = "h:mm a"
            return "\(df.string(from: date)) · \(tf.string(from: date))"
        case .full:
            let df = DateFormatter(); df.dateFormat = "EEEE, MMMM d"
            return df.string(from: date)
        case .relative:
            let cal = Calendar.current
            let now = Date()
            if cal.isDateInToday(date) { return "Today" }
            if cal.isDateInTomorrow(date) { return "Tomorrow" }
            let days = cal.dateComponents([.day], from: now, to: date).day ?? 0
            if days > 0 { return "In \(days) day\(days == 1 ? "" : "s")" }
            if days < 0 { return "\(abs(days)) day\(abs(days) == 1 ? "" : "s") ago" }
            return "Today"
        case .timeOnly:
            let tf = DateFormatter(); tf.dateFormat = "h:mm a"
            return tf.string(from: date)
        }
    }

    var hasTicketLink: Bool {
        guard !ticketLink.isEmpty else { return false }
        let trimmed = ticketLink.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed) != nil
        }
        return URL(string: "https://" + trimmed) != nil
    }

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
    static func generate(shows: [Show], performerName: String, options: ExportOptions) -> UIImage {
        let snapshots = shows.map { ShowSnapshot(from: $0) }
        return generate(snapshots: snapshots, performerName: performerName, options: options)
    }

    /// Generate from thread-safe ShowSnapshot values. Safe to call from any thread.
    static func generate(snapshots: [ShowSnapshot], performerName: String, options: ExportOptions) -> UIImage {
        let size = options.sizePreset.size
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            drawCanvas(in: ctx.cgContext, size: size, snapshots: snapshots,
                       performerName: performerName, options: options)
        }
    }

    // Legacy shim
    static func generate(shows: [Show], performerName: String, layout: ImageLayout = .list) -> UIImage {
        return generate(shows: shows, performerName: performerName, options: ExportOptions())
    }

    // MARK: - Font Resolver

    private static func resolvedFont(size: CGFloat, weight: UIFont.Weight, style: FontStyle) -> UIFont {
        switch style {
        case .system:
            return UIFont.systemFont(ofSize: size, weight: weight)
        case .rounded:
            let desc = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
                .withDesign(.rounded) ?? UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
            return UIFont(descriptor: desc, size: size)
        case .serif:
            let desc = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
                .withDesign(.serif) ?? UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
            return UIFont(descriptor: desc, size: size)
        case .mono:
            let desc = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
                .withDesign(.monospaced) ?? UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
            return UIFont(descriptor: desc, size: size)
        }
    }

    // MARK: - Main Canvas

    private static func drawCanvas(in ctx: CGContext, size: CGSize, snapshots: [ShowSnapshot],
                                    performerName: String, options: ExportOptions) {
        let rect = CGRect(origin: .zero, size: size)
        let allShows = snapshots.sorted { $0.dateOrNow < $1.dateOrNow }
        let featured = allShows.first
        let accent = UIColor(hex: options.accentHex)
        let isLight = options.backgroundStyle == .light

        // 1. Background
        drawBackground(ctx: ctx, rect: rect, featured: featured,
                       style: options.backgroundStyle, customBG: options.customBackground)

        // 2. Scrim overlay for readability
        let scrimAlpha: CGFloat = isLight ? options.scrimIntensity * 0.1 : options.scrimIntensity
        ctx.setFillColor(UIColor.black.withAlphaComponent(scrimAlpha).cgColor)
        ctx.fill(rect)

        // 3. Colors
        let textColor: UIColor = isLight ? UIColor(hex: "#1A1A1A") : .white
        let subColor: UIColor = isLight ? UIColor(hex: "#666666") : UIColor.white.withAlphaComponent(0.65)

        // Card background with user opacity
        let baseCardAlpha: CGFloat = isLight ? 0.85 : 0.08
        let cardBG: UIColor
        let cardBorder: UIColor
        switch options.cardStyle {
        case .rounded, .sharp:
            cardBG = isLight
                ? UIColor.white.withAlphaComponent(baseCardAlpha * options.cardOpacity)
                : UIColor.white.withAlphaComponent(baseCardAlpha * options.cardOpacity)
            cardBorder = isLight
                ? UIColor.black.withAlphaComponent(0.06 * options.cardOpacity)
                : UIColor.white.withAlphaComponent(0.12 * options.cardOpacity)
        case .minimal:
            cardBG = UIColor.clear
            cardBorder = UIColor.clear
        case .outlined:
            cardBG = UIColor.clear
            cardBorder = isLight
                ? UIColor.black.withAlphaComponent(0.15)
                : UIColor.white.withAlphaComponent(0.25)
        }

        // 4. Layout metrics
        let pad = size.width * 0.05
        let headerH: CGFloat = options.headerStyle == .minimal ? size.width * 0.10 : size.width * 0.18
        let bottomH: CGFloat = options.showBottomBar ? size.width * 0.055 : 0
        let gridTop = pad + headerH
        let gridBottom = size.height - bottomH - pad * 0.5
        let gridH = gridBottom - gridTop
        let gridW = size.width - pad * 2

        // 5. Header
        drawHeader(ctx: ctx, size: size, pad: pad, performerName: performerName,
                   options: options, accent: accent, textColor: textColor, subColor: subColor)

        // 6. Card grid — user-defined or auto columns
        let cols: Int
        if options.columns > 0 {
            cols = options.columns
        } else {
            cols = options.sizePreset.isVertical ? 2 : 3
        }
        drawCardGrid(ctx: ctx, allShows: allShows, options: options,
                     gridOrigin: CGPoint(x: pad, y: gridTop),
                     gridSize: CGSize(width: gridW, height: gridH),
                     cols: cols, accent: accent, textColor: textColor,
                     subColor: subColor, cardBG: cardBG, cardBorder: cardBorder, isLight: isLight)

        // 7. Bottom bar
        if options.showBottomBar {
            drawBottomBar(ctx: ctx, size: size, barH: bottomH, accent: accent,
                          badgeText: options.badgeText)
        }

        // 8. Custom text overlays
        if !options.textOverlays.isEmpty {
            drawTextOverlays(options.textOverlays, in: size, ctx: ctx)
        }
    }

    // MARK: - Header

    private static func drawHeader(ctx: CGContext, size: CGSize, pad: CGFloat,
                                    performerName: String, options: ExportOptions,
                                    accent: UIColor, textColor: UIColor, subColor: UIColor) {
        let topY = pad
        let name = performerName.isEmpty ? "My Shows" : performerName
        let fontSt = options.fontStyle

        switch options.headerStyle {
        case .left:
            // Performer name — large, left-aligned
            let nameSz = size.width * 0.065
            let nameFont = resolvedFont(size: nameSz, weight: .bold, style: fontSt)
            drawText(name, at: CGPoint(x: pad, y: topY), font: nameFont,
                     color: textColor, maxWidth: size.width * 0.6, canvasHeight: size.height)

            // "SEE ME LIVE" pill badge — top right
            if options.showBadge {
                drawBadgePill(ctx: ctx, size: size, pad: pad, topY: topY + nameSz * 0.15,
                              accent: accent, fontSt: fontSt, text: options.badgeText)
            }

            // Subtitle line
            let subY = topY + nameSz * 1.35
            let subSz = size.width * 0.026
            let subFont = resolvedFont(size: subSz, weight: .medium, style: fontSt)
            if !options.subtitleText.isEmpty {
                drawText(options.subtitleText, at: CGPoint(x: pad, y: subY), font: subFont,
                         color: subColor, maxWidth: size.width * 0.5, canvasHeight: size.height)
            }

            // Thin divider line
            let divY = subY + subSz * 2
            ctx.setStrokeColor(textColor.withAlphaComponent(0.1).cgColor)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: pad, y: divY))
            ctx.addLine(to: CGPoint(x: size.width - pad, y: divY))
            ctx.strokePath()

        case .centered:
            // Badge above name, centered
            var curY = topY
            if options.showBadge {
                let badgeSz = size.width * 0.02
                let badgeFont = resolvedFont(size: badgeSz, weight: .heavy, style: fontSt)
                let badgeText = options.badgeText as NSString
                let badgeAttrs: [NSAttributedString.Key: Any] = [.font: badgeFont, .foregroundColor: accent]
                let badgeTextSize = badgeText.size(withAttributes: badgeAttrs)
                let bx = (size.width - badgeTextSize.width) / 2
                UIGraphicsPushContext(ctx)
                badgeText.draw(at: CGPoint(x: bx, y: curY), withAttributes: badgeAttrs)
                UIGraphicsPopContext()
                curY += badgeTextSize.height + size.width * 0.015
            }

            let nameSz = size.width * 0.07
            let nameFont = resolvedFont(size: nameSz, weight: .bold, style: fontSt)
            let nameAttrs: [NSAttributedString.Key: Any] = [.font: nameFont, .foregroundColor: textColor]
            let nameSize = (name as NSString).size(withAttributes: nameAttrs)
            let nx = (size.width - nameSize.width) / 2
            UIGraphicsPushContext(ctx)
            (name as NSString).draw(at: CGPoint(x: nx, y: curY), withAttributes: nameAttrs)
            UIGraphicsPopContext()
            curY += nameSize.height + size.width * 0.01

            let subSz = size.width * 0.024
            let subFont = resolvedFont(size: subSz, weight: .medium, style: fontSt)
            let subAttrs: [NSAttributedString.Key: Any] = [.font: subFont, .foregroundColor: subColor]
            let subText = options.subtitleText as NSString
            let subSize = subText.size(withAttributes: subAttrs)
            let sx = (size.width - subSize.width) / 2
            UIGraphicsPushContext(ctx)
            subText.draw(at: CGPoint(x: sx, y: curY), withAttributes: subAttrs)
            UIGraphicsPopContext()

            // Centered short divider
            let divY = curY + subSize.height + size.width * 0.015
            let divW = size.width * 0.15
            ctx.setStrokeColor(accent.withAlphaComponent(0.4).cgColor)
            ctx.setLineWidth(2)
            ctx.move(to: CGPoint(x: (size.width - divW) / 2, y: divY))
            ctx.addLine(to: CGPoint(x: (size.width + divW) / 2, y: divY))
            ctx.strokePath()

        case .minimal:
            // Just the performer name, small, left-aligned
            let nameSz = size.width * 0.04
            let nameFont = resolvedFont(size: nameSz, weight: .semibold, style: fontSt)
            drawText(name, at: CGPoint(x: pad, y: topY), font: nameFont,
                     color: textColor, maxWidth: size.width * 0.5, canvasHeight: size.height)

            if options.showBadge {
                drawBadgePill(ctx: ctx, size: size, pad: pad, topY: topY,
                              accent: accent, fontSt: fontSt, text: options.badgeText)
            }
        }
    }

    /// Draws a pill badge at top-right
    private static func drawBadgePill(ctx: CGContext, size: CGSize, pad: CGFloat,
                                       topY: CGFloat, accent: UIColor, fontSt: FontStyle,
                                       text: String = "SEE ME LIVE") {
        let badgeSz = size.width * 0.02
        let badgeFont = resolvedFont(size: badgeSz, weight: .heavy, style: fontSt)
        let badgeText = text as NSString
        let badgeAttrs: [NSAttributedString.Key: Any] = [.font: badgeFont, .foregroundColor: UIColor.white]
        let badgeTextSize = badgeText.size(withAttributes: badgeAttrs)
        let pillW = badgeTextSize.width + badgeSz * 3
        let pillH = badgeTextSize.height + badgeSz * 1.5
        let pillX = size.width - pad - pillW
        let pillY = topY

        let pillRect = CGRect(x: pillX, y: pillY, width: pillW, height: pillH)
        let pillPath = UIBezierPath(roundedRect: pillRect, cornerRadius: pillH / 2)
        ctx.saveGState()
        ctx.setFillColor(accent.cgColor)
        ctx.addPath(pillPath.cgPath)
        ctx.fillPath()
        ctx.restoreGState()

        UIGraphicsPushContext(ctx)
        badgeText.draw(at: CGPoint(x: pillX + badgeSz * 1.5, y: pillY + badgeSz * 0.75),
                       withAttributes: badgeAttrs)
        UIGraphicsPopContext()
    }

    // MARK: - Card Grid

    private static func drawCardGrid(ctx: CGContext, allShows: [ShowSnapshot],
                                      options: ExportOptions,
                                      gridOrigin: CGPoint, gridSize: CGSize,
                                      cols: Int, accent: UIColor, textColor: UIColor,
                                      subColor: UIColor, cardBG: UIColor,
                                      cardBorder: UIColor, isLight: Bool) {

        guard !allShows.isEmpty else {
            let emptyFont = UIFont.systemFont(ofSize: gridSize.width * 0.04, weight: .medium)
            drawText("No shows scheduled yet",
                     at: CGPoint(x: gridOrigin.x, y: gridOrigin.y + gridSize.height * 0.4),
                     font: emptyFont, color: subColor,
                     maxWidth: gridSize.width, canvasHeight: gridOrigin.y + gridSize.height)
            return
        }

        let count = allShows.count
        let gap = gridSize.width * 0.025 * options.gridGap
        let rows = Int(ceil(Double(count) / Double(cols)))

        let cardW = (gridSize.width - gap * CGFloat(cols - 1)) / CGFloat(cols)
        let cardH = (gridSize.height - gap * CGFloat(rows - 1)) / CGFloat(rows)
        let cornerR: CGFloat
        switch options.cardStyle {
        case .rounded:  cornerR = cardW * 0.06
        case .sharp:    cornerR = 0
        case .minimal:  cornerR = 0
        case .outlined: cornerR = cardW * 0.04
        }

        let fontSt = options.fontStyle

        // Scale fonts relative to card size
        let scale = min(cardW / 300, cardH / 200)
        let titleSz  = max(12, 18 * scale)
        let venueSz  = max(9, 13 * scale)
        let timeSz   = max(8, 12 * scale)
        let priceSz  = max(8, 11 * scale)
        let notesSz  = max(7, 10 * scale)
        let dateBadgeSz  = max(8, 11 * scale)
        let dateDaySz    = max(14, 24 * scale)
        let dateBadgeR   = max(16, 28 * scale)

        for (i, show) in allShows.enumerated() {
            let col = i % cols
            let row = i / cols

            let cx = gridOrigin.x + CGFloat(col) * (cardW + gap)
            let cy = gridOrigin.y + CGFloat(row) * (cardH + gap)
            let cardRect = CGRect(x: cx, y: cy, width: cardW, height: cardH)
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cornerR)

            // Card background
            if cardBG != UIColor.clear {
                ctx.saveGState()
                ctx.setFillColor(cardBG.cgColor)
                ctx.addPath(cardPath.cgPath)
                ctx.fillPath()
                ctx.restoreGState()
            }

            // Card border
            if cardBorder != UIColor.clear {
                ctx.saveGState()
                ctx.setStrokeColor(cardBorder.cgColor)
                ctx.setLineWidth(options.cardStyle == .outlined ? 1.5 : 1)
                ctx.addPath(cardPath.cgPath)
                ctx.strokePath()
                ctx.restoreGState()
            }

            let inset = cardW * 0.08
            let contentX = cx + inset
            let contentW = cardW - inset * 2
            var curY = cy + inset

            // Date badge circle
            let badgeCenterX = contentX + dateBadgeR
            let badgeCenterY = curY + dateBadgeR
            let badgeCircle = CGRect(x: badgeCenterX - dateBadgeR,
                                     y: badgeCenterY - dateBadgeR,
                                     width: dateBadgeR * 2, height: dateBadgeR * 2)
            ctx.saveGState()
            ctx.setFillColor(accent.withAlphaComponent(0.15).cgColor)
            ctx.fillEllipse(in: badgeCircle)
            ctx.restoreGState()

            // Month text in badge
            let monthFont = resolvedFont(size: dateBadgeSz, weight: .heavy, style: fontSt)
            let monthAttrs: [NSAttributedString.Key: Any] = [.font: monthFont, .foregroundColor: accent]
            let monthStr = show.monthAbbrev as NSString
            let monthSize = monthStr.size(withAttributes: monthAttrs)
            UIGraphicsPushContext(ctx)
            monthStr.draw(at: CGPoint(x: badgeCenterX - monthSize.width / 2,
                                       y: badgeCenterY - dateBadgeR * 0.55),
                          withAttributes: monthAttrs)
            UIGraphicsPopContext()

            // Day number in badge
            let dayFont = resolvedFont(size: dateDaySz, weight: .bold, style: fontSt)
            let dayAttrs: [NSAttributedString.Key: Any] = [.font: dayFont, .foregroundColor: textColor]
            let dayStr = show.dayNumber as NSString
            let daySize = dayStr.size(withAttributes: dayAttrs)
            UIGraphicsPushContext(ctx)
            dayStr.draw(at: CGPoint(x: badgeCenterX - daySize.width / 2,
                                     y: badgeCenterY - dateBadgeR * 0.05),
                        withAttributes: dayAttrs)
            UIGraphicsPopContext()

            // Title — to the right of the badge
            let titleX = badgeCenterX + dateBadgeR + inset * 0.6
            let titleW = contentW - (dateBadgeR * 2 + inset * 0.6)
            let titleFont = resolvedFont(size: titleSz, weight: .semibold, style: fontSt)

            drawText(show.titleOrEmpty, at: CGPoint(x: titleX, y: curY + dateBadgeR * 0.15),
                     font: titleFont, color: textColor,
                     maxWidth: max(1, titleW), canvasHeight: curY + dateBadgeR * 2)

            // Role (smaller, below title if room)
            if !show.roleOrEmpty.isEmpty {
                let roleFont = resolvedFont(size: venueSz, weight: .medium, style: fontSt)
                drawText(show.roleOrEmpty,
                         at: CGPoint(x: titleX, y: curY + dateBadgeR * 0.15 + titleSz * 1.3),
                         font: roleFont, color: accent,
                         maxWidth: max(1, titleW), canvasHeight: curY + dateBadgeR * 2)
            }

            curY += dateBadgeR * 2 + inset * 0.4

            // Divider inside card (skip for minimal style)
            if options.cardStyle != .minimal {
                ctx.setStrokeColor(textColor.withAlphaComponent(0.08).cgColor)
                ctx.setLineWidth(0.5)
                ctx.move(to: CGPoint(x: contentX, y: curY))
                ctx.addLine(to: CGPoint(x: contentX + contentW, y: curY))
                ctx.strokePath()
            }
            curY += inset * 0.4

            // Venue
            if options.showVenue && !show.venueOrEmpty.isEmpty {
                let venueFont = resolvedFont(size: venueSz, weight: .medium, style: fontSt)
                drawText("📍 " + show.venueOrEmpty,
                         at: CGPoint(x: contentX, y: curY),
                         font: venueFont, color: subColor,
                         maxWidth: contentW, canvasHeight: cardRect.maxY - inset)
                curY += venueSz * 1.6
            }

            // Time / Date
            if options.showDate {
                let timeFont = resolvedFont(size: timeSz, weight: .regular, style: fontSt)
                drawText("🕐 " + show.formattedDate(style: options.dateFormatStyle),
                         at: CGPoint(x: contentX, y: curY),
                         font: timeFont, color: subColor,
                         maxWidth: contentW, canvasHeight: cardRect.maxY - inset)
                curY += timeSz * 1.6
            }

            // Notes (truncated)
            if options.showNotes && !show.notesOrEmpty.isEmpty {
                let notesFont = UIFont.italicSystemFont(ofSize: notesSz)
                let truncated = show.notesOrEmpty.count > 50
                    ? String(show.notesOrEmpty.prefix(47)) + "..."
                    : show.notesOrEmpty
                drawText(truncated,
                         at: CGPoint(x: contentX, y: curY),
                         font: notesFont, color: subColor.withAlphaComponent(0.7),
                         maxWidth: contentW, canvasHeight: cardRect.maxY - inset)
                curY += notesSz * 1.6
            }

            // Price tag — bottom of card
            let priceY = cardRect.maxY - inset - priceSz * 1.8
            if options.showPrice && priceY > curY {
                let priceFont = resolvedFont(size: priceSz, weight: .semibold, style: fontSt)
                let priceStr = show.price > 0 ? show.priceFormatted : "FREE"
                let priceAttrs: [NSAttributedString.Key: Any] = [
                    .font: priceFont,
                    .foregroundColor: accent
                ]
                let priceTextSize = (priceStr as NSString).size(withAttributes: priceAttrs)

                // Price pill
                let pillPad: CGFloat = priceSz * 0.5
                let pricePillRect = CGRect(x: contentX,
                                           y: priceY,
                                           width: priceTextSize.width + pillPad * 2,
                                           height: priceTextSize.height + pillPad)
                let pricePillPath = UIBezierPath(roundedRect: pricePillRect,
                                                  cornerRadius: pricePillRect.height / 2)
                ctx.saveGState()
                ctx.setFillColor(accent.withAlphaComponent(0.12).cgColor)
                ctx.addPath(pricePillPath.cgPath)
                ctx.fillPath()
                ctx.restoreGState()

                UIGraphicsPushContext(ctx)
                (priceStr as NSString).draw(at: CGPoint(x: contentX + pillPad,
                                                         y: priceY + pillPad * 0.5),
                                            withAttributes: priceAttrs)
                UIGraphicsPopContext()

                // Ticket indicator
                if options.showTickets && show.hasTicketLink {
                    let ticketFont = resolvedFont(size: priceSz * 0.85, weight: .medium, style: fontSt)
                    let ticketX = contentX + pricePillRect.width + pillPad
                    drawText("🎟", at: CGPoint(x: ticketX, y: priceY + pillPad * 0.3),
                             font: ticketFont, color: subColor,
                             maxWidth: contentW - pricePillRect.width - pillPad,
                             canvasHeight: cardRect.maxY)
                }
            }
        }
    }

    // MARK: - Bottom Bar

    private static func drawBottomBar(ctx: CGContext, size: CGSize, barH: CGFloat,
                                      accent: UIColor, badgeText: String = "SEE ME LIVE") {
        let barRect = CGRect(x: 0, y: size.height - barH, width: size.width, height: barH)
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.4).cgColor)
        ctx.fill(barRect)

        let fontSize = size.width * 0.02
        let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        let text = "\(badgeText)  ·  seemelive.app"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: accent.withAlphaComponent(0.9)
        ]
        let textSize = (text as NSString).size(withAttributes: attrs)
        let tx = (size.width - textSize.width) / 2
        let ty = size.height - barH + (barH - textSize.height) / 2
        UIGraphicsPushContext(ctx)
        (text as NSString).draw(at: CGPoint(x: tx, y: ty), withAttributes: attrs)
        UIGraphicsPopContext()
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
                        drawImageFill(img, in: rect, ctx: ctx)
                    } else {
                        ctx.setFillColor(UIColor(hex: "#111111").cgColor); ctx.fill(rect)
                    }
                }
            } else {
                ctx.setFillColor(UIColor(hex: "#111111").cgColor); ctx.fill(rect)
            }
        case .flyer:
            if let data = featured?.flyerImageData, let img = UIImage(data: data) {
                drawImageFill(img, in: rect, ctx: ctx); return
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
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
            let text = overlay.text as NSString
            let textSize = text.size(withAttributes: attrs)
            let cx = overlay.positionX * size.width
            let cy = overlay.positionY * size.height

            ctx.saveGState()
            ctx.translateBy(x: cx, y: cy)
            if overlay.rotation != 0 { ctx.rotate(by: overlay.rotation * .pi / 180) }

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

    /// Draw image filling the rect (aspect-fill, centered crop).
    private static func drawImageFill(_ image: UIImage, in rect: CGRect, ctx: CGContext) {
        let imgAspect = image.size.width / image.size.height
        let rectAspect = rect.width / rect.height
        var drawRect = rect
        if imgAspect > rectAspect {
            let w = rect.height * imgAspect
            drawRect = CGRect(x: rect.midX - w / 2, y: rect.minY, width: w, height: rect.height)
        } else {
            let h = rect.width / imgAspect
            drawRect = CGRect(x: rect.minX, y: rect.midY - h / 2, width: rect.width, height: h)
        }
        ctx.saveGState()
        ctx.clip(to: rect)
        UIGraphicsPushContext(ctx)
        image.draw(in: drawRect)
        UIGraphicsPopContext()
        ctx.restoreGState()
    }

    private static func drawText(_ text: String, at origin: CGPoint, font: UIFont,
                                  color: UIColor, maxWidth: CGFloat, canvasHeight: CGFloat,
                                  lineSpacing: CGFloat = 0) {
        let ps = NSMutableParagraphStyle()
        ps.lineSpacing = lineSpacing; ps.lineBreakMode = .byTruncatingTail
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
