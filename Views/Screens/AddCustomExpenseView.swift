import SwiftUI
import SwiftData
import WidgetKit

struct AddCustomExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount: String = ""
    @State private var category: String = ""
    
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
    
    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea() // 💡 Адаптивный фон
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary) // 💡 Адаптивный
                            .padding()
                            .background(Color.primary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .onChange(of: amount) { oldValue, newValue in
                                let cleanString = newValue.filter { "0123456789".contains($0) }
                                if let number = Int(cleanString) {
                                    amount = Self.formatter.string(from: NSNumber(value: number)) ?? ""
                                } else { amount = "" }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What did you buy?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("e.g. Groceries, Shoes...", text: $category)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding()
                            .background(Color.primary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Spacer()
                    
                    Button(action: saveExpense) {
                        Text("ADD EXPENSE")
                            .font(.headline)
                            .foregroundStyle(.black) // Черный на зеленом всегда читается
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(amount.isEmpty || category.isEmpty)
                    .opacity((amount.isEmpty || category.isEmpty) ? 0.5 : 1)
                }
                .padding(24)
            }
            .navigationTitle("Custom Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }.foregroundStyle(.secondary)
                }
            }
            // 💡 УДАЛЕН модификатор .preferredColorScheme(.dark)
        }
    }
    
    private func saveExpense() {
        let cleanString = amount.filter { "0123456789".contains($0) }
        guard let finalAmount = Double(cleanString) else { return }
        
        let newExpense = ExpenseTransaction(amount: finalAmount, category: category)
        modelContext.insert(newExpense)
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
