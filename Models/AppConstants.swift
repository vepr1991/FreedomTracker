//
//  AppConstants.swift
//  FreedomTracker
//

import Foundation
import SwiftData

enum AppConstants {
    // Единый идентификатор группы для шаринга данных
    static let appGroup = "group.com.vladimirkovalenko.FreedomTracker"
    static let dbFileName = "FreedomData.sqlite"
    
    static var appGroupURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Не удалось получить доступ к App Group. Проверьте App Groups Capability.")
        }
        return url
    }
    
    static var dbURL: URL {
        appGroupURL.appendingPathComponent(dbFileName)
    }
    
    // Единый Shared Container для всего приложения, виджета и Intent'ов
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([BudgetCycle.self, ExpenseTransaction.self])
        let modelConfiguration = ModelConfiguration(schema: schema, url: dbURL)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // Единый UserDefaults для хранения настроек (иконок, названий кнопок)
    static var sharedUserDefaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }
}
