//
//  OnboardingView.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import SwiftUI
import SwiftData
import WidgetKit

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var totalBudget: String = ""
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date()
    
    // 💡 ОПТИМИЗАЦИЯ: Форматтер создается один раз
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
    
    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Budget")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("How much can you spend on yourself until your next paycheck? (Excluding rent and bills)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    CustomTextField(title: "Allowance amount (\(currencySymbol))", text: $totalBudget, keyboardType: .numberPad)
                        .onChange(of: totalBudget) { oldValue, newValue in
                            let cleanString = newValue.filter { "0123456789".contains($0) }
                            if let number = Int(cleanString) {
                                totalBudget = Self.formatter.string(from: NSNumber(value: number)) ?? ""
                            } else {
                                totalBudget = ""
                            }
                        }
                    
                    DatePicker("Payday", selection: $endDate, displayedComponents: .date)
                        .colorScheme(.dark)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Spacer()
                
                Button(action: saveCycle) {
                    Text("START")
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
        let cleanString = totalBudget.filter { "0123456789".contains($0) }
        guard let budget = Double(cleanString) else { return }
        
        let newCycle = BudgetCycle(totalBudget: budget, endDate: endDate)
        modelContext.insert(newCycle)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct CustomTextField: View {
    var title: LocalizedStringKey
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
