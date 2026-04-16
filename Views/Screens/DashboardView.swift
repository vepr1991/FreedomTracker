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
    @State private var showSettings: Bool = false
    
    @AppStorage("isPro") private var isPro: Bool = false
    @State private var showPaywall: Bool = false
    
    @AppStorage("btn1_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Name: String = "Coffee"
    @AppStorage("btn1_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Amount: Double = 2000.0
    @AppStorage("btn1_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Icon: String = "cup.and.saucer.fill"
    
    @AppStorage("btn2_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Name: String = "Taxi"
    @AppStorage("btn2_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Amount: Double = 3000.0
    @AppStorage("btn2_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Icon: String = "car.fill"
    
    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }
    
    private var totalDays: Int {
        let components = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: cycle.startDate), to: Calendar.current.startOfDay(for: cycle.endDate))
        return max(1, (components.day ?? 0) + 1)
    }
    
    private var daysPassed: Int {
        let components = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: cycle.startDate), to: Calendar.current.startOfDay(for: Date()))
        return max(1, (components.day ?? 0) + 1)
    }
    
    private var baseDailyLimit: Double { cycle.totalBudget / Double(totalDays) }
    
    private var spentToday: Double {
        expenses.filter { Calendar.current.isDateInToday($0.timestamp) }.reduce(0) { $0 + $1.amount }
    }
    
    private var spentPastDays: Double {
        expenses.filter { !Calendar.current.isDateInToday($0.timestamp) && $0.timestamp < Calendar.current.startOfDay(for: Date()) }.reduce(0) { $0 + $1.amount }
    }
    
    private var availableToday: Double { baseDailyLimit - spentToday }
    private var totalSpent: Double { spentToday + spentPastDays }
    private var remainingBudget: Double { cycle.totalBudget - totalSpent }
    
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
        else if progressPercentage >= 80 { return .yellow }
        else { return .green }
    }
    
    private var dynamicGreeting: LocalizedStringKey {
        if availableToday < 0 {
            return "Overspent, but tomorrow is a new day 🌙"
        } else if spentToday == 0 {
            return "A fresh start! You have your full limit ✨"
        } else if progressPercentage >= 80 {
            return "Careful, you're close to your limit ⚠️"
        } else {
            let hour = Calendar.current.component(.hour, from: Date())
            if hour < 12 {
                return "Good morning! Stay on budget ☀️"
            } else if hour < 18 {
                return "Doing great this afternoon ✨"
            } else {
                return "Evening is here, keep it up 🌙"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Payday in: \(totalDays - daysPassed) days")
                        .font(.caption)
                        .fontWeight(.medium)
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Button(action: {
                        if isPro { showSettings = true } else { showPaywall = true }
                    }) {
                        Image(systemName: "gearshape.fill").font(.title3).foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                
                Spacer()
                
                // Главный круг
                CircularProgressView(
                    percentage: progressPercentage,
                    amount: "\(currencySymbol)\(Int(availableToday).formatted())",
                    subtitle: availableToday >= 0 ? LocalizedStringKey("TODAY'S LIMIT") : LocalizedStringKey("OVERSPENT"),
                    color: statusColor
                )
                .animation(.easeInOut(duration: 0.5), value: progressPercentage)
                
                // Динамический статус с защитой от скачков
                VStack(spacing: 8) {
                    Text(dynamicGreeting)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(statusColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Total left: \(currencySymbol)\(Int(remainingBudget).formatted())")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(minHeight: 50)
                
                // Плашка "Копилка Мечты" всегда на экране
                VStack {
                    if dreamEnvelope > 0 {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Dream Envelope 🎯")
                                    .font(.caption).fontWeight(.bold).foregroundStyle(.white.opacity(0.6)).textCase(.uppercase)
                                Text("\(currencySymbol)\(Int(dreamEnvelope).formatted())")
                                    .font(.title3).fontWeight(.bold).foregroundStyle(.cyan).contentTransition(.numericText())
                            }
                            Spacer()
                            Image(systemName: "star.fill").font(.title2).foregroundStyle(.cyan.opacity(0.8))
                        }
                        .padding()
                        .background(Color.cyan.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                    } else {
                        // Состояние "Закрыто/Пусто"
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Dream Envelope 🎯")
                                    .font(.caption).fontWeight(.bold).foregroundStyle(.white.opacity(0.3)).textCase(.uppercase)
                                Text("Save today to unlock")
                                    .font(.subheadline).foregroundStyle(.white.opacity(0.3))
                            }
                            Spacer()
                            Image(systemName: "lock.fill").font(.title2).foregroundStyle(.white.opacity(0.1))
                        }
                        .padding()
                        .background(Color.white.opacity(0.02))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
                    }
                }
                .frame(height: 76)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Кнопки
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ActionCardView(iconName: btn1Icon, label: LocalizedStringKey(btn1Name)) { addExpense(btn1Amount, btn1Name) }
                    ActionCardView(iconName: btn2Icon, label: LocalizedStringKey(btn2Name)) { addExpense(btn2Amount, btn2Name) }
                    ActionCardView(iconName: "plus", label: "Other") { showCustomExpense = true }
                    ActionCardView(iconName: "list.bullet", label: "History") {
                        if isPro { showHistory = true } else { showPaywall = true }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showHistory) { HistoryView(cycle: cycle).presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showCustomExpense) { AddCustomExpenseView().presentationDetents([.fraction(0.65)]) }
        .sheet(isPresented: $showSettings) { SettingsView().presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showPaywall) { PaywallView(isPro: $isPro).presentationDetents([.large]) }
        // 💡 ОТПРАВЛЯЕМ ЛИМИТ НА ЧАСЫ ПРИ ИЗМЕНЕНИИ И ЗАПУСКЕ
        .onChange(of: availableToday) { oldValue, newValue in
            WatchConnector.shared.syncLimitToWatch(limit: newValue)
        }
        .onAppear {
            WatchConnector.shared.syncLimitToWatch(limit: availableToday)
        }
    }
    
    private func addExpense(_ amount: Double, _ category: String) {
        let newExpense = ExpenseTransaction(amount: amount, category: category)
        modelContext.insert(newExpense)
        WidgetCenter.shared.reloadAllTimelines()
        // При добавлении траты лимит пересчитается, и .onChange сам отправит новую цифру на часы!
    }
}
