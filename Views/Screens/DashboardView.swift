//
//  DashboardView.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savings: [SavingEvent]
    
    // Сюда мы будем передавать наш долг из базы
    var debt: Debt

    private let dailyGoal: Double = 10000
    
    private var totalSaved: Double {
        savings.reduce(0) { sum, saving in sum + saving.amount }
    }
    
    private var progressPercentage: Double {
        min((totalSaved / dailyGoal) * 100, 100)
    }
    
    // 💡 ТЕПЕРЬ СЧИТАЕМ НА ОСНОВЕ РЕАЛЬНОГО ПЛАТЕЖА ИЗ БАЗЫ!
    private var daysSaved: Double {
        totalSaved / debt.dailyCost
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                HStack {
                    // 💡 РЕАЛЬНОЕ НАЗВАНИЕ
                    Text(debt.title.uppercased())
                        .font(.caption)
                        .fontWeight(.medium)
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Spacer()
                    
                    HStack(spacing: -10) {
                        Circle().fill(.gray.opacity(0.5)).frame(width: 32, height: 32)
                            .overlay(Circle().stroke(.black, lineWidth: 2))
                        Circle().fill(.gray.opacity(0.5)).frame(width: 32, height: 32)
                            .overlay(Circle().stroke(.black, lineWidth: 2))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                withAnimation {
                    CircularProgressView(
                        percentage: progressPercentage,
                        amount: "\(Int(totalSaved)) ₸"
                    )
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Freedom:")
                            .font(.title3)
                            .fontWeight(.light)
                            .foregroundStyle(.white.opacity(0.9))
                        // 💡 РЕАЛЬНАЯ ДАТА
                        Text(debt.targetDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                            .shadow(color: .green.opacity(0.5), radius: 8)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                        Text(String(format: "-%.1f days", daysSaved))
                            .contentTransition(.numericText())
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.green.opacity(0.8))
                }
                
                Spacer()
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ActionCardView(iconName: "cup.and.saucer.fill", label: "Coffee") {
                        addSaving(amount: 2000, category: "Coffee")
                    }
                    ActionCardView(iconName: "car.fill", label: "Taxi") {
                        addSaving(amount: 3000, category: "Taxi")
                    }
                    ActionCardView(iconName: "bag.fill", label: "Grocery") {
                        addSaving(amount: 5000, category: "Grocery")
                    }
                    ActionCardView(iconName: "trash.fill", label: "Reset All") {
                        resetAll()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func addSaving(amount: Double, category: String) {
        let newSaving = SavingEvent(amount: amount, category: category)
        modelContext.insert(newSaving)
    }
    
    // Сброс и трат, И самого долга (чтобы снова попасть на онбординг для теста)
    private func resetAll() {
        for saving in savings { modelContext.delete(saving) }
        modelContext.delete(debt)
    }
}
