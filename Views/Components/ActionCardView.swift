//
//  ActionCardView.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

//
//  ActionCardView.swift
//  FreedomTracker
//

import SwiftUI

struct ActionCardView: View {
    var iconName: String
    var label: LocalizedStringKey // 💡 1. Поменяли тип на LocalizedStringKey
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(label) // 💡 2. Убрали .uppercased() отсюда
                    .textCase(.uppercase) // 💡 3. Добавили правильный модификатор капса для перевода
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
