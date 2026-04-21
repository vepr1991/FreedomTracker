import SwiftUI
import WidgetKit
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var cycle: BudgetCycle
    
    @AppStorage("btn1_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Name = "Кофе"
    @AppStorage("btn1_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Amount = 1000.0
    @AppStorage("btn1_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Icon = "cup.and.saucer.fill"
    
    @AppStorage("btn2_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Name = "Такси"
    @AppStorage("btn2_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Amount = 1500.0
    @AppStorage("btn2_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Icon = "car.fill"
    
    @AppStorage("btn3_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn3Name = "Обед"
    @AppStorage("btn3_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn3Amount = 2500.0
    @AppStorage("btn3_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn3Icon = "bag.fill"
    
    private let icons = ["cup.and.saucer.fill", "car.fill", "bag.fill", "cart.fill", "airplane", "pills.fill", "gamecontroller.fill", "wineglass.fill"]
    private var symbol: String { Locale.current.currencySymbol ?? "₸" }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Цель накопления") {
                    TextField("Название (напр. AirPods)", text: Binding(get: { cycle.dreamGoalName ?? "" }, set: { cycle.dreamGoalName = $0 }))
                    HStack {
                        Text("Стоимость (\(symbol))")
                        Spacer()
                        TextField("Сумма", value: Binding(get: { cycle.dreamGoalPrice ?? 0 }, set: { cycle.dreamGoalPrice = $0 }), format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Быстрые кнопки") {
                    SettingsRow(label: "Кнопка 1", name: $btn1Name, amount: $btn1Amount, icon: $btn1Icon, icons: icons)
                    SettingsRow(label: "Кнопка 2", name: $btn2Name, amount: $btn2Amount, icon: $btn2Icon, icons: icons)
                    SettingsRow(label: "Кнопка 3", name: $btn3Name, amount: $btn3Amount, icon: $btn3Icon, icons: icons)
                }
                
                Section("Управление периодом") {
                    Button(role: .destructive) {
                        modelContext.delete(cycle)
                        dismiss()
                    } label: {
                        Label("Сбросить период и бюджет", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("Настройки")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { WidgetCenter.shared.reloadAllTimelines(); dismiss() }
                }
            }
        }
    }
}

struct SettingsRow: View {
    let label: String
    @Binding var name: String
    @Binding var amount: Double
    @Binding var icon: String
    let icons: [String]
    var body: some View {
        DisclosureGroup(label) {
            TextField("Название", text: $name)
            TextField("Сумма", value: $amount, format: .number).keyboardType(.decimalPad)
            Picker("Иконка", selection: $icon) {
                ForEach(icons, id: \.self) { i in Image(systemName: i).tag(i) }
            }
        }
    }
}
