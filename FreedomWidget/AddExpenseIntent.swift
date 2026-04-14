//
//  AddExpenseIntent.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import AppIntents
import SwiftData
import Foundation

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Добавить трату"
    
    // Эти параметры мы будем передавать прямо с виджета
    @Parameter(title: "Сумма")
    var amount: Double
    
    @Parameter(title: "Категория")
    var category: String
    
    // Обязательный пустой инициализатор для системы
    init() {}
    
    init(amount: Double, category: String) {
        self.amount = amount
        self.category = category
    }
    
    // Эта функция срабатывает в фоне при нажатии на виджет
    func perform() async throws -> some IntentResult {
        // Указываем наши модели
        let schema = Schema([BudgetCycle.self, ExpenseTransaction.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            // Подключаемся к базе напрямую из фона
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = ModelContext(container)
            
            // Создаем и сохраняем новую транзакцию
            let expense = ExpenseTransaction(amount: amount, category: category)
            context.insert(expense)
            try context.save()
            
        } catch {
            print("Ошибка сохранения виджета: \(error)")
        }
        
        return .result()
    }
}
