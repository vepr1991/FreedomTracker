//
//  DataModels.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import Foundation
import SwiftData

// Модель самого Долга/Цели
@Model
final class Debt {
    var title: String
    var totalAmount: Double
    var remainingAmount: Double
    var dailyCost: Double // Стоимость одного дня (Платеж / 30)
    var targetDate: Date
    
    init(title: String = "Debt to Nikita", totalAmount: Double, monthlyPayment: Double, targetDate: Date) {
        self.title = title
        self.totalAmount = totalAmount
        self.remainingAmount = totalAmount
        self.dailyCost = monthlyPayment / 30.4
        self.targetDate = targetDate
    }
}

// Модель отдельной "Победы" (Сэкономленной транзакции)
@Model
final class SavingEvent {
    var amount: Double
    var category: String
    var timestamp: Date
    
    init(amount: Double, category: String, timestamp: Date = Date()) {
        self.amount = amount
        self.category = category
        self.timestamp = timestamp
    }
}
