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
        
        let contextModel = ModelContext(AppConstants.sharedModelContainer)

        var cycleDescriptor = FetchDescriptor<BudgetCycle>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        cycleDescriptor.fetchLimit = 1
        
        if let cycles = try? contextModel.fetch(cycleDescriptor), let activeCycle = cycles.first {
            let calendar = Calendar.current
            let totalDays = max(1, calendar.dateComponents([.day], from: calendar.startOfDay(for: activeCycle.startDate), to: calendar.startOfDay(for: activeCycle.endDate)).day! + 1)
            let baseDailyLimit = activeCycle.totalBudget / Double(totalDays)
            
            let startOfToday = calendar.startOfDay(for: Date())
            guard let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) else { return }
            
            let todayPredicate = #Predicate<ExpenseTransaction> {
                $0.timestamp >= startOfToday && $0.timestamp < endOfToday
            }
            let expenseDescriptor = FetchDescriptor<ExpenseTransaction>(predicate: todayPredicate)
            
            if let todayExpenses = try? contextModel.fetch(expenseDescriptor) {
                let spentToday = todayExpenses.reduce(0) { $0 + $1.amount }
                availableToday = baseDailyLimit - spentToday
            }
        }
        
        let entry = SimpleEntry(date: Date(), availableLimit: availableToday)
        let startOfTomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(startOfTomorrow))
        
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
    
    // 💡 Читаем обертку
    @AppStorage("quickActions", store: AppConstants.sharedUserDefaults) var quickActionsData = QuickActionsWrapper(items: defaultQuickActions)
    
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
                    // 💡 Первые 2 кнопки для маленького виджета
                    ForEach(quickActionsData.items.prefix(2)) { action in
                        Button(intent: AddExpenseIntent(amount: action.amount, category: action.name)) {
                            Image(systemName: action.icon).font(.system(size: 22)).frame(width: 44, height: 44).background(.white.opacity(0.15)).clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        default:
            VStack(spacing: 12) {
                Text(displayAmount)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(limitColor)
                    .contentTransition(.numericText())
                
                HStack(spacing: 20) {
                    // 💡 Первые 3 кнопки для стандартного виджета
                    ForEach(quickActionsData.items.prefix(3)) { action in
                        Button(intent: AddExpenseIntent(amount: action.amount, category: action.name)) {
                            Image(systemName: action.icon).font(.title2).foregroundStyle(.white).frame(width: 50, height: 50).background(Color.white.opacity(0.1)).clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
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
