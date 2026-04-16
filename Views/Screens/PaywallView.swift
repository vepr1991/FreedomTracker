//
//  PaywallView.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 16.04.2026.
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPro: Bool // Временно управляем статусом отсюда
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Кнопка закрытия
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Иконка и Заголовок
                VStack(spacing: 16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.yellow)
                        .shadow(color: .yellow.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    Text("DayLimit Pro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Unlock the full potential of your daily allowance.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 32)
                }
                
                // Список фич
                VStack(alignment: .leading, spacing: 24) {
                    PaywallFeatureRow(icon: "square.grid.2x2.fill", title: "Custom Categories", subtitle: "Change widget icons and names.")
                    PaywallFeatureRow(icon: "list.bullet.rectangle.fill", title: "Full History", subtitle: "View and manage all your past expenses.")
                    PaywallFeatureRow(icon: "icloud.fill", title: "iCloud Sync", subtitle: "Securely backup and sync across devices.")
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Кнопки "Покупки"
                VStack(spacing: 16) {
                    Button(action: {
                        isPro = true // Имитация покупки
                        dismiss()
                    }) {
                        VStack {
                            Text("Lifetime Access")
                                .font(.headline)
                            Text("$29.99 One-time")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Button(action: {
                        isPro = true // Имитация покупки
                        dismiss()
                    }) {
                        Text("Restore Purchases")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct PaywallFeatureRow: View {
    var icon: String
    var title: LocalizedStringKey
    var subtitle: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.yellow)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
