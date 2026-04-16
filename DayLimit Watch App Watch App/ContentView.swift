//
//  ContentView.swift
//  DayLimit Watch App Watch App
//
//  Created by Владимир Коваленко on 16.04.2026.
//

import SwiftUI

struct ContentView: View {
    // 💡 Пока используем @State для теста верстки.
    // На следующем шаге мы заменим это на реальные данные с телефона!
    @State private var availableLimit: Double = 8500
    
    // Временные данные для кнопок (потом подтянем из настроек)
    @State private var btn1Name = "Coffee"
    @State private var btn1Amount: Double = 2000
    @State private var btn1Icon = "cup.and.saucer.fill"
    
    @State private var btn2Name = "Taxi"
    @State private var btn2Amount: Double = 3000
    @State private var btn2Icon = "car.fill"
    
    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }
    
    var body: some View {
        VStack(spacing: 12) {
            // Заголовок и текущий лимит
            VStack(spacing: 2) {
                Text("TODAY'S LIMIT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(availableLimit >= 0 ? .green : .red)
                    .opacity(0.8)
                
                Text("\(currencySymbol)\(Int(availableLimit))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .contentTransition(.numericText())
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Две быстрые кнопки
            HStack(spacing: 8) {
                WatchActionButton(icon: btn1Icon, label: LocalizedStringKey(btn1Name), color: .orange) {
                    withAnimation { availableLimit -= btn1Amount }
                    // 🚀 Скоро здесь будет отправка сигнала на iPhone
                }
                
                WatchActionButton(icon: btn2Icon, label: LocalizedStringKey(btn2Name), color: .yellow) {
                    withAnimation { availableLimit -= btn2Amount }
                    // 🚀 Скоро здесь будет отправка сигнала на iPhone
                }
            }
            .frame(height: 70)
        }
        .padding(.horizontal, 8)
    }
}

// Переиспользуемый компонент кнопки для часов
struct WatchActionButton: View {
    var icon: String
    var label: LocalizedStringKey
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
