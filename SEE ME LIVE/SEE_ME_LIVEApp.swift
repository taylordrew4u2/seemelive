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

    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                } else {
                    HomeScreenView()
                        .transition(.opacity)
                }
            }
            .environment(\.managedObjectContext,
                          persistenceController.container.viewContext)
            .tint(Color.accentColor)
            .onAppear {
                // Show splash for 2.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(
                for: UIApplication.willEnterForegroundNotification)) { _ in
                // Retry any pending public CloudKit operations when
                // the app comes back to the foreground.
                Task.detached {
                    let bgContext = persistenceController.container.newBackgroundContext()
                    await PublicCloudSyncService.shared.flushQueue(using: bgContext)
                }
            }
        }
    }
}
