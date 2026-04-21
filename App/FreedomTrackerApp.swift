//
//  FreedomTrackerApp.swift
//  FreedomTracker
//

import SwiftUI
import SwiftData

@main
struct FreedomTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Подключаем единый контейнер, который пишет в App Group
        .modelContainer(AppConstants.sharedModelContainer)
    }
}
