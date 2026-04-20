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
    
    @AppStorage("isPro") private var isPro = false
    @State private var showPaywall = false
    
    // Синхронизация кнопок
    @AppStorage("btn1_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Name = "Coffee"
    @AppStorage("btn1_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Amount = 5.0
    @AppStorage("btn1_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Icon = "cup.and.saucer.fill"
    
    @AppStorage("btn2_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Name = "Taxi"
    @AppStorage("btn2_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Amount = 15.0
    @AppStorage("btn2_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Icon = "car.fill"

    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }
    private var calendar: Calendar { Calendar.current }
    
    // Фильтрация транзакций
    private var expenses: [ExpenseTransaction] {
        allExpenses.filter { $0.timestamp >= cycle.startDate && $0.timestamp <= cycle.endDate }
    }

    // ЛОГИКА РАСЧЕТА (Решение проблемы №1)
    private var remainingDays: Int {
        let today = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: cycle.endDate)
        let components = calendar.dateComponents([.day], from: today, to: end)
        return max(1, (components.day ?? 0) + 1)
    }

    private var spentPastDays: Double {
        expenses.filter { !calendar.isDateInToday($0.timestamp) && $0.timestamp < calendar.startOfDay(for: Date()) }.reduce(0) { $0 + $1.amount }
    }

    private var spentToday: Double {
        expenses.filter { calendar.isDateInToday($0.timestamp) }.reduce(0) { $0 + $1.amount }
    }

    private var availableToday: Double {
        let remainingBudget = cycle.totalBudget - spentPastDays
        let dailyLimit = remainingBudget / Double(remainingDays)
        return dailyLimit - spentToday
    }

    private var dreamEnvelope: Double {
        let totalDaysCount = calendar.dateComponents([.day], from: cycle.startDate, to: cycle.endDate).day ?? 1
        let dailyBase = cycle.totalBudget / Double(max(1, totalDaysCount))
        let daysPassed = calendar.dateComponents([.day], from: cycle.startDate, to: Date()).day ?? 0
        return max(0, (dailyBase * Double(daysPassed)) - spentPastDays)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day \(max(1, (calendar.dateComponents([.day], from: cycle.startDate, to: Date()).day ?? 0) + 1))")
                            .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                        Text("Payday in \(remainingDays - 1) days")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                    Button(action: { if isPro { showSettings = true } else { showPaywall = true } }) {
                        Image(systemName: "line.3.horizontal.circle.fill").font(.title).foregroundStyle(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 24).padding(.top, 12)
                
                Spacer(minLength: 10)
                
                CircularProgressView(
                    percentage: min(max((spentToday / (availableToday + spentToday)) * 100, 0), 100),
                    amount: "\(currencySymbol)\(Int(availableToday))",
                    subtitle: availableToday >= 0 ? "FOR TODAY" : "OVERSPENT",
                    color: availableToday >= 0 ? .green : .red
                ).frame(height: 260)
                
                Spacer(minLength: 20)
                
                // Копилка
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label((cycle.dreamGoalName ?? "DREAM GOAL").uppercased(), systemImage: "target")
                            .font(.system(size: 10, weight: .black)).foregroundStyle(.cyan)
                        Spacer()
                        Text("\(currencySymbol)\(Int(dreamEnvelope))").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.05)).frame(height: 6)
                            Capsule()
                                .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * min(dreamEnvelope / 500, 1.0), height: 6)
                        }
                    }.frame(height: 6)
                }
                .padding(20).background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.05)))
                .padding(.horizontal, 24)
                
                Spacer(minLength: 20)
                
                // Быстрые кнопки
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        QuickActionBtn(icon: btn1Icon, label: btn1Name, amount: btn1Amount) { addExpense(btn1Amount, btn1Name) }
                        QuickActionBtn(icon: btn2Icon, label: btn2Name, amount: btn2Amount) { addExpense(btn2Amount, btn2Name) }
                        QuickActionBtn(icon: "plus", label: "Other", amount: 0) { showCustomExpense = true }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 16)
                
                // Управление
                HStack(spacing: 16) {
                    Button(action: { if isPro { showHistory = true } else { showPaywall = true } }) {
                        Label("History", systemImage: "list.bullet.rectangle.portrait.fill")
                            .font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.6))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Color.white.opacity(0.05)).clipShape(Capsule())
                    }
                    Button(action: { showResetConfirmation = true }) {
                        Label("Cleanup", systemImage: "trash.fill")
                            .font(.system(size: 12, weight: .bold)).foregroundStyle(.red.opacity(0.8))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Color.red.opacity(0.1)).clipShape(Capsule())
                    }
                    .confirmationDialog("Reset Today?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
                        Button("Delete Today's Expenses", role: .destructive) { resetToday() }
                        Button("Cancel", role: .cancel) {}
                    } message: { Text("This will remove all expenses recorded today.") }
                }
                .padding(.horizontal, 24).padding(.bottom, 34)
            }
        }
        .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
        .sheet(isPresented: $showHistory) { HistoryView(cycle: cycle).presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showSettings) { SettingsView().presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showCustomExpense) { AddCustomExpenseView().presentationDetents([.fraction(0.65)]) }
    }
    
    private func addExpense(_ amount: Double, _ category: String) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        modelContext.insert(ExpenseTransaction(amount: amount, category: category))
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func resetToday() {
        let todayExpenses = expenses.filter { calendar.isDateInToday($0.timestamp) }
        todayExpenses.forEach { modelContext.delete($0) }
        WidgetCenter.shared.reloadAllTimelines()
        WatchConnector.shared.syncLimitToWatch(limit: availableToday)
    }
}

// 💡 QuickActionBtn теперь на правильном уровне (вне DashboardView)
struct QuickActionBtn: View {
    let icon: String; let label: String; let amount: Double; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title3)
                VStack(spacing: 0) {
                    Text(label).font(.caption2).fontWeight(.bold)
                    if amount > 0 { Text("\(Int(amount))").font(.system(size: 10)).opacity(0.6) }
                }
            }
            .frame(width: 80, height: 80).background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain)
    }
}
