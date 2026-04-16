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
        let schema = Schema([BudgetCycle.self, ExpenseTransaction.self])
        
        // Указываем путь к нашей общей папке App Group
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.vladimirkovalenko.FreedomTracker")!
        let dbURL = groupURL.appendingPathComponent("FreedomData.sqlite")
        
        let modelConfiguration = ModelConfiguration(schema: schema, url: dbURL)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // 💡 ПЕРЕДАЕМ БАЗУ ДАННЫХ В МОСТ ДЛЯ ЧАСОВ
            WatchConnector.shared.modelContext = container.mainContext
            
            return container
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
