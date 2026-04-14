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
    
    // 💡 НОВОЕ: Считаем, сколько вообще денег осталось до ЗП
    private var remainingBudget: Double {
        cycle.totalBudget - totalSpent
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
    
    // 💡 НОВОЕ: Поведенческие подсказки для мотивации
    private var motivationMessage: String {
        if availableToday < 0 {
            return "Ты тратишь деньги из своего завтра 📉"
        } else if progressPercentage >= 75 {
            return "Лимит на исходе. Время притормозить ⚠️"
        } else {
            return "Отличный темп! Продолжай копить 📈"
        }
    }
    
    // MARK: - UI
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Заголовок
                HStack {
                    Text("До зарплаты: \(totalDays - daysPassed) дней")
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
                        amount: "\(Int(availableToday).formatted()) ₸",
                        subtitle: availableToday >= 0 ? "МОЖНО ТРАТИТЬ" : "ПЕРЕРАСХОД",
                        color: statusColor
                    )
                }
                
                // Статус и мотивация
                VStack(spacing: 12) {
                    // Мотивационный текст
                    Text(motivationMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(statusColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    // Реальный остаток денег
                    HStack {
                        Text("Остаток на месяц:")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("\(Int(remainingBudget).formatted()) ₸")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            // Если ушли в минус по всему бюджету - красим в красный
                            .foregroundStyle(remainingBudget < 0 ? .red : .white)
                            .contentTransition(.numericText())
                    }
                }
                
                Spacer()
                
                // Кнопки
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ActionCardView(iconName: "cup.and.saucer.fill", label: "Кофе") { addExpense(2000, "Coffee") }
                    ActionCardView(iconName: "car.fill", label: "Такси") { addExpense(3000, "Taxi") }
                    ActionCardView(iconName: "takeoutbag.and.cup.and.straw.fill", label: "Еда") { addExpense(5000, "Food") }
                    ActionCardView(iconName: "trash.fill", label: "Сброс") { resetCycle() }
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
