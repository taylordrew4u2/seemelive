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
    case custom   = "Custom"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .gradient: return "paintpalette.fill"
        case .dark:     return "moon.fill"
        case .light:    return "sun.max.fill"
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

// MARK: - Layout Template

enum LayoutTemplate: String, CaseIterable, Identifiable {
    case classic    = "Classic"      // Date badge left, text right
    case minimal    = "Minimal"      // Simple text list, no badges
    case bold       = "Bold"         // Large date on top, text below
    case compact    = "Compact"      // Small cards, more shows visible
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .classic: return "rectangle.split.2x1"
        case .minimal: return "list.bullet"
        case .bold:    return "calendar"
        case .compact: return "square.grid.3x3"
        }
    }
    
    var description: String {
        switch self {
        case .classic: return "Date badge with show details"
        case .minimal: return "Clean text-only layout"
        case .bold:    return "Large prominent dates"
        case .compact: return "Fit more shows"
        }
    }
}

// MARK: - Export Options

struct ExportOptions {
    var sizePreset:      SocialSizePreset = .instagramPost
    var backgroundStyle: BackgroundStyle  = .gradient
    var accentHex:       String           = "#CC7057"
    var textColorHex:    String?          = nil       // nil = auto (white/dark based on background)
    
    // Content toggles
    var showVenue:       Bool             = true
    var showDate:        Bool             = true
    var showTime:        Bool             = true
    var showHeader:      Bool             = false     // No header by default
    
    // Layout
    var layoutTemplate:  LayoutTemplate   = .classic
    var cardStyle:       CardStyle        = .rounded
    var columns:         Int              = 0        // 0 = auto
    var cardOpacity:     Double           = 1.0      // 0…1
    var headerStyle:     HeaderStyle      = .left
    var fontStyle:       FontStyle        = .system

    // Customizable text
    var subtitleText:    String           = ""

    // Scrim (background overlay darkness)
    var scrimIntensity:  Double           = 0.55     // 0…1

    // Grid gap multiplier
    var gridGap:         Double           = 1.0      // 0.5…2.0

    // Text scale multiplier
    var textScale:       Double           = 1.0      // 0.7…1.5

    // Padding inside cards
    var showPadding:     Double           = 1.0      // 0.5…2.0

