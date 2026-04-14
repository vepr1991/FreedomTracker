//
//  OnboardingView.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var totalBudget: String = ""
    // По умолчанию ставим дату на 15 дней вперед
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Твой бюджет")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Сколько денег ты можешь тратить на жизнь до следующей зарплаты? (Без учета кредитов и коммуналки)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    CustomTextField(title: "Сумма на расходы (₸)", text: $totalBudget, keyboardType: .numberPad)
                    
                    DatePicker("День зарплаты", selection: $endDate, displayedComponents: .date)
                        .colorScheme(.dark)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Spacer()
                
                Button(action: saveCycle) {
                    Text("НАЧАТЬ")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(totalBudget.isEmpty)
                .opacity(totalBudget.isEmpty ? 0.5 : 1)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func saveCycle() {
        guard let budget = Double(totalBudget) else { return }
        let newCycle = BudgetCycle(totalBudget: budget, endDate: endDate)
        modelContext.insert(newCycle)
    }
}

// Компонент поля ввода оставляем
struct CustomTextField: View {
    var title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        TextField(title, text: $text)
            .keyboardType(keyboardType)
            .padding()
            .background(Color.white.opacity(0.05))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .colorScheme(.dark)
    }
}
