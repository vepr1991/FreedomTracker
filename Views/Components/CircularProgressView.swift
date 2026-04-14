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
    
    @State private var animatedPercentage: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 12)
            
            Circle()
                .trim(from: 0, to: CGFloat(animatedPercentage / 100))
                .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.green.opacity(0.8), radius: 10)
                .animation(.easeOut(duration: 1.0), value: animatedPercentage)
            
            VStack(spacing: 4) {
                Text(amount)
                    // Модификатор contentTransition делает смену цифр плавной, как в барабане
                    .contentTransition(.numericText())
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("SAVED TODAY")
                    .font(.caption)
                    .fontWeight(.medium)
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(width: 280, height: 280)
        .onAppear {
            animatedPercentage = percentage
        }
        // Заставляем круг реагировать на новые данные из базы
        .onChange(of: percentage) { oldValue, newValue in
            animatedPercentage = newValue
        }
    }
}
