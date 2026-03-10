//
//  UserIdentityService.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import Foundation

// MARK: - User Identity Service
/// Generates a stable UUID on first launch and persists it in UserDefaults.
/// This ID tags every show in the CloudKit public database so the public
/// calendar page can filter by user.

final class UserIdentityService: Sendable {
    static let shared = UserIdentityService()

    private let key = "com.seemelive.userID"

    /// The unique user ID for this install. Created once, then reused forever.
    var userID: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: key)
        return newID
    }

    private init() {}
}
