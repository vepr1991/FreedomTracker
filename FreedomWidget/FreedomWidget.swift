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
                
                // 💡 НОВАЯ МАТЕМАТИКА ВИДЖЕТА
                let totalDays = max(1, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: activeCycle.startDate), to: Calendar.current.startOfDay(for: activeCycle.endDate)).day! + 1)
                
                let baseDailyLimit = activeCycle.totalBudget / Double(totalDays)
                
                // Берем траты только за сегодняшний день
                let spentToday = expenses
                    .filter { Calendar.current.isDateInToday($0.timestamp) }
                    .reduce(0) { $0 + $1.amount }
                
                availableToday = baseDailyLimit - spentToday
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
    
    @Environment(\.widgetFamily) var family
    
    // Подтягиваем настройки из App Group
    @AppStorage("btn1_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Name: String = "Coffee"
    @AppStorage("btn1_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Amount: Double = 2000.0
    @AppStorage("btn1_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Icon: String = "cup.and.saucer.fill"
    
    @AppStorage("btn2_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Name: String = "Taxi"
    @AppStorage("btn2_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Amount: Double = 3000.0
    @AppStorage("btn2_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Icon: String = "car.fill"
    
    private var currencySymbol: String {
        Locale.current.currencySymbol ?? "$"
    }

    var body: some View {
        switch family {
        case .accessoryRectangular:
            // 🔒 Экран блокировки
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ALLOWANCE")
                        .font(.system(size: 10, weight: .bold))
                        .opacity(0.6)
                    
                    Text("\(currencySymbol)\(Int(entry.availableLimit))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .widgetAccentable()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 4)
                
                HStack(spacing: 12) {
                    Button(intent: AddExpenseIntent(amount: btn1Amount, category: btn1Name)) {
                        Image(systemName: btn1Icon)
                            .font(.system(size: 22))
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(intent: AddExpenseIntent(amount: btn2Amount, category: btn2Name)) {
                        Image(systemName: btn2Icon)
                            .font(.system(size: 22))
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            
        default:
            // 📱 Рабочий стол
            VStack(spacing: 12) {
                Text("\(currencySymbol)\(Int(entry.availableLimit))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.availableLimit < 0 ? .red : .green)
                    .contentTransition(.numericText())
                
                HStack(spacing: 20) {
                    Button(intent: AddExpenseIntent(amount: btn1Amount, category: btn1Name)) {
                        Image(systemName: btn1Icon)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(intent: AddExpenseIntent(amount: btn2Amount, category: btn2Name)) {
                        Image(systemName: btn2Icon)
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
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
