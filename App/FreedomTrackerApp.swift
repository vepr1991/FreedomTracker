//
//  FreedomTrackerApp.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

//
//  FreedomTrackerApp.swift
//  FreedomTracker
//

import SwiftUI
import SwiftData

@main
struct FreedomTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([BudgetCycle.self, ExpenseTransaction.self])
        
        // 💡 НОВОЕ: Указываем путь к нашей общей папке App Group
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.vladimirkovalenko.FreedomTracker")!
        let dbURL = groupURL.appendingPathComponent("FreedomData.sqlite")
        
        let modelConfiguration = ModelConfiguration(schema: schema, url: dbURL)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
