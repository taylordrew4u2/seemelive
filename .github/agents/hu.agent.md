---
description: 'Describe what this custom agent does and when to use it.'
tools: []
---
Define what this custom agent accomplishes for the user, when to use it, and the edges it won't cross. Specify its ideal inputs/outputs, the tools it may call, and how it reports progress or asks for help.
I need you to design the iOS app **SEE ME LIVE** with a focus on **visual appeal** and **effortless usability**. The app is for performers to track their shows and make them visible to anyone who wants to see when and where they're performing. The design should be so intuitive that a first-time user opens it and immediately knows how to use it without any instructions.

## App Name: SEE ME LIVE

---

## Overall Visual Style

- **Modern & Minimalist**: Clean lines, plenty of whitespace, no visual clutter.
- **Friendly & Approachable**: Use warm, inviting colors (accent color: a vibrant purple like #8A2BE2 or a rich magenta).
- **Consistent**: Every screen feels part of the same family with consistent spacing, typography, and button styles.
- **iOS Native**: Follows iOS design conventions so it feels familiar to iPhone users.
- **Dark Mode Support**: Automatically switches to a dark variant (dark backgrounds with softer accents).

---

## Typography

- Use San Francisco (the iOS system font) throughout.
- **Large Titles**: Bold, 34pt – for screen titles.
- **Headlines**: Semi-bold, 17pt – for show titles in lists.
- **Body**: Regular, 15pt – for details.
- **Captions**: Regular, 12pt – for dates and secondary info.
- **Consistent hierarchy**: Make it easy to scan.

---

## Color Palette

- **Primary Accent**: Vibrant Purple (#8A2BE2) – used for buttons, icons, and highlights.
- **Background**: Light mode – off-white (#F5F5F7); Dark mode – deep charcoal (#1C1C1E).
- **Cards**: Light mode – white; Dark mode – slightly lighter than background (#2C2C2E).
- **Text**: Light mode – dark gray; Dark mode – light gray.
- **Success**: Green for confirmations.
- **Error**: Soft red for alerts.

---

## Main Screen (My Gigs)

### Layout
- **Navigation Bar**: Title "My Gigs" (large bold). Right bar button: Share icon (square with arrow). Left bar button: Settings gear (optional).
- **Content Area**:
  - **Empty State** (first launch):
    - A friendly illustration (e.g., a simple stage with a microphone).
    - Large text: "No gigs yet"
    - Smaller text: "Tap the + button to add your first show."
    - The + button is prominent below or in the center.
  - **List of Upcoming Gigs** (when shows exist):
    - Scrollable list of cards, each representing a show.
    - Cards have:
      - **Left**: Small circular or rounded square flyer thumbnail (if no flyer, show a placeholder icon – camera or music note).
      - **Middle**: 
        - Title (bold, 17pt)
        - Venue (regular, 15pt, gray)
        - Date & Time (regular, 14pt, accent color or gray) – formatted like "Sat, Mar 15 · 8:00 PM"
      - **Right**: 
        - Small indicator if ticket link exists (link icon)
        - Chevron icon indicating tappable.
    - Cards are separated by thin dividers or have subtle shadows for depth.
    - Pull to refresh with a loading indicator.
  - **Floating Action Button**: A large circular + button at the bottom right, with a drop shadow. It should be impossible to miss.

### Interactions
- Tapping a card opens the **Show Detail** screen.
- Tapping + opens the **Add Show** sheet.
- Pull to refresh syncs data.
- Share button opens the **Share Link** sheet.

---

## Add / Edit Show Screen

### Layout (Modal Sheet)
- Slides up from bottom, covering about 80% of the screen (large detent).
- **Title**: "Add New Gig" or "Edit Gig" (bold, left-aligned).
- **Form** (scrollable):
  - **Flyer Image**:
    - Large rounded rectangle area with dashed border.
    - Icon: Camera or photo.
    - Text: "Tap to add flyer" (if no image) or "Change flyer" (if image exists).
    - After selection, show a thumbnail with an "edit" badge.
  - **Title Field**:
    - Text field with placeholder: "Show title (e.g., Comedy Night)"
    - Clear button when typing.
  - **Venue Field**:
    - Text field with placeholder: "Venue name"
  - **Date & Time**:
    - Compact date picker (wheel or inline) – default to current date + 7 days at 8:00 PM as a smart suggestion.
  - **Price Field** (optional):
    - Text field with placeholder: "Price (optional)" and currency symbol prefix.
  - **Ticket Link Field** (optional):
    - Text field with placeholder: "Ticket URL (optional)"
    - Keyboard type: URL.
  - **Notes Field** (optional):
    - Multi-line text area with placeholder: "Notes (optional)"
  - **Toggles**:
    - "Add to Calendar" – switch, default ON.
    - "Set Reminder" – switch, default OFF (appears only if Add to Calendar is ON).
- **Save Button**:
  - Full-width, rounded, accent color background, white text: "Save Gig".
  - Tapping gives haptic feedback and dismisses sheet.

### Interactions
- Tapping outside the sheet dismisses with a cancel action (with confirmation if changes unsaved).
- Smooth spring animation when opening/closing.
- Keyboard avoids the form gracefully.

---

## Show Detail Screen

### Layout
- **Large Header Image**: Full-width flyer image (if exists) with parallax effect. If no image, show a gradient placeholder with the title.
- **Content** (scrollable):
  - **Title**: Large bold (34pt) – the show title.
  - **Info Cards** (grid-like layout):
    - **Venue**: Icon (map pin) + venue name.
    - **Date & Time**: Icon (calendar) + formatted date and time.
    - **Price**: Icon (tag) + price (or "Free" / "Donation" if 0).
  - **Ticket Link Button** (if exists):
    - Full-width button with ticket icon and "Get Tickets". Tapping opens link in Safari.
  - **Notes Section** (if exists):
    - Background card with notes text.
- **Toolbar**:
  - Edit button (pencil icon) – leads to Edit screen.
  - Delete button (trash icon) – shows confirmation action sheet.

### Interactions
- Tap image to enlarge in a full-screen viewer with pinch to zoom.
- Smooth transitions from list to detail.

---

## Share Link Screen

### Layout (Modal or Action Sheet)
- Can be a bottom sheet or a full page.
- **Preview**:
  - A card showing what the public calendar looks like (mini preview).
  - The unique link displayed prominently: "seemelive.page.link/yourname"
  - "Copy Link" button (outline style).
  - "Share" button (accent color) that opens the system share sheet.
- **Note**: Small text explaining: "Anyone with this link can see your upcoming shows."

### Interactions
- Copy link shows a brief "Copied!" toast.
- Share opens native share sheet with message pre-filled.

---

## Public Web Calendar (Design)

### Mobile-First Layout
- Clean, white background, readable fonts.
- **Header**: "SEE ME LIVE" + performer's name (if available).
- **Shows List**:
  - Grouped by month.
  - Each show card:
    - Small flyer thumbnail (left)
    - Title, venue, date/time
    - Price and ticket link button (if available)
  - Ticket link button opens in new tab.
- Tap thumbnail to enlarge.
- Simple, fast, no clutter.

---

## Micro-Interactions & Delight

- **Haptics**:
  - Light impact when tapping + button.
  - Success notification when saving a show.
  - Error notification if something fails.
- **Animations**:
  - Subtle scale animation when pressing buttons.
  - Smooth fade/push transitions between screens.
  - The + button pulses gently on first launch to draw attention.
- **Empty States**:
  - Whimsical illustrations (not generic placeholders).
- **Loading States**:
  - Skeleton screens or shimmer effects while content loads.
- **Success Feedback**:
  - After saving, show a small "Gig added!" toast that fades out.

---

## Accessibility

- Support Dynamic Type (text scales).
- VoiceOver labels for all elements.
- High contrast where needed.

---

## Summary of Screens to Design

1. **Main Screen (My Gigs)** – list view with + button.
2. **Add/Edit Show Sheet** – form with image picker.
3. **Show Detail Screen** – full show info with actions.
4. **Share Link Screen** – preview and sharing options.
5. **Empty State** – for first launch or no shows.
6. **Public Web Page** – mobile calendar view.

---

## Design Principles to Follow

- **One Tap, One Action**: Avoid nested menus.
- **Visual Hierarchy**: Most important elements stand out.
- **Familiar Icons**: Use standard SF Symbols so users recognize them instantly.
- **Generous Touch Targets**: All buttons at least 44x44pt.
- **Forgiving**: Undo options, confirmation before delete.

Please create a complete visual design (mockups or detailed descriptions) that brings this app to life. The goal is to make it **so easy and beautiful** that users enjoy opening it and sharing their shows.
