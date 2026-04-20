import SwiftUI
import WidgetKit
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var cycle: BudgetCycle
    
    @AppStorage("btn1_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Name = "Coffee"
    @AppStorage("btn1_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Amount = 5.0
    @AppStorage("btn1_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Icon = "cup.and.saucer.fill"
    
    @AppStorage("btn2_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Name = "Taxi"
    @AppStorage("btn2_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Amount = 15.0
    @AppStorage("btn2_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Icon = "car.fill"
    
    @AppStorage("btn3_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn3Name = "Lunch"
    @AppStorage("btn3_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn3Amount = 20.0
    @AppStorage("btn3_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn3Icon = "bag.fill"
    
    private let icons = ["cup.and.saucer.fill", "car.fill", "bag.fill", "cart.fill", "airplane", "pills.fill"]
    private var symbol: String { Locale.current.currencySymbol ?? "$" }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Dream Goal") {
                    TextField("Goal Name", text: Binding(get: { cycle.dreamGoalName ?? "" }, set: { cycle.dreamGoalName = $0 }))
                    HStack {
                        Text("Target (\(symbol))")
                        Spacer()
                        TextField("Amount", value: Binding(get: { cycle.dreamGoalPrice ?? 0 }, set: { cycle.dreamGoalPrice = $0 }), format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Quick Buttons") {
                    SettingsRow(label: "Button 1", name: $btn1Name, amount: $btn1Amount, icon: $btn1Icon, icons: icons)
                    SettingsRow(label: "Button 2", name: $btn2Name, amount: $btn2Amount, icon: $btn2Icon, icons: icons)
                    SettingsRow(label: "Button 3", name: $btn3Name, amount: $btn3Amount, icon: $btn3Icon, icons: icons)
                }
                
                Section("Danger Zone") {
                    Button(role: .destructive) {
                        modelContext.delete(cycle)
                        dismiss()
                    } label: {
                        Label("Reset Current Cycle", systemImage: "arrow.clockwise")
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
