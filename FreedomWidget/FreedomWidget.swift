//
//  FreedomWidget.swift
//  FreedomWidget
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// 1. Провайдер данных
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), availableLimit: 10000)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), availableLimit: 10000)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var availableToday: Double = 0
        
        let schema = Schema([BudgetCycle.self, ExpenseTransaction.self])
        
        // Подключаемся к общей базе App Group
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.vladimirkovalenko.FreedomTracker")!
        let dbURL = groupURL.appendingPathComponent("FreedomData.sqlite")
        
        let modelConfiguration = ModelConfiguration(schema: schema, url: dbURL)
        
        if let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) {
            let context = ModelContext(container)

            let cycleDescriptor = FetchDescriptor<BudgetCycle>()
            let expenseDescriptor = FetchDescriptor<ExpenseTransaction>()
            
            if let cycles = try? context.fetch(cycleDescriptor), let activeCycle = cycles.first,
               let expenses = try? context.fetch(expenseDescriptor) {
                
                let totalDays = max(1, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: activeCycle.startDate), to: Calendar.current.startOfDay(for: activeCycle.endDate)).day! + 1)
                let daysPassed = max(1, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: activeCycle.startDate), to: Calendar.current.startOfDay(for: Date())).day! + 1)
                
                let baseDailyLimit = activeCycle.totalBudget / Double(totalDays)
                let accumulatedLimit = baseDailyLimit * Double(daysPassed)
                let totalSpent = expenses.reduce(0) { $0 + $1.amount }
                
                availableToday = accumulatedLimit - totalSpent
            }
        }
        
        let entry = SimpleEntry(date: Date(), availableLimit: availableToday)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// 2. Модель данных
struct SimpleEntry: TimelineEntry {
    let date: Date
    let availableLimit: Double
}

// 3. Дизайн виджета
struct FreedomWidgetEntryView : View {
    var entry: Provider.Entry
    
    // Читаем, где именно установлен виджет
    @Environment(\.widgetFamily) var family
    
    // Динамическая валюта системы
    private var currencySymbol: String {
        Locale.current.currencySymbol ?? "$"
    }

    var body: some View {
        switch family {
        case .accessoryRectangular:
            // 🔒 ДИЗАЙН ДЛЯ ЭКРАНА БЛОКИРОВКИ (Максимально крупный)
            HStack(alignment: .center) {
                // Баланс слева
                VStack(alignment: .leading, spacing: 2) {
                    Text("ALLOWANCE")
                        .font(.system(size: 10, weight: .bold))
                        .opacity(0.6)
                    
                    Text("\(currencySymbol)\(Int(entry.availableLimit))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .widgetAccentable() // iOS сама покрасит текст под стиль часов пользователя
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 4)
                
                // Крупные кнопки справа
                HStack(spacing: 12) {
                    Button(intent: AddExpenseIntent(amount: 2000, category: "Coffee")) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 22))
                            .frame(width: 44, height: 44) // Большая зона нажатия
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(intent: AddExpenseIntent(amount: 3000, category: "Taxi")) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 22))
                            .frame(width: 44, height: 44) // Большая зона нажатия
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            
        default:
            // 📱 ДИЗАЙН ДЛЯ РАБОЧЕГО СТОЛА
            VStack(spacing: 12) {
                Text("\(currencySymbol)\(Int(entry.availableLimit))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.availableLimit < 0 ? .red : .green)
                    .contentTransition(.numericText())
                
                HStack(spacing: 20) {
                    Button(intent: AddExpenseIntent(amount: 2000, category: "Coffee")) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(intent: AddExpenseIntent(amount: 3000, category: "Taxi")) {
                        Image(systemName: "car.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .containerBackground(.black, for: .widget)
        }
    }
}

// 4. Настройка самого виджета
struct FreedomWidget: Widget {
    let kind: String = "FreedomWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FreedomWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Spendable")
        .description("Quick expenses and daily limit.")
        // Поддержка локскрина и обычных виджетов
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
