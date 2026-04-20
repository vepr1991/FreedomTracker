//
//  DashboardView.swift
//  FreedomTracker
//

import SwiftUI
import SwiftData
import WidgetKit

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseTransaction.timestamp, order: .reverse) private var expenses: [ExpenseTransaction]
    var cycle: BudgetCycle
    
    @State private var showHistory: Bool = false
    @State private var showCustomExpense: Bool = false
    @State private var showSettings: Bool = false
    @AppStorage("isPro") private var isPro: Bool = false
    @State private var showPaywall: Bool = false
    
    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }
    
    // --- РАСЧЕТЫ ---
    private var totalDays: Int {
        let components = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: cycle.startDate), to: Calendar.current.startOfDay(for: cycle.endDate))
        return max(1, (components.day ?? 0) + 1)
    }
    private var daysPassed: Int {
        let components = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: cycle.startDate), to: Calendar.current.startOfDay(for: Date()))
        return max(1, (components.day ?? 0) + 1)
    }
    private var baseDailyLimit: Double { cycle.totalBudget / Double(totalDays) }
    private var spentToday: Double { expenses.filter { Calendar.current.isDateInToday($0.timestamp) }.reduce(0) { $0 + $1.amount } }
    private var spentPastDays: Double { expenses.filter { !Calendar.current.isDateInToday($0.timestamp) && $0.timestamp < Calendar.current.startOfDay(for: Date()) }.reduce(0) { $0 + $1.amount } }
    private var availableToday: Double { baseDailyLimit - spentToday }
    private var dreamEnvelope: Double {
        let expectedPastSpend = baseDailyLimit * Double(max(0, daysPassed - 1))
        return max(0, expectedPastSpend - spentPastDays)
    }
    
    private var statusColor: Color {
        if availableToday < 0 { return .red }
        else if (spentToday / baseDailyLimit) >= 0.8 { return .yellow }
        else { return .green }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day \(daysPassed) of \(totalDays)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("Payday in \(totalDays - daysPassed) days")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                    Button(action: { if isPro { showSettings = true } else { showPaywall = true } }) {
                        Image(systemName: "line.3.horizontal.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                
                Spacer(minLength: 10)
                
                // Кольцо прогресса
                CircularProgressView(
                    percentage: min(max((spentToday / baseDailyLimit) * 100, 0), 100),
                    amount: "\(currencySymbol)\(Int(availableToday).formatted())",
                    subtitle: availableToday >= 0 ? "FOR TODAY" : "OVERSPENT",
                    color: statusColor
                )
                .frame(height: 260)
                
                Text(availableToday > 0 ? "Save today to have \(currencySymbol)\(Int(baseDailyLimit + availableToday)) tomorrow" : "Resetting limits tomorrow 🌙")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 12)
                
                Spacer(minLength: 20)
                
                // Визуальная Копилка
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label((cycle.dreamGoalName ?? "Dream Goal").uppercased(), systemImage: "target")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.cyan)
                        Spacer()
                        Text("\(currencySymbol)\(Int(dreamEnvelope))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.05)).frame(height: 6)
                        Capsule()
                            .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 100, height: 6)
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.cyan.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, 24)
                
                Spacer(minLength: 20)
                
                // Быстрые кнопки трат
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        QuickActionBtn(icon: "cup.and.saucer.fill", label: "Coffee", amount: 2000) { addExpense(2000, "Coffee") }
                        QuickActionBtn(icon: "car.fill", label: "Taxi", amount: 3000) { addExpense(3000, "Taxi") }
                        QuickActionBtn(icon: "bag.fill", label: "Lunch", amount: 5000) { addExpense(5000, "Lunch") }
                        QuickActionBtn(icon: "ellipsis.circle.fill", label: "Other", amount: 0) { showCustomExpense = true }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 16)
                
                // Кнопки управления (История и Очистка)
                HStack(spacing: 16) {
                    Button(action: { if isPro { showHistory = true } else { showPaywall = true } }) {
                        Label("History", systemImage: "list.bullet.rectangle.portrait.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Capsule())
                    }
                    
                    Button(action: { resetToday() }) {
                        Label("Cleanup", systemImage: "trash.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.red.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
        }
        .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
        .sheet(isPresented: $showHistory) { HistoryView(cycle: cycle).presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showCustomExpense) { AddCustomExpenseView().presentationDetents([.fraction(0.65)]) }
        .sheet(isPresented: $showSettings) { SettingsView().presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showPaywall) { PaywallView(isPro: $isPro).presentationDetents([.large]) }
        .onChange(of: availableToday) { oldValue, newValue in
            WatchConnector.shared.syncLimitToWatch(limit: newValue)
        }
    }
    
    private func addExpense(_ amount: Double, _ category: String) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let newExpense = ExpenseTransaction(amount: amount, category: category)
        modelContext.insert(newExpense)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func resetToday() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        let todayExpenses = expenses.filter { Calendar.current.isDateInToday($0.timestamp) }
        for expense in todayExpenses {
            modelContext.delete(expense)
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        WatchConnector.shared.syncLimitToWatch(limit: baseDailyLimit)
    }
}

// Вспомогательный компонент (вынесен за пределы DashboardView)
struct QuickActionBtn: View {
    let icon: String
    let label: String
    let amount: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title3)
                VStack(spacing: 0) {
                    Text(label).font(.caption2).fontWeight(.bold)
                    if amount > 0 { Text("\(Int(amount))").font(.system(size: 10)).opacity(0.6) }
                }
            }
            .frame(width: 80, height: 80)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
