//
//  FreedomTrackerApp.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import SwiftUI
import SwiftData

@main
struct FreedomTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        // 💡 МЕНЯЕМ СХЕМУ НА НОВЫЕ МОДЕЛИ
        let schema = Schema([
            BudgetCycle.self,
            ExpenseTransaction.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

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
