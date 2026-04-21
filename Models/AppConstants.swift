import Foundation
import SwiftData

enum AppConstants {
    static let appGroup = "group.com.vladimirkovalenko.FreedomTracker"
    static let dbFileName = "FreedomData.sqlite"
    
    static var appGroupURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Не удалось получить доступ к App Group.")
        }
        return url
    }
    
    static var dbURL: URL {
        appGroupURL.appendingPathComponent(dbFileName)
    }
    
    // 💡 ИСПРАВЛЕНИЕ: Никаких @MainActor или nonisolated(unsafe).
    // ModelContainer сам по себе потокобезопасен (Sendable).
    static let sharedModelContainer: ModelContainer? = {
        let schema = Schema(versionedSchema: FreedomSchemaV1.self)
        let modelConfiguration = ModelConfiguration(schema: schema, url: dbURL)
        
        return try? ModelContainer(for: schema, migrationPlan: FreedomMigrationPlan.self, configurations: [modelConfiguration])
    }()
    
    static var sharedUserDefaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }
}
