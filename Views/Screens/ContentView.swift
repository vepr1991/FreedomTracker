//
//  ContentView.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 14.04.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // Делаем запрос к базе: есть ли у нас долги?
    @Query private var debts: [Debt]

    var body: some View {
        // Если массив долгов не пустой, берем первый активный долг
        if let activeDebt = debts.first {
            // Показываем дашборд и передаем туда этот долг
            DashboardView(debt: activeDebt)
        } else {
            // Если долгов нет, показываем экран первичной настройки
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
}
