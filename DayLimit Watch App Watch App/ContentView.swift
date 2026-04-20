import SwiftUI

struct ContentView: View {
    @ObservedObject var connector = WatchConnector.shared
    
    // Синхронизация названий с iPhone
    @AppStorage("btn1_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Name = "Coffee"
    @AppStorage("btn1_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Amount = 5.0
    
    @AppStorage("btn2_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Name = "Taxi"
    @AppStorage("btn2_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Amount = 15.0

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("$\(Int(connector.availableLimit))")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(connector.availableLimit >= 0 ? .green : .red)
                
                HStack(spacing: 10) {
                    WatchActionBtn(icon: "cup.and.saucer.fill", label: btn1Name) {
                        connector.sendExpenseToPhone(amount: btn1Amount, category: btn1Name)
                    }
                    WatchActionBtn(icon: "car.fill", label: btn2Name) {
                        connector.sendExpenseToPhone(amount: btn2Amount, category: btn2Name)
                    }
                }
            }
            .navigationTitle("DayLimit")
        }
    }
}

struct WatchActionBtn: View {
    let icon: String; let label: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon).font(.title3)
                Text(label).font(.caption2).lineLimit(1)
            }
        }
    }
}
