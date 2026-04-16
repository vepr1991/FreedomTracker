//
//  ContentView.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var cycles: [BudgetCycle]
    // 💡 Сохраняем в памяти, видел ли юзер обучение
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false

    var body: some View {
        if !hasSeenTutorial {
            WelcomeView(hasSeenTutorial: $hasSeenTutorial)
        } else if let activeCycle = cycles.first {
            DashboardView(cycle: activeCycle)
        } else {
            OnboardingView()
        }
    }
}
