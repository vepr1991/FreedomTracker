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
    
    init() {}
    
    init(amount: Double, category: String) {
        self.amount = amount
        self.category = category
    }
    
    // 💡 Работает в фоновом потоке
    func perform() async throws -> some IntentResult & ProvidesDialog {
        
        // 💡 ИСПРАВЛЕНИЕ: Безопасно забираем контейнер из главного потока,
        // чтобы удовлетворить строгие правила Swift 6.
        let container = await MainActor.run { AppConstants.sharedModelContainer }
        
        guard let container = container else {
            return .result(dialog: "Storage Error.")
        }
        
        // Создаем фоновый контекст и пишем данные без блокировки UI
        let context = ModelContext(container)
        let expense = ExpenseTransaction(amount: amount, category: category)
        context.insert(expense)
        try? context.save()
        
        // Обновляем виджеты
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result(dialog: "Done! Expense added.")
    }
}
