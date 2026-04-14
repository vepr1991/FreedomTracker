//
//  HistoryView.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import SwiftUI
import SwiftData
import WidgetKit

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \ExpenseTransaction.timestamp, order: .reverse) private var expenses: [ExpenseTransaction]
    
    var cycle: BudgetCycle
    
    private var currencySymbol: String {
        Locale.current.currencySymbol ?? "$"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if expenses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.2))
                        
                        Text("No expenses yet")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                } else {
                    List {
                        ForEach(expenses) { expense in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(expense.category)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    
                                    Text(expense.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                
                                Spacer()
                                
                                Text("-\(currencySymbol)\(Int(expense.amount))")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                            .listRowSeparatorTint(.white.opacity(0.1))
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
                    Button("Done") { dismiss() }
                        .foregroundStyle(.green)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset Cycle") { resetCycle() }
                        .foregroundStyle(.red)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Действия
    
    private func deleteExpense(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(expenses[index])
        }
        // Обновляем виджет после удаления траты
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func resetCycle() {
        for expense in expenses { modelContext.delete(expense) }
        modelContext.delete(cycle)
        
        // Обновляем виджет при сбросе цикла
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
