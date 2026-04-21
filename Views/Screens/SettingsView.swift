import SwiftUI
import WidgetKit
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var cycle: BudgetCycle
    
    @AppStorage("appTheme", store: AppConstants.sharedUserDefaults) var appTheme = 2
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
                Section("Appearance") {
                    Picker("Theme", selection: $appTheme) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Dream Goal") {
                    TextField("Name (e.g. AirPods)", text: Binding(get: { cycle.dreamGoalName ?? "" }, set: { cycle.dreamGoalName = $0 }))
                    HStack {
                        Text("Price (\(symbol))")
                        Spacer()
                        TextField("Amount", value: Binding(get: { cycle.dreamGoalPrice ?? 0 }, set: { cycle.dreamGoalPrice = $0 }), format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Quick Actions (\(quickActionsData.items.count)/10)") {
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
                            Label("Add Action", systemImage: "plus.circle.fill")
                        }
                    }
                }
                
                Section("Cycle Management") {
                    Button(role: .destructive) {
                        modelContext.delete(cycle)
                        dismiss()
                    } label: {
                        Label("Reset Cycle & Budget", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { WidgetCenter.shared.reloadAllTimelines(); dismiss() }
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
            TextField("Name", text: $name)
            TextField("Amount", value: $amount, format: .number).keyboardType(.decimalPad)
            Picker("Icon", selection: $icon) {
                ForEach(icons, id: \.self) { i in Image(systemName: i).tag(i) }
            }
        }
    }
}
