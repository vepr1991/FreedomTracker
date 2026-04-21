import SwiftUI
import SwiftData
import WidgetKit

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    // 💡 Фильтруем данные только для текущего цикла
    @Query private var allExpenses: [ExpenseTransaction]
    
    var cycle: BudgetCycle
    
    @State private var showHistory = false
    @State private var showCustomExpense = false
    @State private var showSettings = false
    @State private var showResetConfirmation = false
    @State private var showPaywall = false
    @AppStorage("isPro") private var isPro = false
    
    @AppStorage("quickActions", store: AppConstants.sharedUserDefaults) var quickActionsData = QuickActionsWrapper(items: defaultQuickActions)

    private var calendar: Calendar { Calendar.current }
    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }
    
    // 💡 Инициализатор: настраиваем фильтр базы данных
    init(cycle: BudgetCycle) {
        self.cycle = cycle
        let start = cycle.startDate
        let end = cycle.endDate
        
        let predicate = #Predicate<ExpenseTransaction> {
            $0.timestamp >= start && $0.timestamp <= end
        }
        _allExpenses = Query(filter: predicate, sort: \.timestamp, order: .reverse)
    }
    
    // MARK: - Оптимизированные расчеты
    
    private var remainingDays: Int {
        let today = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: cycle.endDate)
        let days = calendar.dateComponents([.day], from: today, to: end).day ?? 0
        return max(1, days + 1)
    }
    
    private var spentSummary: (today: Double, past: Double) {
        let startOfToday = calendar.startOfDay(for: Date())
        var today = 0.0
        var past = 0.0
        
        for expense in allExpenses {
            if expense.timestamp >= startOfToday {
                today += expense.amount
            } else {
                past += expense.amount
            }
        }
        return (today, past)
    }
    
    private var availableToday: Double {
        let remainBudget = cycle.totalBudget - spentSummary.past
        return (remainBudget / Double(remainingDays)) - spentSummary.today
    }
    
    private var dreamEnvelope: Double {
        let start = calendar.startOfDay(for: cycle.startDate)
        let end = calendar.startOfDay(for: cycle.endDate)
        let today = calendar.startOfDay(for: Date())
        
        let totalDays = max(1, calendar.dateComponents([.day], from: start, to: end).day ?? 1)
        let dailyBase = cycle.totalBudget / Double(totalDays)
        let passedDays = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        
        return max(0, (dailyBase * Double(passedDays)) - spentSummary.past)
    }

    // MARK: - UI
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        let currentDay = max(1, (calendar.dateComponents([.day], from: calendar.startOfDay(for: cycle.startDate), to: calendar.startOfDay(for: Date())).day ?? 0) + 1)
                        
                        Text("Day \(currentDay)")
                            .font(.caption).bold().foregroundStyle(.secondary)
                        Text("Payday in: \(remainingDays - 1) days").font(.subheadline).bold()
                    }
                    Spacer()
                    Button(action: { if isPro { showSettings = true } else { showPaywall = true } }) {
                        Image(systemName: "gearshape.fill").font(.title3).foregroundStyle(.primary.opacity(0.4))
                    }
                }
                .padding(.horizontal, 24).padding(.top, 10)
                
                Spacer()
                
                CircularProgressView(
                    percentage: min(max((spentSummary.today / max(1.0, availableToday + spentSummary.today)) * 100, 0.0), 100.0),
                    amount: "\(Int(availableToday).formatted()) \(currencySymbol)",
                    subtitle: availableToday >= 0 ? "TODAY'S LIMIT" : "OVERSPENT",
                    color: availableToday >= 0 ? .green : .red
                ).frame(height: 240)
                
                Spacer()
                
                // Копилка
                VStack(alignment: .leading, spacing: 10) {
                    // 💡 ИСПРАВЛЕНИЕ ТУТ: Добавлено выравнивание по нижнему краю и сумма цели
                    HStack(alignment: .bottom) {
                        Label((cycle.dreamGoalName ?? "Dream Goal").uppercased(), systemImage: "target")
                            .font(.system(size: 10, weight: .black)).foregroundStyle(.cyan)
                        Spacer()
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(dreamEnvelope).formatted()) \(currencySymbol)")
                                .bold()
                                .foregroundStyle(.primary)
                            
                            if let targetPrice = cycle.dreamGoalPrice, targetPrice > 0 {
                                Text("/ \(Int(targetPrice).formatted()) \(currencySymbol)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    GeometryReader { geo in
                        let target = cycle.dreamGoalPrice ?? 500.0
                        let ratio = min(dreamEnvelope / max(1.0, target), 1.0)
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.primary.opacity(0.1))
                            Capsule().fill(Color.cyan).frame(width: geo.size.width * ratio)
                        }
                    }.frame(height: 6)
                }
                .padding(20).background(Color.primary.opacity(0.05)).cornerRadius(24).padding(.horizontal, 24)
                
                Spacer()
                
                // Скролл с быстрыми кнопками
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(quickActionsData.items) { action in
                            QuickActionBtn(icon: action.icon, label: action.name, amount: action.amount, symbol: currencySymbol) {
                                addExpense(action.amount, action.name)
                            }
                        }
                        QuickActionBtn(icon: "plus", label: "Other", amount: 0, symbol: currencySymbol) { showCustomExpense = true }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
                
                HStack(spacing: 12) {
                    Button(action: { if isPro { showHistory = true } else { showPaywall = true } }) {
                        Label("History", systemImage: "clock.fill")
                            .font(.subheadline).bold()
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.primary.opacity(0.08)).cornerRadius(18)
                    }
                    Button(action: { showResetConfirmation = true }) {
                        Label("Clear", systemImage: "trash.fill")
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
        .confirmationDialog("Clear today?", isPresented: $showResetConfirmation) {
            Button("Delete today's expenses", role: .destructive) { resetToday() }
        }
        .onAppear { syncToWatch() }
        .onChange(of: spentSummary.today) { _, _ in syncToWatch() }
        .onChange(of: quickActionsData.items) { _, _ in syncToWatch() }
    }
    
    // MARK: - Actions
    
    private func syncToWatch() {
        WatchConnector.shared.syncDataToWatch(limit: availableToday, actions: quickActionsData.items)
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
                Image(systemName: icon).font(.title3).foregroundStyle(.primary)
                VStack(spacing: 0) {
                    Text(label).font(.caption2).bold().foregroundStyle(.primary)
                    if amount > 0 {
                        Text("\(Int(amount)) \(symbol)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 95, height: 85)
            .background(Color.primary.opacity(0.08))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        }.buttonStyle(.plain)
    }
}
