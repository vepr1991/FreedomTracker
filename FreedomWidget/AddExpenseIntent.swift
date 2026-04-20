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
            
            // 💡 КРИТИЧНО: Обновляем виджеты сразу после записи
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch {
            return .result(dialog: "Error saving expense.")
        }
        
        return .result(dialog: "Done! Expense added.")
    }
}
