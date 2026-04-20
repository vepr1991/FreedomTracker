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
    
    @AppStorage("btn1_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Name = "Coffee"
    @AppStorage("btn1_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Amount = 5.0
    @AppStorage("btn1_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Icon = "cup.and.saucer.fill"
    
    @AppStorage("btn2_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Name = "Taxi"
    @AppStorage("btn2_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Amount = 15.0
    @AppStorage("btn2_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Icon = "car.fill"
    
    @AppStorage("btn3_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn3Name = "Lunch"
    @AppStorage("btn3_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn3Amount = 20.0
    @AppStorage("btn3_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn3Icon = "bag.fill"

    private var calendar: Calendar { Calendar.current }
    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }
    
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
                HStack {
                    VStack(alignment: .leading) {
                        Text("Day \(max(1, (calendar.dateComponents([.day], from: cycle.startDate, to: Date()).day ?? 0) + 1))")
                            .font(.caption).bold().foregroundStyle(.secondary)
                        Text("Payday in \(remainingDays - 1) days").font(.subheadline).bold()
                    }
                    Spacer()
                    Button(action: { if isPro { showSettings = true } else { showPaywall = true } }) {
                        Image(systemName: "gearshape.fill").font(.title3).foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 24).padding(.top, 10)
                
                Spacer()
                
                CircularProgressView(
                    percentage: min(max((spentToday / max(1.0, availableToday + spentToday)) * 100, 0), 100),
                    amount: "\(currencySymbol)\(Int(availableToday))",
                    subtitle: availableToday >= 0 ? "FOR TODAY" : "OVERSPENT",
                    color: availableToday >= 0 ? .green : .red
                ).frame(height: 240)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label((cycle.dreamGoalName ?? "Dream").uppercased(), systemImage: "target")
                            .font(.system(size: 10, weight: .black)).foregroundStyle(.cyan)
                        Spacer()
                        Text("\(currencySymbol)\(Int(dreamEnvelope))").bold()
                    }
                    GeometryReader { geo in
                        let target = cycle.dreamGoalPrice ?? 500.0
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
                        // 💡 Исправлено: добавлен аргумент amount
                        QuickActionBtn(icon: btn1Icon, label: btn1Name, amount: btn1Amount) { addExpense(btn1Amount, btn1Name) }
                        QuickActionBtn(icon: btn2Icon, label: btn2Name, amount: btn2Amount) { addExpense(btn2Amount, btn2Name) }
                        QuickActionBtn(icon: btn3Icon, label: btn3Name, amount: btn3Amount) { addExpense(btn3Amount, btn3Name) }
                        QuickActionBtn(icon: "plus", label: "Other", amount: 0) { showCustomExpense = true }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
                
                HStack(spacing: 12) {
                    Button(action: { if isPro { showHistory = true } else { showPaywall = true } }) {
                        Label("History", systemImage: "clock.fill")
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.white.opacity(0.12)).cornerRadius(18)
                    }
                    Button(action: { showResetConfirmation = true }) {
                        Label("Cleanup", systemImage: "trash.fill")
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
        .confirmationDialog("Reset Today?", isPresented: $showResetConfirmation) {
            Button("Delete Today's Spend", role: .destructive) { resetToday() }
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

// 💡 Исправленный и яркий компонент
struct QuickActionBtn: View {
    let icon: String
    let label: String
    let amount: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title3).foregroundStyle(.cyan)
                VStack(spacing: 0) {
                    Text(label).font(.caption2).bold().foregroundStyle(.white)
                    if amount > 0 { Text("$\(Int(amount))").font(.system(size: 10)).opacity(0.6) }
                }
            }
            .frame(width: 95, height: 85)
            .background(Color.white.opacity(0.18)) // 💡 Ярче для первого плана
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }.buttonStyle(.plain)
    }
}
