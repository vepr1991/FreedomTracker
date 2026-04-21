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
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = AppConstants.sharedModelContainer.mainContext
        let expense = ExpenseTransaction(amount: amount, category: category)
        context.insert(expense)
        try? context.save()
        
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result(dialog: "Done! Expense added.")
    }
}
