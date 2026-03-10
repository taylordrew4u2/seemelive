//
//  ShareLinkService.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import Foundation

// MARK: - Share Link Service
/// Builds the public-facing URLs for the GitHub Pages calendar view,
/// and lazily generates a short link (via TinyURL) that is cached
/// permanently in UserDefaults — so it is created once and never changes.

enum ShareLinkService {

    // The real host (GitHub Pages serves the fan page).
    private static let baseURL = "https://taylordrew4u2.github.io/seemelive"

    // UserDefaults key where the cached short link is stored.
    private static let shortLinkKey = "com.seemelive.shortLink"

    // MARK: - Raw URL builders

    static func shareURL(for userID: String) -> URL {
        var c = URLComponents(string: baseURL)!
        c.queryItems = [URLQueryItem(name: "user", value: userID)]
        return c.url!
    }

    static func calendarFeedURL(for userID: String) -> URL {
        var c = URLComponents(string: baseURL)!
        c.path += "/calendar.ics"
        c.queryItems = [URLQueryItem(name: "user", value: userID)]
        return c.url!
    }

    static var currentShareURL: URL {
        shareURL(for: UserIdentityService.shared.userID)
    }

    static var currentCalendarFeedURL: URL {
        calendarFeedURL(for: UserIdentityService.shared.userID)
    }

    // MARK: - Short link (auto-generated, cached forever)

    /// Returns a short link for the current user's fan page.
    /// On first call it hits the TinyURL API; afterwards it returns
    /// the cached value instantly — no user action required.
    static func shortLink() async -> URL {
        // Return cached value if we already have one.
        if let cached = UserDefaults.standard.string(forKey: shortLinkKey),
           let url = URL(string: cached) {
            return url
        }

        let longURL = currentShareURL.absoluteString
        let apiURL  = URL(string: "https://tinyurl.com/api-create.php?url=\(longURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? longURL)")!

        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            if let short = String(data: data, encoding: .utf8),
               short.hasPrefix("https://"),
               let url = URL(string: short.trimmingCharacters(in: .whitespacesAndNewlines)) {
                // Cache it permanently.
                UserDefaults.standard.set(url.absoluteString, forKey: shortLinkKey)
                return url
            }
        } catch {
            print("⚠️ TinyURL shortening failed, using full URL: \(error)")
        }

        // Fallback: return the raw URL if the API is unreachable.
        return currentShareURL
    }

    /// Clears the cached short link (e.g. if the user ID changes).
    static func clearCachedShortLink() {
        UserDefaults.standard.removeObject(forKey: shortLinkKey)
    }
}
