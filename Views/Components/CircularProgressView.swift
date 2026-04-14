//
//  CircularProgressView.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import SwiftUI

struct CircularProgressView: View {
    var percentage: Double
    var amount: String
    var subtitle: String
    var color: Color // 💡 НОВОЕ: Теперь цвет можно менять извне
    
    @State private var animatedPercentage: Double = 0
    
    var body: some View {
        ZStack {
            // Фоновый серый круг
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 12)
            
            // Динамический цветной круг
            Circle()
                .trim(from: 0, to: CGFloat(animatedPercentage / 100))
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round)) // 💡 Используем color
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.8), radius: 10) // 💡 Тень тоже красится
                // Анимация цвета и заполнения
                .animation(.easeOut(duration: 1.0), value: animatedPercentage)
                .animation(.easeInOut(duration: 0.5), value: color)
            
            VStack(spacing: 4) {
                Text(amount)
                    .contentTransition(.numericText())
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 20)
                
                Text(subtitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .tracking(2)
                    // 💡 Подкрашиваем подпись, если это перерасход (красный цвет)
                    .foregroundStyle(color == .red ? .red : .white.opacity(0.5))
            }
        }
        .frame(width: 280, height: 280)
        .onAppear {
            animatedPercentage = percentage
        }
        .onChange(of: percentage) { oldValue, newValue in
            animatedPercentage = newValue
        }
    }
}
