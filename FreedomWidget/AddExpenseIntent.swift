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
    
    // 💡 НОВОЕ: Описание (description) и диалог Siri (requestValueDialog)
    @Parameter(
        title: "Сумма",
        description: "Сколько денег было потрачено?",
        requestValueDialog: "Какую сумму записать?"
    )
    var amount: Double
    
    @Parameter(
        title: "Категория",
        description: "На что ушли деньги?",
        requestValueDialog: "На что потратили?"
    )
    var category: String
    
    init() {}
    
    init(amount: Double, category: String) {
        self.amount = amount
        self.category = category
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
            let schema = Schema([BudgetCycle.self, ExpenseTransaction.self])
            
            let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.vladimirkovalenko.FreedomTracker")!
            let dbURL = groupURL.appendingPathComponent("FreedomData.sqlite")
            
            let modelConfiguration = ModelConfiguration(schema: schema, url: dbURL)
            
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                let context = ModelContext(container)
                
                let expense = ExpenseTransaction(amount: amount, category: category)
                context.insert(expense)
                try context.save()
                
            } catch {
                print("Ошибка сохранения виджета/Siri: \(error)")
            }
            
            return .result(dialog: "Готово! Трата записана.")
        }
}
