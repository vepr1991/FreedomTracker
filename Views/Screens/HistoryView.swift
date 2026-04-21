import SwiftUI
import SwiftData
import WidgetKit

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var expenses: [ExpenseTransaction]
    var cycle: BudgetCycle
    
    init(cycle: BudgetCycle) {
        self.cycle = cycle
        let cycleStart = cycle.startDate
        let cycleEnd = cycle.endDate
        
        let predicate = #Predicate<ExpenseTransaction> {
            $0.timestamp >= cycleStart && $0.timestamp <= cycleEnd
        }
        _expenses = Query(filter: predicate, sort: \.timestamp, order: .reverse)
    }
    
    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea() // 💡 Системный фон
                
                if expenses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundStyle(.primary.opacity(0.2))
                        
                        Text("No expenses yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach(expenses) { expense in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(expense.category)
                                        .font(.headline)
                                        .foregroundStyle(.primary) // 💡 Под цвет темы
                                    
                                    Text(expense.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("-\(currencySymbol)\(Int(expense.amount))")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                            }
                            .listRowBackground(Color.primary.opacity(0.05))
                            .listRowSeparatorTint(.primary.opacity(0.1))
                        }
                        .onDelete(perform: deleteExpense)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(.green)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset Cycle") { resetCycle() }.foregroundStyle(.red)
                }
            }
            // 💡 УДАЛЕН модификатор .preferredColorScheme(.dark), чтобы тема переключалась
        }
    }
    
    private func deleteExpense(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(expenses[index]) }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func resetCycle() {
        for expense in expenses { modelContext.delete(expense) }
        modelContext.delete(cycle)
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
