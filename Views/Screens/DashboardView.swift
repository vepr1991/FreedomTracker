//
//  DashboardView.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [ExpenseTransaction]
    
    var cycle: BudgetCycle
    
    private var currencySymbol: String {
        Locale.current.currencySymbol ?? "$"
    }
    
    // MARK: - Математика лимитов
    
    private var totalDays: Int {
        let components = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: cycle.startDate), to: Calendar.current.startOfDay(for: cycle.endDate))
        return max(1, (components.day ?? 0) + 1)
    }
    
    private var daysPassed: Int {
        let components = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: cycle.startDate), to: Calendar.current.startOfDay(for: Date()))
        return max(1, (components.day ?? 0) + 1)
    }
    
    private var baseDailyLimit: Double {
        cycle.totalBudget / Double(totalDays)
    }
    
    private var accumulatedLimit: Double {
        baseDailyLimit * Double(daysPassed)
    }
    
    private var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var availableToday: Double {
        accumulatedLimit - totalSpent
    }
    
    private var remainingBudget: Double {
        cycle.totalBudget - totalSpent
    }
    
    // 💡 НОВОЕ: Считаем сэкономленные деньги (всё, что накопилось с прошлых дней)
    private var savedAmount: Double {
        let saved = availableToday - baseDailyLimit
        return max(0, saved)
    }
    
    private var progressPercentage: Double {
        guard accumulatedLimit > 0 else { return 0 }
        let progress = (totalSpent / accumulatedLimit) * 100
        return min(max(progress, 0), 100)
    }
    
    private var statusColor: Color {
        if availableToday < 0 {
            return .red
        } else if progressPercentage >= 75 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private var motivationMessage: String {
        if availableToday < 0 {
            return "You are spending from tomorrow 📉"
        } else if progressPercentage >= 75 {
            return "Limit is almost reached. Slow down ⚠️"
        } else {
            return "Great pace! Keep saving 📈"
        }
    }
    
    // MARK: - UI
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Заголовок
                HStack {
                    Text("Payday in: \(totalDays - daysPassed) days")
                        .font(.caption)
                        .fontWeight(.medium)
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                
                Spacer()
                
                // Главный круг
                withAnimation {
                    CircularProgressView(
                        percentage: progressPercentage,
                        amount: "\(currencySymbol)\(Int(availableToday).formatted())",
                        subtitle: availableToday >= 0 ? "SPENDABLE" : "OVERSPENT",
                        color: statusColor
                    )
                }
                
                // Статус и мотивация
                VStack(spacing: 12) {
                    Text(motivationMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(statusColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    HStack {
                        Text("Monthly balance:")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("\(currencySymbol)\(Int(remainingBudget).formatted())")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(remainingBudget < 0 ? .red : .white)
                            .contentTransition(.numericText())
                    }
                }
                
                // 💡 НОВОЕ: Плашка "Сэкономлено" (Появляется только если есть сбережения)
                if savedAmount > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Saved for the dream 🏎️")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.6))
                                .textCase(.uppercase)
                            
                            Text("\(currencySymbol)\(Int(savedAmount).formatted())")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                                .contentTransition(.numericText())
                        }
                        
                        Spacer()
                        
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                            .shadow(color: .yellow.opacity(0.5), radius: 5)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    // Легкая анимация появления плашки
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
                
                // Кнопки
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ActionCardView(iconName: "cup.and.saucer.fill", label: "Coffee") { addExpense(2000, "Coffee") }
                    ActionCardView(iconName: "car.fill", label: "Taxi") { addExpense(3000, "Taxi") }
                    ActionCardView(iconName: "takeoutbag.and.cup.and.straw.fill", label: "Food") { addExpense(5000, "Food") }
                    ActionCardView(iconName: "trash.fill", label: "Reset") { resetCycle() }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Действия
    
    private func addExpense(_ amount: Double, _ category: String) {
        let newExpense = ExpenseTransaction(amount: amount, category: category)
        modelContext.insert(newExpense)
    }
    
    private func resetCycle() {
        for expense in expenses { modelContext.delete(expense) }
        modelContext.delete(cycle)
    }
}
