//
//  FreedomWidget.swift
//  FreedomWidget
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
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.vladimirkovalenko.FreedomTracker")!
        let dbURL = groupURL.appendingPathComponent("FreedomData.sqlite")
        let modelConfiguration = ModelConfiguration(schema: schema, url: dbURL)
        
        if let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) {
            let context = ModelContext(container)

            // 💡 ОПТИМИЗАЦИЯ 1: Берем только последний цикл, а не все
            var cycleDescriptor = FetchDescriptor<BudgetCycle>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
            cycleDescriptor.fetchLimit = 1
            
            if let cycles = try? context.fetch(cycleDescriptor), let activeCycle = cycles.first {
                let calendar = Calendar.current
                let totalDays = max(1, calendar.dateComponents([.day], from: calendar.startOfDay(for: activeCycle.startDate), to: calendar.startOfDay(for: activeCycle.endDate)).day! + 1)
                let baseDailyLimit = activeCycle.totalBudget / Double(totalDays)
                
                // 💡 ОПТИМИЗАЦИЯ 2: Просим базу дать расходы ТОЛЬКО за сегодня
                let startOfToday = calendar.startOfDay(for: Date())
                guard let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) else { return }
                
                let todayPredicate = #Predicate<ExpenseTransaction> {
                    $0.timestamp >= startOfToday && $0.timestamp < endOfToday
                }
                let expenseDescriptor = FetchDescriptor<ExpenseTransaction>(predicate: todayPredicate)
                
                if let todayExpenses = try? context.fetch(expenseDescriptor) {
                    let spentToday = todayExpenses.reduce(0) { $0 + $1.amount }
                    availableToday = baseDailyLimit - spentToday
                }
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
    
    @AppStorage("btn1_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Name: String = "Coffee"
    @AppStorage("btn1_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Amount: Double = 2000.0
    @AppStorage("btn1_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Icon: String = "cup.and.saucer.fill"
    
    @AppStorage("btn2_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Name: String = "Taxi"
    @AppStorage("btn2_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Amount: Double = 3000.0
    @AppStorage("btn2_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Icon: String = "car.fill"
    
    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }

    var body: some View {
        let isNegative = entry.availableLimit < 0
        let displayAmount = isNegative ? "-\(currencySymbol)\(abs(Int(entry.availableLimit)))" : "\(currencySymbol)\(Int(entry.availableLimit))"
        let limitColor: Color = isNegative ? .red : .green
        
        switch family {
        case .accessoryRectangular:
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ALLOWANCE")
                        .font(.system(size: 10, weight: .bold))
                        .opacity(0.6)
                    
                    Text(displayAmount)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(isNegative ? Color.red : Color.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                HStack(spacing: 12) {
                    Button(intent: AddExpenseIntent(amount: btn1Amount, category: btn1Name)) {
                        Image(systemName: btn1Icon).font(.system(size: 22)).frame(width: 44, height: 44).background(.white.opacity(0.15)).clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(intent: AddExpenseIntent(amount: btn2Amount, category: btn2Name)) {
                        Image(systemName: btn2Icon).font(.system(size: 22)).frame(width: 44, height: 44).background(.white.opacity(0.15)).clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        default:
            VStack(spacing: 12) {
                Text(displayAmount)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(limitColor)
                    .contentTransition(.numericText())
                
                HStack(spacing: 20) {
                    Button(intent: AddExpenseIntent(amount: btn1Amount, category: btn1Name)) {
                        Image(systemName: btn1Icon).font(.title2).foregroundStyle(.white).frame(width: 50, height: 50).background(Color.white.opacity(0.1)).clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(intent: AddExpenseIntent(amount: btn2Amount, category: btn2Name)) {
                        Image(systemName: btn2Icon).font(.title2).foregroundStyle(.white).frame(width: 50, height: 50).background(Color.white.opacity(0.1)).clipShape(Circle())
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
        .configurationDisplayName("DayLimit")
        .description("Quick expenses and daily limit.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
