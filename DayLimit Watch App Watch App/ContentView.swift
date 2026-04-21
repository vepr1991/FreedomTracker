import SwiftUI

struct ContentView: View {
    // 💡 Для синглтонов правильно использовать @ObservedObject
    @ObservedObject private var connector = WatchConnector.shared

    var body: some View {
        // 💡 Выносим вычисления из верстки, чтобы компилятор не зависал
        let symbol = Locale.current.currencySymbol ?? "$"
        let limitInt = Int(connector.availableLimit)
        let isPositive = connector.availableLimit >= 0
        
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    
                    // Теперь текст простой и понятный для компилятора
                    Text("\(symbol)\(limitInt)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(isPositive ? Color.green : Color.red)
                        .contentTransition(.numericText())
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        // 💡 Добавили явный id: \.id, чтобы ForEach не тратил время на вывод типов
                        ForEach(connector.quickActions, id: \.id) { action in
                            WatchActionBtn(icon: action.icon, label: action.name) {
                                connector.sendExpenseToPhone(amount: action.amount, category: action.name)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
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
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
