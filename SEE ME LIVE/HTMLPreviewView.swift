//
//  HTMLPreviewView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI
import WebKit

// MARK: - WKWebView SwiftUI Wrapper

struct WebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.isOpaque = false
        wv.backgroundColor = .clear
        wv.scrollView.backgroundColor = .clear
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - Full-screen HTML Preview Sheet

struct HTMLPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let html: String
    let onExport: (() -> Void)?   // optional: called when user taps "Export / Share"

    init(html: String, onExport: (() -> Void)? = nil) {
        self.html = html
        self.onExport = onExport
    }

    var body: some View {
        NavigationStack {
            WebView(html: html)
                .ignoresSafeArea(edges: .bottom)
                .background(Color("AppBackground"))
                .navigationTitle("Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                    if onExport != nil {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                onExport?()
                                dismiss()
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
        }
    }
}

#Preview {
    HTMLPreviewView(
        html: HTMLExportService.generateHTML(shows: [], options: CalendarDisplayOptions())
    )
}
