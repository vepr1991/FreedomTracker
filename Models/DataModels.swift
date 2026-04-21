import Foundation
import SwiftData

// MARK: - Версионирование базы данных (Защита данных пользователей)
enum FreedomSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [BudgetCycle.self, ExpenseTransaction.self] }
}

enum FreedomMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [FreedomSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

@Model
final class BudgetCycle {
    var totalBudget: Double
    var startDate: Date
    var endDate: Date
    var dreamGoalName: String?
    var dreamGoalPrice: Double?
    
    init(totalBudget: Double, startDate: Date = Date(), endDate: Date, dreamGoalName: String? = "New Goal", dreamGoalPrice: Double? = 500.0) {
        self.totalBudget = totalBudget
        self.startDate = startDate
        self.endDate = endDate
        self.dreamGoalName = dreamGoalName
        self.dreamGoalPrice = dreamGoalPrice
    }
}

@Model
final class ExpenseTransaction {
    var amount: Double
    var category: String
    var timestamp: Date
    
    init(amount: Double, category: String, timestamp: Date = Date()) {
        self.amount = amount
        self.category = category
        self.timestamp = timestamp
    }
}

// MARK: - Динамические кнопки (Quick Actions)
struct QuickAction: Codable, Identifiable, Hashable {
    let id: UUID // 💡 ИСПРАВЛЕНИЕ: let вместо var, чтобы UUID не пересоздавался
    var name: String
    var amount: Double
    var icon: String
    
    init(id: UUID = UUID(), name: String, amount: Double, icon: String) {
        self.id = id
        self.name = name
        self.amount = amount
        self.icon = icon
    }
}

struct QuickActionsWrapper: RawRepresentable {
    var items: [QuickAction]
    
    init(items: [QuickAction]) {
        self.items = items
    }
    
    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([QuickAction].self, from: data) else {
            return nil
        }
        self.items = result
    }
    
    var rawValue: String {
        guard let data = try? JSONEncoder().encode(items),
              let result = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return result
    }
}

let defaultQuickActions: [QuickAction] = [
    QuickAction(name: "Coffee", amount: 5.0, icon: "cup.and.saucer.fill"),
    QuickAction(name: "Taxi", amount: 15.0, icon: "car.fill"),
    QuickAction(name: "Lunch", amount: 25.0, icon: "bag.fill")
]
