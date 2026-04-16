//
//  ContentView.swift
//  DayLimit Watch App Watch App
//

import SwiftUI

struct ContentView: View {
    // 💡 Слушаем реальные данные с телефона
    @StateObject private var connector = WatchConnector.shared
    
    // В будущем их можно тоже подтягивать с телефона, но пока оставим для теста
    @State private var btn1Name = "Coffee"
    @State private var btn1Amount: Double = 2000
    @State private var btn1Icon = "cup.and.saucer.fill"
    
    @State private var btn2Name = "Taxi"
    @State private var btn2Amount: Double = 3000
    @State private var btn2Icon = "car.fill"
    
    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 2) {
                Text("TODAY'S LIMIT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(connector.availableLimit >= 0 ? .green : .red)
                    .opacity(0.8)
                
                Text("\(currencySymbol)\(Int(connector.availableLimit))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .contentTransition(.numericText())
            }
            .padding(.top, 8)
            
            Spacer()
            
            HStack(spacing: 8) {
                WatchActionButton(icon: btn1Icon, label: LocalizedStringKey(btn1Name), color: .orange) {
                    withAnimation { connector.availableLimit -= btn1Amount }
                    // 🚀 Отправляем команду на телефон
                    connector.sendExpenseToPhone(amount: btn1Amount, category: btn1Name)
                }
                
                WatchActionButton(icon: btn2Icon, label: LocalizedStringKey(btn2Name), color: .yellow) {
                    withAnimation { connector.availableLimit -= btn2Amount }
                    connector.sendExpenseToPhone(amount: btn2Amount, category: btn2Name)
                }
            }
            .frame(height: 70)
        }
        .padding(.horizontal, 8)
    }
}

struct WatchActionButton: View {
    var icon: String
    var label: LocalizedStringKey
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title2).foregroundStyle(color)
                Text(label).font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.8)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
