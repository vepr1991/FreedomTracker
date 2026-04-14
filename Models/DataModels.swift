//
//  DataModels.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import Foundation
import SwiftData

// Модель текущего цикла (например, до следующей зарплаты)
@Model
final class BudgetCycle {
    var totalBudget: Double // Сколько всего денег можно потратить (Баланс - Обязательные)
    var startDate: Date     // Дата начала цикла (обычно сегодня)
    var endDate: Date       // Дата окончания (день ЗП)
    
    init(totalBudget: Double, startDate: Date = Date(), endDate: Date) {
        self.totalBudget = totalBudget
        self.startDate = startDate
        self.endDate = endDate
    }
}

// Модель конкретной траты (Кофе, Такси и т.д.)
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
