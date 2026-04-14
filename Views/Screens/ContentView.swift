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

    var body: some View {
        if let activeCycle = cycles.first {
            DashboardView(cycle: activeCycle)
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
}
