//
//  DashboardView.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import SwiftUI
import SwiftData
import WidgetKit

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [ExpenseTransaction]
    
    var cycle: BudgetCycle
    
    @State private var showHistory: Bool = false
    @State private var showCustomExpense: Bool = false
    @State private var showSettings: Bool = false // 💡 Вызов экрана настроек
    
    // 💡 Подтягиваем кастомные настройки кнопок
    @AppStorage("btn1_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Name: String = "Coffee"
    @AppStorage("btn1_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Amount: Double = 2000.0
    @AppStorage("btn1_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Icon: String = "cup.and.saucer.fill"
    
    @AppStorage("btn2_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Name: String = "Taxi"
    @AppStorage("btn2_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Amount: Double = 3000.0
    @AppStorage("btn2_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Icon: String = "car.fill"
    
    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }
    
    // MARK: - НОВАЯ МАТЕМАТИКА (Копилка Мечты)
    
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
    
    // 💡 Траты ТОЛЬКО за сегодня
    private var spentToday: Double {
        expenses.filter { Calendar.current.isDateInToday($0.timestamp) }
            .reduce(0) { $0 + $1.amount }
    }
    
    // 💡 Траты за ВСЕ ПРОШЛЫЕ дни (до сегодня)
    private var spentPastDays: Double {
        expenses.filter { !Calendar.current.isDateInToday($0.timestamp) && $0.timestamp < Calendar.current.startOfDay(for: Date()) }
            .reduce(0) { $0 + $1.amount }
    }
    
    // 💡 Жесткий лимит на сегодня (базовый минус сегодняшние траты)
    private var availableToday: Double {
        baseDailyLimit - spentToday
    }
    
    private var totalSpent: Double { spentToday + spentPastDays }
    private var remainingBudget: Double { cycle.totalBudget - totalSpent }
    
    // 💡 Копилка мечты = (Сколько должны были потратить в прошлом) - (Сколько реально потратили в прошлом)
    private var dreamEnvelope: Double {
        let expectedPastSpend = baseDailyLimit * Double(max(0, daysPassed - 1))
        let saved = expectedPastSpend - spentPastDays
        return max(0, saved)
    }
    
    private var progressPercentage: Double {
        guard baseDailyLimit > 0 else { return 0 }
        let progress = (spentToday / baseDailyLimit) * 100
        return min(max(progress, 0), 100)
    }
    
    private var statusColor: Color {
        if availableToday < 0 { return .red }
        else if progressPercentage >= 75 { return .yellow }
        else { return .green }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                HStack {
                    Text("Payday in: \(totalDays - daysPassed) days")
                        .font(.caption)
                        .fontWeight(.medium)
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                
                Spacer()
                
                // Главный круг
                withAnimation {
                    CircularProgressView(
                        percentage: progressPercentage,
                        amount: "\(currencySymbol)\(Int(availableToday).formatted())",
                        subtitle: availableToday >= 0 ? "TODAY'S LIMIT" : "OVERSPENT",
                        color: statusColor
                    )
                }
                
                // Статус
                VStack(spacing: 8) {
                    Text(availableToday >= 0 ? "You're doing great ✨" : "Tomorrow is a new day 🌙")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(statusColor)
                    
                    Text("Total left: \(currencySymbol)\(Int(remainingBudget).formatted())")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
                
                // Плашка "Копилка Мечты"
                if dreamEnvelope > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dream Envelope 🎯")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white.opacity(0.6))
                                .textCase(.uppercase)
                            
                            Text("\(currencySymbol)\(Int(dreamEnvelope).formatted())")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.cyan)
                                .contentTransition(.numericText())
                        }
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(.cyan.opacity(0.8))
                    }
                    .padding()
                    .background(Color.cyan.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
                
                // Кнопки (Теперь динамические)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ActionCardView(iconName: btn1Icon, label: btn1Name) { addExpense(btn1Amount, btn1Name) }
                    ActionCardView(iconName: btn2Icon, label: btn2Name) { addExpense(btn2Amount, btn2Name) }
                    ActionCardView(iconName: "plus", label: "Other") { showCustomExpense = true }
                    ActionCardView(iconName: "list.bullet", label: "History") { showHistory = true }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(cycle: cycle)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showCustomExpense) {
            AddCustomExpenseView()
                .presentationDetents([.fraction(0.65)])
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
        }
    }
    
    private func addExpense(_ amount: Double, _ category: String) {
        let newExpense = ExpenseTransaction(amount: amount, category: category)
        modelContext.insert(newExpense)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
