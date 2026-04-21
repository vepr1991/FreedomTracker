import SwiftUI
import SwiftData
import WidgetKit

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseTransaction.timestamp, order: .reverse) private var allExpenses: [ExpenseTransaction]
    
    var cycle: BudgetCycle
    
    @State private var showHistory = false
    @State private var showCustomExpense = false
    @State private var showSettings = false
    @State private var showResetConfirmation = false
    @State private var showPaywall = false
    @AppStorage("isPro") private var isPro = false
    
    // Настройки кнопок
    @AppStorage("btn1_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Name = "Кофе"
    @AppStorage("btn1_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Amount = 1000.0
    @AppStorage("btn1_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Icon = "cup.and.saucer.fill"
    
    @AppStorage("btn2_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Name = "Такси"
    @AppStorage("btn2_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Amount = 1500.0
    @AppStorage("btn2_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Icon = "car.fill"
    
    @AppStorage("btn3_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn3Name = "Обед"
    @AppStorage("btn3_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn3Amount = 2500.0
    @AppStorage("btn3_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn3Icon = "bag.fill"

    private var calendar: Calendar { Calendar.current }
    private var currencySymbol: String { Locale.current.currencySymbol ?? "₸" }
    
    // Расчеты
    private var remainingDays: Int {
        let today = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: cycle.endDate)
        let days = calendar.dateComponents([.day], from: today, to: end).day ?? 0
        return max(1, days + 1)
    }
    
    private var spentToday: Double {
        allExpenses.filter { calendar.isDateInToday($0.timestamp) }.reduce(0) { $0 + $1.amount }
    }
    
    private var spentPastDays: Double {
        allExpenses.filter { !calendar.isDateInToday($0.timestamp) && $0.timestamp < calendar.startOfDay(for: Date()) }.reduce(0) { $0 + $1.amount }
    }
    
    private var availableToday: Double {
        let remainBudget = cycle.totalBudget - spentPastDays
        return (remainBudget / Double(remainingDays)) - spentToday
    }
    
    private var dreamEnvelope: Double {
        let totalDays = calendar.dateComponents([.day], from: cycle.startDate, to: cycle.endDate).day ?? 1
        let dailyBase = cycle.totalBudget / Double(max(1, totalDays))
        let passed = calendar.dateComponents([.day], from: cycle.startDate, to: Date()).day ?? 0
        return max(0, (dailyBase * Double(passed)) - spentPastDays)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("День \(max(1, (calendar.dateComponents([.day], from: cycle.startDate, to: Date()).day ?? 0) + 1))")
                            .font(.caption).bold().foregroundStyle(.secondary)
                        Text("До зарплаты: \(remainingDays - 1) дн.").font(.subheadline).bold()
                    }
                    Spacer()
                    Button(action: { if isPro { showSettings = true } else { showPaywall = true } }) {
                        Image(systemName: "gearshape.fill").font(.title3).foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 24).padding(.top, 10)
                
                Spacer()
                
                CircularProgressView(
                    percentage: min(max((spentToday / max(1.0, availableToday + spentToday)) * 100, 0.0), 100.0),
                    amount: "\(Int(availableToday).formatted()) \(currencySymbol)",
                    subtitle: availableToday >= 0 ? "НА СЕГОДНЯ" : "ПЕРЕРАСХОД",
                    color: availableToday >= 0 ? .green : .red
                ).frame(height: 240)
                
                Spacer()
                
                // Копилка
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label((cycle.dreamGoalName ?? "Цель").uppercased(), systemImage: "target")
                            .font(.system(size: 10, weight: .black)).foregroundStyle(.cyan)
                        Spacer()
                        Text("\(Int(dreamEnvelope).formatted()) \(currencySymbol)").bold()
                    }
                    GeometryReader { geo in
                        let target = cycle.dreamGoalPrice ?? 50000.0
                        let ratio = min(dreamEnvelope / max(1.0, target), 1.0)
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.1))
                            Capsule().fill(Color.cyan).frame(width: geo.size.width * ratio)
                        }
                    }.frame(height: 6)
                }
                .padding(20).background(Color.white.opacity(0.05)).cornerRadius(24).padding(.horizontal, 24)
                
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        QuickActionBtn(icon: btn1Icon, label: btn1Name, amount: btn1Amount, symbol: currencySymbol) { addExpense(btn1Amount, btn1Name) }
                        QuickActionBtn(icon: btn2Icon, label: btn2Name, amount: btn2Amount, symbol: currencySymbol) { addExpense(btn2Amount, btn2Name) }
                        QuickActionBtn(icon: btn3Icon, label: btn3Name, amount: btn3Amount, symbol: currencySymbol) { addExpense(btn3Amount, btn3Name) }
                        QuickActionBtn(icon: "plus", label: "Другое", amount: 0, symbol: currencySymbol) { showCustomExpense = true }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
                
                HStack(spacing: 12) {
                    Button(action: { if isPro { showHistory = true } else { showPaywall = true } }) {
                        Label("История", systemImage: "clock.fill")
                            .font(.subheadline).bold()
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.white.opacity(0.12)).cornerRadius(18)
                    }
                    Button(action: { showResetConfirmation = true }) {
                        Label("Очистить", systemImage: "trash.fill")
                            .font(.subheadline).bold()
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.red.opacity(0.1)).cornerRadius(18)
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showHistory) { HistoryView(cycle: cycle).presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showSettings) { SettingsView(cycle: cycle).presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showCustomExpense) { AddCustomExpenseView().presentationDetents([.fraction(0.6)]) }
        .sheet(isPresented: $showPaywall) { PaywallView(isPro: $isPro).presentationDetents([.large]) }
        .confirmationDialog("Сбросить сегодня?", isPresented: $showResetConfirmation) {
            Button("Удалить траты за сегодня", role: .destructive) { resetToday() }
        }
    }
    
    private func addExpense(_ amount: Double, _ name: String) {
        let generator = UIImpactFeedbackGenerator(style: .medium); generator.impactOccurred()
        modelContext.insert(ExpenseTransaction(amount: amount, category: name))
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func resetToday() {
        allExpenses.filter { calendar.isDateInToday($0.timestamp) }.forEach { modelContext.delete($0) }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct QuickActionBtn: View {
    let icon: String
    let label: String
    let amount: Double
    let symbol: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title3).foregroundStyle(.white)
                VStack(spacing: 0) {
                    Text(label).font(.caption2).bold().foregroundStyle(.white)
                    if amount > 0 {
                        Text("\(Int(amount)) \(symbol)")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .frame(width: 95, height: 85)
            .background(Color.white.opacity(0.18))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }.buttonStyle(.plain)
    }
}
