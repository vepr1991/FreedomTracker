import SwiftUI
import WidgetKit
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var cycle: BudgetCycle
    
    @AppStorage("appTheme", store: AppConstants.sharedUserDefaults) var appTheme = 2
    
    // 💡 Обертка для массива
    @AppStorage("quickActions", store: AppConstants.sharedUserDefaults) var quickActionsData = QuickActionsWrapper(items: defaultQuickActions)
    
    private let icons = ["cup.and.saucer.fill", "car.fill", "bag.fill", "cart.fill", "airplane", "pills.fill", "gamecontroller.fill", "wineglass.fill", "train.side.front.car", "fork.knife"]
    private var symbol: String { Locale.current.currencySymbol ?? "$" }
    
    private var colorScheme: ColorScheme? {
        switch appTheme {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Внешний вид") {
                    Picker("Тема оформления", selection: $appTheme) {
                        Text("Системная").tag(0)
                        Text("Светлая").tag(1)
                        Text("Темная").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Цель накопления") {
                    TextField("Название (напр. AirPods)", text: Binding(get: { cycle.dreamGoalName ?? "" }, set: { cycle.dreamGoalName = $0 }))
                    HStack {
                        Text("Стоимость (\(symbol))")
                        Spacer()
                        TextField("Сумма", value: Binding(get: { cycle.dreamGoalPrice ?? 0 }, set: { cycle.dreamGoalPrice = $0 }), format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Быстрые кнопки (\(quickActionsData.items.count)/10)") {
                    List {
                        ForEach($quickActionsData.items) { $action in
                            SettingsRow(label: action.name, name: $action.name, amount: $action.amount, icon: $action.icon, icons: icons)
                        }
                        .onDelete { indexSet in
                            quickActionsData.items.remove(atOffsets: indexSet)
                        }
                    }
                    
                    if quickActionsData.items.count < 10 {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium); generator.impactOccurred()
                            quickActionsData.items.append(QuickAction(name: "New", amount: 10, icon: "star.fill"))
                        } label: {
                            Label("Добавить кнопку", systemImage: "plus.circle.fill")
                        }
                    }
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
        .preferredColorScheme(colorScheme)
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
