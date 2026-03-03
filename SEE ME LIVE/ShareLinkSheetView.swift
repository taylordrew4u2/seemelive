//
//  ShareLinkSheetView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI

// MARK: - Share Link Sheet View
/// Super simple share sheet - one tap to copy or share your calendar link.

struct ShareLinkSheetView: View {
    @Environment(\.dismiss) private var dismiss

    let userID: String

    @State private var copied = false

    private var shareURL: URL {
        ShareLinkService.shareURL(for: userID)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 120, height: 120)
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)
                }

                // Title & Description
                VStack(spacing: 10) {
                    Text("Share Your Shows")
                        .font(.title.bold())

                    Text("Anyone with this link can see all your upcoming performances")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Link Preview
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(Color.accentColor)
                        Text(shareURL.host ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider()

                    Text(shareURL.absoluteString)
                        .font(.footnote.monospaced())
                        .foregroundStyle(Color.accentColor)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color("CardBackground"))
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                )
                .padding(.horizontal, 24)

                // Action Buttons
                VStack(spacing: 14) {
                    // Copy Link Button
                    Button {
                        UIPasteboard.general.string = shareURL.absoluteString
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        withAnimation(.spring(response: 0.3)) {
                            copied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { copied = false }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.body.bold())
                            Text(copied ? "Copied!" : "Copy Link")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(copied ? Color.green : Color.accentColor, lineWidth: 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(copied ? Color.green.opacity(0.1) : Color.clear)
                                )
                        )
                        .foregroundStyle(copied ? .green : Color.accentColor)
                    }

                    // Share Button
                    ShareLink(item: shareURL, message: Text("Check out my upcoming shows! 🎤")) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.body.bold())
                            Text("Share")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.accentColor)
                        )
                        .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                Spacer()
            }
            .background(Color("AppBackground"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ShareLinkSheetView(userID: "preview-user")
}
