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
    
    // Состояния для полей ввода
    @State private var title: String = ""
    @State private var totalAmount: String = ""
    @State private var monthlyPayment: String = ""
    @State private var targetDate: Date = Date().addingTimeInterval(365 * 24 * 3600) // +1 год по умолчанию
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Твоя финансовая цель")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Давай рассчитаем стоимость одного дня твоей свободы.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    // Кастомные поля ввода
                    CustomTextField(title: "Название (Например: Долг за авто)", text: $title)
                    CustomTextField(title: "Общая сумма долга (₸)", text: $totalAmount, keyboardType: .numberPad)
                    CustomTextField(title: "Ежемесячный платеж (₸)", text: $monthlyPayment, keyboardType: .numberPad)
                    
                    DatePicker("Дата полного погашения", selection: $targetDate, displayedComponents: .date)
                        .colorScheme(.dark)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Spacer()
                
                // Кнопка сохранения
                Button(action: saveDebt) {
                    Text("НАЧАТЬ ПУТЬ К СВОБОДЕ")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                // Кнопка неактивна, если поля пустые
                .disabled(title.isEmpty || totalAmount.isEmpty || monthlyPayment.isEmpty)
                .opacity((title.isEmpty || totalAmount.isEmpty || monthlyPayment.isEmpty) ? 0.5 : 1)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func saveDebt() {
        // Конвертируем строки в числа
        guard let amount = Double(totalAmount),
              let payment = Double(monthlyPayment) else { return }
        
        let newDebt = Debt(title: title, totalAmount: amount, monthlyPayment: payment, targetDate: targetDate)
        
        // Сохраняем в базу. ContentView автоматически это заметит и переключит экран.
        modelContext.insert(newDebt)
    }
}

// Переиспользуемый компонент текстового поля для красоты
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
