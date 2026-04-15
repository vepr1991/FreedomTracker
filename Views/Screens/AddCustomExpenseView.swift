//
//  AddCustomExpenseView.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import SwiftUI
import SwiftData
import WidgetKit

struct AddCustomExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount: String = ""
    @State private var category: String = ""
    
    private var currencySymbol: String {
        Locale.current.currencySymbol ?? "$"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Поле суммы
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                        
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .onChange(of: amount) { oldValue, newValue in
                                // Форматируем пробелы на лету
                                let cleanString = newValue.filter { "0123456789".contains($0) }
                                if let number = Int(cleanString) {
                                    let formatter = NumberFormatter()
                                    formatter.numberStyle = .decimal
                                    amount = formatter.string(from: NSNumber(value: number)) ?? ""
                                } else {
                                    amount = ""
                                }
                            }
                    }
                    
                    // Поле категории
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What did you buy?")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                        
                        TextField("e.g. Groceries, Shoes...", text: $category)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Spacer()
                    
                    // Кнопка сохранения
                    Button(action: saveExpense) {
                        Text("ADD EXPENSE")
                            .font(.headline)
                            .foregroundStyle(.black)
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
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private func saveExpense() {
        let cleanString = amount.filter { "0123456789".contains($0) }
        guard let finalAmount = Double(cleanString) else { return }
        
        let newExpense = ExpenseTransaction(amount: finalAmount, category: category)
        modelContext.insert(newExpense)
        
        // Стучимся в виджет, чтобы он обновил лимит
        WidgetCenter.shared.reloadAllTimelines()
        
        dismiss()
    }
}
