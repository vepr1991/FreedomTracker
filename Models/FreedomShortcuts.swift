//
//  FreedomShortcuts.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 16.04.2026.
//

import AppIntents
import Foundation

struct FreedomShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Добавить трату в \(.applicationName)",
                "Записать расход в \(.applicationName)",
                "Я потратил деньги в \(.applicationName)"
            ],
            shortTitle: "Добавить трату",
            systemImageName: "creditcard.circle.fill"
        )
    }
}