    // Max rows (0 = show all)
    var maxRows:         Int              = 0

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
        "\(Self.dayFormatter.string(from: date)) · \(Self.timeFormatter.string(from: date))"
    }

    var monthAbbrev: String {
        Self.monthAbbrevFormatter.string(from: date).uppercased()
    }

    var dayNumber: String {
        Self.dayNumFormatter.string(from: date)
    }

    var timeString: String {
        Self.timeFormatter.string(from: date)
    }

    func formattedDate(style: DateFormatStyle) -> String {
        switch style {
        case .short:
            return "\(Self.shortDateFormatter.string(from: date)) · \(Self.timeFormatter.string(from: date))"
        case .full:
            return "\(Self.fullDateFormatter.string(from: date)) · \(Self.timeFormatter.string(from: date))"
        case .relative:
            return "\(Self.shortDateFormatter.string(from: date)) · \(Self.timeFormatter.string(from: date))"
        case .timeOnly:
            return Self.timeFormatter.string(from: date)
        }
    }

    // MARK: - Shared Formatters
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d"; return f
    }()
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f
    }()
    private static let monthAbbrevFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM"; return f
    }()
    private static let dayNumFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()
    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f
    }()
    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"; return f
    }()

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
        let textColor: UIColor
        if let customHex = options.textColorHex {
            textColor = UIColor(hex: customHex)
        } else {
            textColor = isLight ? UIColor(hex: "#1A1A1A") : .white
        }
        let subColor: UIColor = textColor.withAlphaComponent(0.65)

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
        let headerH: CGFloat = options.showHeader ? (options.headerStyle == .minimal ? size.width * 0.10 : size.width * 0.14) : 0
        let gridTop = pad + headerH
        let gridBottom = size.height - pad * 0.5
        let gridH = gridBottom - gridTop
        let gridW = size.width - pad * 2

        // 5. Header (only if enabled)
        if options.showHeader {
            drawHeader(ctx: ctx, size: size, pad: pad, performerName: performerName,
                       options: options, accent: accent, textColor: textColor, subColor: subColor)
        }

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

        // 7. Custom text overlays (if any)
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
                     color: textColor, maxWidth: size.width * 0.8, canvasHeight: size.height)

            // Subtitle line
            let subY = topY + nameSz * 1.35
            let subSz = size.width * 0.026
            let subFont = resolvedFont(size: subSz, weight: .medium, style: fontSt)
            if !options.subtitleText.isEmpty {
                drawText(options.subtitleText, at: CGPoint(x: pad, y: subY), font: subFont,
                         color: subColor, maxWidth: size.width * 0.5, canvasHeight: size.height)
            }

        case .centered:
            let nameSz = size.width * 0.07
            let nameFont = resolvedFont(size: nameSz, weight: .bold, style: fontSt)
            let nameAttrs: [NSAttributedString.Key: Any] = [.font: nameFont, .foregroundColor: textColor]
            let nameSize = (name as NSString).size(withAttributes: nameAttrs)
            let nx = (size.width - nameSize.width) / 2
            UIGraphicsPushContext(ctx)
            (name as NSString).draw(at: CGPoint(x: nx, y: topY), withAttributes: nameAttrs)
            UIGraphicsPopContext()

            let subY = topY + nameSize.height + size.width * 0.01
            let subSz = size.width * 0.024
            let subFont = resolvedFont(size: subSz, weight: .medium, style: fontSt)
            let subAttrs: [NSAttributedString.Key: Any] = [.font: subFont, .foregroundColor: subColor]
            let subText = options.subtitleText as NSString
            let subSize = subText.size(withAttributes: subAttrs)
            let sx = (size.width - subSize.width) / 2
            UIGraphicsPushContext(ctx)
            subText.draw(at: CGPoint(x: sx, y: subY), withAttributes: subAttrs)
            UIGraphicsPopContext()

        case .minimal:
            // Just the performer name, small, left-aligned
            let nameSz = size.width * 0.04
            let nameFont = resolvedFont(size: nameSz, weight: .semibold, style: fontSt)
            drawText(name, at: CGPoint(x: pad, y: topY), font: nameFont,
                     color: textColor, maxWidth: size.width * 0.5, canvasHeight: size.height)
        }
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

        let fontSt  = options.fontStyle
        let template = options.layoutTemplate
        let shows   = options.maxRows > 0 ? Array(allShows.prefix(options.maxRows * cols)) : allShows
        let count   = shows.count
        
        // Adjust columns for compact template
        let safeCols: Int
        switch template {
        case .compact:
            safeCols = max(1, cols + 1)  // More columns for compact
        default:
            safeCols = max(1, cols)
        }

        // Gap between cards
        let gapMultiplier: CGFloat = template == .compact ? 0.5 : 1.0
        let gap = gridSize.width * 0.025 * options.gridGap * gapMultiplier

        // Card width from column count
        let cardW = (gridSize.width - gap * CGFloat(safeCols - 1)) / CGFloat(safeCols)

        // Determine row count and card height
        let rows = Int(ceil(Double(count) / Double(safeCols)))
        let rowGap = gap
        let cardH: CGFloat
        if rows > 0 {
            let totalRowGaps = rowGap * CGFloat(max(rows - 1, 0))
            cardH = max(1, (gridSize.height - totalRowGaps) / CGFloat(rows))
        } else {
            cardH = gridSize.height
        }

        // Fonts scaled to card size - adjust for template
        let ts = options.textScale
        let compactScale: CGFloat = template == .compact ? 0.85 : 1.0
        let innerPad  = cardW * 0.07 * options.showPadding
        let titleSz   = max(10, cardH * 0.22 * ts * compactScale)
        let detailSz  = max(8,  cardH * 0.15 * ts * compactScale)
        let dateSz    = max(8,  cardH * 0.13 * ts * compactScale)
        let monthSz   = max(7,  cardH * 0.11 * ts * compactScale)

        for (i, show) in shows.enumerated() {
            let col = i % safeCols
            let row = i / safeCols

            let cardX = gridOrigin.x + CGFloat(col) * (cardW + gap)
            let cardY = gridOrigin.y + CGFloat(row)  * (cardH + rowGap)
            let cardRect = CGRect(x: cardX, y: cardY, width: cardW, height: cardH)

            switch template {
            case .classic:
                // Date badge left, text right
                drawClassicCard(ctx: ctx, show: show, cardRect: cardRect, innerPad: innerPad,
                               titleSz: titleSz, detailSz: detailSz, dateSz: dateSz, monthSz: monthSz,
                               fontSt: fontSt, accent: accent, textColor: textColor, subColor: subColor, options: options)
                
            case .minimal:
                // Simple text list, no date badge
                drawMinimalCard(ctx: ctx, show: show, cardRect: cardRect, innerPad: innerPad,
                               titleSz: titleSz, detailSz: detailSz,
                               fontSt: fontSt, textColor: textColor, subColor: subColor, options: options)
                
            case .bold:
                // Large date on top, text below
                drawBoldCard(ctx: ctx, show: show, cardRect: cardRect, innerPad: innerPad,
                            titleSz: titleSz, detailSz: detailSz, dateSz: dateSz, monthSz: monthSz,
                            fontSt: fontSt, accent: accent, textColor: textColor, subColor: subColor, options: options)
                
            case .compact:
                // Small cards, tight layout
                drawCompactCard(ctx: ctx, show: show, cardRect: cardRect, innerPad: innerPad,
                               titleSz: titleSz, detailSz: detailSz, monthSz: monthSz,
                               fontSt: fontSt, accent: accent, textColor: textColor, subColor: subColor, options: options)
            }
        }
    }

    // MARK: - Card Templates

    /// Classic: Date badge on left, show details on right
    private static func drawClassicCard(ctx: CGContext, show: ShowSnapshot, cardRect: CGRect,
                                         innerPad: CGFloat, titleSz: CGFloat, detailSz: CGFloat,
                                         dateSz: CGFloat, monthSz: CGFloat, fontSt: FontStyle,
                                         accent: UIColor, textColor: UIColor, subColor: UIColor,
                                         options: ExportOptions) {
        let cardX = cardRect.minX
        let cardY = cardRect.minY
        let cardW = cardRect.width
        let cardH = cardRect.height
        
        // Date badge (left strip)
        let badgeW = cardW * 0.22
        let badgeX = cardX + innerPad * 0.5
        let badgeY = cardY + cardH * 0.15

        if options.showDate {
            // Month
            let monthFont = resolvedFont(size: monthSz, weight: .bold, style: fontSt)
            let monthAttrs: [NSAttributedString.Key: Any] = [.font: monthFont, .foregroundColor: accent]
            let monthStr = show.monthAbbrev as NSString
            let monthSize = monthStr.size(withAttributes: monthAttrs)
            UIGraphicsPushContext(ctx)
            monthStr.draw(at: CGPoint(x: badgeX + (badgeW - monthSize.width) / 2, y: badgeY), withAttributes: monthAttrs)
            UIGraphicsPopContext()

            // Day number
            let dayFont = resolvedFont(size: dateSz * 1.5, weight: .heavy, style: fontSt)
            let dayAttrs: [NSAttributedString.Key: Any] = [.font: dayFont, .foregroundColor: textColor]
            let dayStr = show.dayNumber as NSString
            let daySize = dayStr.size(withAttributes: dayAttrs)
            UIGraphicsPushContext(ctx)
            dayStr.draw(at: CGPoint(x: badgeX + (badgeW - daySize.width) / 2, y: badgeY + monthSize.height + 1), withAttributes: dayAttrs)
            UIGraphicsPopContext()
        }

        // Text content (right of date badge)
        let textX = options.showDate ? cardX + badgeW + innerPad : cardX + innerPad
        let textW = options.showDate ? max(1, cardW - badgeW - innerPad * 1.5) : max(1, cardW - innerPad * 2)

        // Title
        let titleFont = resolvedFont(size: titleSz, weight: .bold, style: fontSt)
        let titleY = cardY + cardH * 0.18
        drawText(show.titleOrEmpty, at: CGPoint(x: textX, y: titleY),
                 font: titleFont, color: textColor,
                 maxWidth: textW, canvasHeight: cardRect.maxY,
                 forceNoTruncation: true)

        // Venue
        var nextY = titleY + titleSz * 1.3
        if options.showVenue, !show.venueOrEmpty.isEmpty {
            let venueFont = resolvedFont(size: detailSz, weight: .medium, style: fontSt)
            drawText(show.venueOrEmpty, at: CGPoint(x: textX, y: nextY),
                     font: venueFont, color: subColor,
                     maxWidth: textW, canvasHeight: cardRect.maxY,
                     forceNoTruncation: true)
            nextY += detailSz * 1.3
        }

        // Time
        if options.showTime {
            let timeFont = resolvedFont(size: detailSz * 0.9, weight: .regular, style: fontSt)
            drawText(show.timeString, at: CGPoint(x: textX, y: nextY),
                     font: timeFont, color: subColor.withAlphaComponent(0.75),
                     maxWidth: textW, canvasHeight: cardRect.maxY)
        }
    }

    /// Minimal: Clean text-only, no date badge
    private static func drawMinimalCard(ctx: CGContext, show: ShowSnapshot, cardRect: CGRect,
                                         innerPad: CGFloat, titleSz: CGFloat, detailSz: CGFloat,
                                         fontSt: FontStyle, textColor: UIColor, subColor: UIColor,
                                         options: ExportOptions) {
        let cardX = cardRect.minX
        let cardY = cardRect.minY
        let cardW = cardRect.width
        
        let textX = cardX + innerPad
        let textW = max(1, cardW - innerPad * 2)
        var currentY = cardY + innerPad

        // Title
        let titleFont = resolvedFont(size: titleSz, weight: .bold, style: fontSt)
        drawText(show.titleOrEmpty, at: CGPoint(x: textX, y: currentY),
                 font: titleFont, color: textColor,
                 maxWidth: textW, canvasHeight: cardRect.maxY,
                 forceNoTruncation: true)
        currentY += titleSz * 1.2

        // Date inline
        if options.showDate {
            let dateFont = resolvedFont(size: detailSz, weight: .medium, style: fontSt)
            let dateStr = "\(show.monthAbbrev) \(show.dayNumber)" + (options.showTime ? " · \(show.timeString)" : "")
            drawText(dateStr, at: CGPoint(x: textX, y: currentY),
                     font: dateFont, color: subColor,
                     maxWidth: textW, canvasHeight: cardRect.maxY)
            currentY += detailSz * 1.2
        }

        // Venue
        if options.showVenue, !show.venueOrEmpty.isEmpty {
            let venueFont = resolvedFont(size: detailSz * 0.9, weight: .regular, style: fontSt)
            drawText(show.venueOrEmpty, at: CGPoint(x: textX, y: currentY),
                     font: venueFont, color: subColor.withAlphaComponent(0.7),
                     maxWidth: textW, canvasHeight: cardRect.maxY,
                     forceNoTruncation: true)
        }
    }

    /// Bold: Large date on top, details below
    private static func drawBoldCard(ctx: CGContext, show: ShowSnapshot, cardRect: CGRect,
                                      innerPad: CGFloat, titleSz: CGFloat, detailSz: CGFloat,
                                      dateSz: CGFloat, monthSz: CGFloat, fontSt: FontStyle,
                                      accent: UIColor, textColor: UIColor, subColor: UIColor,
                                      options: ExportOptions) {
        let cardX = cardRect.minX
        let cardY = cardRect.minY
        let cardW = cardRect.width
        let cardH = cardRect.height
        
        let textX = cardX + innerPad
        let textW = max(1, cardW - innerPad * 2)
        var currentY = cardY + innerPad * 0.5

        // Large date at top
        if options.showDate {
            let bigDateSz = dateSz * 2.5
            let dateFont = resolvedFont(size: bigDateSz, weight: .heavy, style: fontSt)
            let dateStr = "\(show.monthAbbrev) \(show.dayNumber)" as NSString
            let dateAttrs: [NSAttributedString.Key: Any] = [.font: dateFont, .foregroundColor: accent]
            let dateSize = dateStr.size(withAttributes: dateAttrs)
            UIGraphicsPushContext(ctx)
            dateStr.draw(at: CGPoint(x: cardX + (cardW - dateSize.width) / 2, y: currentY), withAttributes: dateAttrs)
            UIGraphicsPopContext()
            currentY += bigDateSz * 1.1
        }

        // Title centered
        let titleFont = resolvedFont(size: titleSz, weight: .bold, style: fontSt)
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: textColor]
        let titleStr = show.titleOrEmpty as NSString
        let titleSize = titleStr.size(withAttributes: titleAttrs)
        UIGraphicsPushContext(ctx)
        titleStr.draw(at: CGPoint(x: cardX + (cardW - min(titleSize.width, textW)) / 2, y: currentY), withAttributes: titleAttrs)
        UIGraphicsPopContext()
        currentY += titleSz * 1.2

        // Venue centered
        if options.showVenue, !show.venueOrEmpty.isEmpty {
            let venueFont = resolvedFont(size: detailSz, weight: .medium, style: fontSt)
            let venueAttrs: [NSAttributedString.Key: Any] = [.font: venueFont, .foregroundColor: subColor]
            let venueStr = show.venueOrEmpty as NSString
            let venueSize = venueStr.size(withAttributes: venueAttrs)
            UIGraphicsPushContext(ctx)
            venueStr.draw(at: CGPoint(x: cardX + (cardW - min(venueSize.width, textW)) / 2, y: currentY), withAttributes: venueAttrs)
            UIGraphicsPopContext()
            currentY += detailSz * 1.2
        }

        // Time centered
        if options.showTime {
            let timeFont = resolvedFont(size: detailSz * 0.9, weight: .regular, style: fontSt)
            let timeAttrs: [NSAttributedString.Key: Any] = [.font: timeFont, .foregroundColor: subColor.withAlphaComponent(0.7)]
            let timeStr = show.timeString as NSString
            let timeSize = timeStr.size(withAttributes: timeAttrs)
            UIGraphicsPushContext(ctx)
            timeStr.draw(at: CGPoint(x: cardX + (cardW - timeSize.width) / 2, y: currentY), withAttributes: timeAttrs)
            UIGraphicsPopContext()
        }
    }

    /// Compact: Small cards with essential info
    private static func drawCompactCard(ctx: CGContext, show: ShowSnapshot, cardRect: CGRect,
                                         innerPad: CGFloat, titleSz: CGFloat, detailSz: CGFloat,
                                         monthSz: CGFloat, fontSt: FontStyle,
                                         accent: UIColor, textColor: UIColor, subColor: UIColor,
                                         options: ExportOptions) {
        let cardX = cardRect.minX
        let cardY = cardRect.minY
        let cardW = cardRect.width
        
        let textX = cardX + innerPad * 0.5
        let textW = max(1, cardW - innerPad)
        var currentY = cardY + innerPad * 0.3

        // Date small inline
        if options.showDate {
            let dateFont = resolvedFont(size: monthSz, weight: .bold, style: fontSt)
            let dateStr = "\(show.monthAbbrev) \(show.dayNumber)"
            drawText(dateStr, at: CGPoint(x: textX, y: currentY),
                     font: dateFont, color: accent,
                     maxWidth: textW, canvasHeight: cardRect.maxY)
            currentY += monthSz * 1.1
        }

        // Title
        let titleFont = resolvedFont(size: titleSz * 0.9, weight: .bold, style: fontSt)
        drawText(show.titleOrEmpty, at: CGPoint(x: textX, y: currentY),
                 font: titleFont, color: textColor,
                 maxWidth: textW, canvasHeight: cardRect.maxY,
                 forceNoTruncation: true)
        currentY += titleSz * 1.0

        // Venue (smaller)
        if options.showVenue, !show.venueOrEmpty.isEmpty {
            let venueFont = resolvedFont(size: detailSz * 0.8, weight: .regular, style: fontSt)
            drawText(show.venueOrEmpty, at: CGPoint(x: textX, y: currentY),
                     font: venueFont, color: subColor.withAlphaComponent(0.7),
                     maxWidth: textW, canvasHeight: cardRect.maxY,
                     forceNoTruncation: true)
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
                        drawImageFill(img, in: rect, ctx: ctx)
                    } else {
                        ctx.setFillColor(UIColor(hex: "#111111").cgColor); ctx.fill(rect)
                    }
                }
            } else {
                ctx.setFillColor(UIColor(hex: "#111111").cgColor); ctx.fill(rect)
            }
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
                                  lineSpacing: CGFloat = 0, forceNoTruncation: Bool = false) {
        let drawWidth = max(1, maxWidth)
        let drawHeight = max(1, canvasHeight - origin.y)
        let ps = NSMutableParagraphStyle()
        ps.lineSpacing = lineSpacing
        if forceNoTruncation {
            ps.lineBreakMode = .byWordWrapping
        } else {
            ps.lineBreakMode = .byTruncatingTail
        }
        var usedFont = font
        var attrString = NSAttributedString(string: text, attributes: [.font: usedFont, .foregroundColor: color, .paragraphStyle: ps])
        var bounding = attrString.boundingRect(with: CGSize(width: drawWidth, height: drawHeight), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        // If forceNoTruncation and text doesn't fit, reduce font size until it fits
        if forceNoTruncation && (bounding.height > drawHeight || bounding.width > drawWidth) {
            var fontSize = font.pointSize
            let minFontSize: CGFloat = 8
            while (bounding.height > drawHeight || bounding.width > drawWidth) && fontSize > minFontSize {
                fontSize -= 1
                usedFont = font.withSize(fontSize)
                attrString = NSAttributedString(string: text, attributes: [.font: usedFont, .foregroundColor: color, .paragraphStyle: ps])
                bounding = attrString.boundingRect(with: CGSize(width: drawWidth, height: drawHeight), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            }
        }
        attrString.draw(in: CGRect(x: origin.x, y: origin.y, width: drawWidth, height: drawHeight))
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
