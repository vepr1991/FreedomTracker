//
//  ContentView.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // Подключаемся к нашей новой базе данных
    @Environment(\.modelContext) private var modelContext
    @Query private var debts: [Debt]
    @Query private var savings: [SavingEvent]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                HStack {
                    Text("DEBT TO NIKITA")
                        .font(.caption)
                        .fontWeight(.medium)
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Spacer()
                    
                    HStack(spacing: -10) {
                        Circle().fill(.gray).frame(width: 32, height: 32)
                            .overlay(Circle().stroke(.black, lineWidth: 2))
                        Circle().fill(Color.gray.opacity(0.5)).frame(width: 32, height: 32)
                            .overlay(Circle().stroke(.black, lineWidth: 2))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // Прогресс (пока хардкод для визуала)
                CircularProgressView(percentage: 85, amount: "8,500 ₸")
                
                // Даты
                VStack(spacing: 8) {
                    HStack {
                        Text("Freedom:")
                            .font(.title3)
                            .fontWeight(.light)
                            .foregroundStyle(.white.opacity(0.9))
                        Text("14 Nov 2026")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                            .shadow(color: .green.opacity(0.5), radius: 8)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                        Text("-1.5 days")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.green.opacity(0.8))
                }
                
                Spacer()
                
                // Grid кнопок
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ActionCardView(iconName: "cup.and.saucer.fill", label: "Coffee") { print("Coffee tapped") }
                    ActionCardView(iconName: "car.fill", label: "Taxi") { print("Taxi tapped") }
                    ActionCardView(iconName: "bag.fill", label: "Grocery") { print("Grocery tapped") }
                    ActionCardView(iconName: "plus", label: "Add") { print("Add tapped") }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    ContentView()
}
