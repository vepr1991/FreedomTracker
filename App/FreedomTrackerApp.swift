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
    // Инициализируем наш контейнер с новыми схемами
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Debt.self,
            SavingEvent.self
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
            // Временно ставим ContentView, скоро мы его перепишем
            ContentView()
                // Обязательно применяем темную тему ко всему приложению
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
