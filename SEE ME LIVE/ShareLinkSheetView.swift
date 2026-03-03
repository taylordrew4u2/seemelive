//
//  ShareLinkSheetView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

// MARK: - Share Link Sheet View
/// Export and share a beautiful HTML calendar page.

struct ShareLinkSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    let userID: String

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Show.date, ascending: true)],
        predicate: NSPredicate(format: "date >= %@", Date() as NSDate),
        animation: .default
    ) private var upcomingShows: FetchedResults<Show>

    @State private var isGenerating = false
    @State private var generatedHTML: String?
    @State private var showShareSheet = false
    @State private var htmlFileURL: URL?
    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.accentColor)
                }

                // Title & Description
                VStack(spacing: 10) {
                    Text("Export Calendar")
                        .font(.title.bold())

                    Text("Generate a beautiful webpage with all your upcoming shows")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Stats
                HStack(spacing: 20) {
                    VStack {
                        Text("\(upcomingShows.count)")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundStyle(Color.accentColor)
                        Text("Shows")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color("CardBackground"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
                        )
                )

                // Action Buttons
                VStack(spacing: 14) {
                    // Generate & Share Button
                    Button {
                        generateAndShare()
                    } label: {
                        HStack(spacing: 10) {
                            if isGenerating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.body.bold())
                            }
                            Text(isGenerating ? "Generating..." : "Generate & Share")
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
                    .disabled(isGenerating || upcomingShows.isEmpty)

                    // Preview Button
                    if generatedHTML != nil {
                        Button {
                            if let url = htmlFileURL {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "eye")
                                    .font(.body.bold())
                                Text("Preview")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.accentColor, lineWidth: 2)
                            )
                            .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .padding(.horizontal, 24)

                if upcomingShows.isEmpty {
                    Text("Add some shows to export your calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .background(Color("AppBackground"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = htmlFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Actions

    private func generateAndShare() {
        isGenerating = true

        // Small delay for UI feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let html = HTMLExportService.generateHTML(
                shows: Array(upcomingShows),
                performerName: "Your"
            )
            generatedHTML = html

            if let url = HTMLExportService.saveHTMLToFile(html: html) {
                htmlFileURL = url
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                isGenerating = false
                showShareSheet = true
            } else {
                isGenerating = false
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ShareLinkSheetView(userID: "preview-user")
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
