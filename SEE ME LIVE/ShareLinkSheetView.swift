//
//  ShareLinkSheetView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI

// MARK: - Share Link Sheet View
/// A beautiful modal sheet for sharing the user's public calendar link.
/// Shows a mini preview, the URL, and copy/share actions.

struct ShareLinkSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let userID: String

    @State private var copied = false
    @State private var selectedTab = 0

    private var shareURL: URL {
        ShareLinkService.shareURL(for: userID)
    }

    private var calendarFeedURL: URL {
        ShareLinkService.calendarFeedURL(for: userID)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(Color.accentColor)
                }

                // Title
                VStack(spacing: 8) {
                    Text("Share Your Gigs")
                        .font(.title2.bold())

                    Text("Choose how to share your upcoming shows.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Segmented picker for tab selection
                Picker("Share Method", selection: $selectedTab) {
                    Text("📱 Web Link").tag(0)
                    Text("📅 Calendar Feed").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                if selectedTab == 0 {
                    webLinkView
                } else {
                    calendarFeedView
                }

                Spacer()
            }
            .background(Color("AppBackground"))
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Web Link View

    private var webLinkView: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                // Mini calendar preview
                HStack(spacing: 10) {
                    Image(systemName: "music.mic.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SEE ME LIVE")
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                        Text("Your Public Calendar")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "globe")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // URL
                Text(shareURL.absoluteString)
                    .font(.footnote.monospaced())
                    .foregroundStyle(Color.accentColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("CardBackground"))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            )
            .padding(.horizontal, 20)

            // Action Buttons
            VStack(spacing: 12) {
                // Copy Link
                Button {
                    UIPasteboard.general.string = shareURL.absoluteString
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                    withAnimation(.spring(response: 0.3)) {
                        copied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation { copied = false }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.body.bold())
                        Text(copied ? "Copied!" : "Copy Link")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 13)
                            .strokeBorder(copied ? Color.green : Color.accentColor, lineWidth: 2)
                            .background(
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(copied ? Color.green.opacity(0.08) : Color.clear)
                            )
                    )
                    .foregroundStyle(copied ? .green : Color.accentColor)
                }

                // Share via system share sheet
                Button {
                    presentSystemShareSheet(items: ["Check out my upcoming shows! 🎤", shareURL])
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body.bold())
                        Text("Share")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 13)
                            .fill(Color.accentColor)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 6, y: 3)
                    )
                    .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Calendar Feed View

    private var calendarFeedView: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                // Calendar feed preview
                HStack(spacing: 10) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCalendar Feed")
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                        Text("Auto-sync with Calendar apps")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                Divider()

                // URL
                Text(calendarFeedURL.absoluteString)
                    .font(.footnote.monospaced())
                    .foregroundStyle(Color.accentColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("CardBackground"))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            )
            .padding(.horizontal, 20)

            // Calendar app buttons
            VStack(spacing: 12) {
                // Copy Feed Link
                Button {
                    UIPasteboard.general.string = calendarFeedURL.absoluteString
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                    withAnimation(.spring(response: 0.3)) {
                        copied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation { copied = false }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.body.bold())
                        Text(copied ? "Copied!" : "Copy Feed Link")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 13)
                            .strokeBorder(copied ? Color.green : Color.accentColor, lineWidth: 2)
                            .background(
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(copied ? Color.green.opacity(0.08) : Color.clear)
                            )
                    )
                    .foregroundStyle(copied ? .green : Color.accentColor)
                }

                // Share to Calendar
                Button {
                    presentSystemShareSheet(items: ["Add to your calendar: SEE ME LIVE", calendarFeedURL])
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body.bold())
                        Text("Add to Calendar")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 13)
                            .fill(Color.accentColor)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 6, y: 3)
                    )
                    .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Present System Share Sheet

    /// Presents UIActivityViewController directly from the root window
    /// to avoid issues with nested sheet presentation on iOS 17.
    private func presentSystemShareSheet(items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        // Walk to the topmost presented controller so the share sheet
        // appears above this modal.
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        // iPad requires a popover source.
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX,
                                        y: topVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        topVC.present(activityVC, animated: true)
    }
}

#Preview {
    ShareLinkSheetView(userID: "preview-user-id")
}
