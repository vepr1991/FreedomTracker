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

// 1. Провайдер данных (отвечает за то, что показывать на виджете)
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
            
            // 💡 НОВОЕ: Тот же самый путь к общей базе
            let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.vladimirkovalenko.FreedomTracker")!
            let dbURL = groupURL.appendingPathComponent("FreedomData.sqlite")
            
            let modelConfiguration = ModelConfiguration(schema: schema, url: dbURL)
            
            if let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) {
                let context = ModelContext(container)

            let cycleDescriptor = FetchDescriptor<BudgetCycle>()
            let expenseDescriptor = FetchDescriptor<ExpenseTransaction>()
            
            if let cycles = try? context.fetch(cycleDescriptor), let activeCycle = cycles.first,
               let expenses = try? context.fetch(expenseDescriptor) {
                
                // Вся наша математика перекочевала сюда
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

// 2. Модель данных для одного кадра виджета
struct SimpleEntry: TimelineEntry {
    let date: Date
    let availableLimit: Double
}

// 3. Дизайн виджета
struct FreedomWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 12) {
            // Показываем текущий лимит
            Text("\(Int(entry.availableLimit)) ₸")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(entry.availableLimit < 0 ? .red : .green)
                .contentTransition(.numericText())
            
            // Наши интерактивные кнопки
            HStack(spacing: 20) {
                // 💡 Магия: кнопка вызывает Intent в фоне
                Button(intent: AddExpenseIntent(amount: 2000, category: "Кофе")) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Button(intent: AddExpenseIntent(amount: 3000, category: "Такси")) {
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
        .containerBackground(.black, for: .widget) // Черный фон для iOS 17
    }
}

// 4. Настройка самого виджета
struct FreedomWidget: Widget {
    let kind: String = "FreedomWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FreedomWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Freedom Tracker")
        .description("Быстрые траты и контроль лимита.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
