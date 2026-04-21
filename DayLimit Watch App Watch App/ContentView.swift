import SwiftUI

struct ContentView: View {
    @StateObject private var connector = WatchConnector.shared
    
    // 💡 Добавили определение локальной валюты
    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // 💡 Используем переменную вместо жесткого "$"
                Text("\(currencySymbol)\(Int(connector.availableLimit))")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(connector.availableLimit >= 0 ? .green : .red)
                    .contentTransition(.numericText())
                
                HStack(spacing: 10) {
                    WatchActionBtn(icon: connector.btn1Icon, label: connector.btn1Name) {
                        connector.sendExpenseToPhone(amount: connector.btn1Amount, category: connector.btn1Name)
                    }
                    WatchActionBtn(icon: connector.btn2Icon, label: connector.btn2Name) {
                        connector.sendExpenseToPhone(amount: connector.btn2Amount, category: connector.btn2Name)
                    }
                }
            }
            .navigationTitle("DayLimit")
        }
    }
}

struct WatchActionBtn: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                Text(label).font(.caption2).lineLimit(1)
            }
            .padding(.vertical, 8)
        }
    }
}
