//
//  SEE_ME_LIVEApp.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI
import CoreData
import CloudKit

@main
struct SEE_ME_LIVEApp: App {
    let persistenceController = PersistenceController.shared

    /// Ensure the user ID is generated on first launch.
    private let _userID = UserIdentityService.shared.userID

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                              persistenceController.container.viewContext)
                .tint(Color.accentColor)
                .onReceive(NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Retry any pending public CloudKit operations when
                    // the app comes back to the foreground.
                    let ctx = persistenceController.container.viewContext
                    Task {
                        await PublicCloudSyncService.shared.flushQueue(using: ctx)
                    }
                }
        }
    }
}
