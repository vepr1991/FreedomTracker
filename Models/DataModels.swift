import Foundation
import SwiftData

@Model
final class BudgetCycle {
    var totalBudget: Double
    var startDate: Date
    var endDate: Date
    var dreamGoalName: String?
    var dreamGoalPrice: Double? // 💡 Поле для цены цели
    
    init(totalBudget: Double, startDate: Date = Date(), endDate: Date, dreamGoalName: String? = "New Gadget", dreamGoalPrice: Double? = 500.0) {
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
