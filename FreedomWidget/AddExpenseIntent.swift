//
//  AddExpenseIntent.swift
//  FreedomWidget
//

import AppIntents
import SwiftData
import Foundation
import WidgetKit

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    
    @Parameter(title: "Amount")
    var amount: Double
    
    @Parameter(title: "Category")
    var category: String
    
    // Обязательный пустой инициализатор для системы
    init() {}
    
    // Инициализатор для использования в коде (кнопки виджета)
    init(amount: Double, category: String) {
        self.amount = amount
        self.category = category
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Создаем контекст из нашего общего контейнера
        let context = ModelContext(AppConstants.sharedModelContainer)
        
        let expense = ExpenseTransaction(amount: amount, category: category)
        context.insert(expense)
        try? context.save()
        
        // КРИТИЧНО: Обновляем виджеты сразу после записи
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result(dialog: "Done! Expense added.")
    }
}
