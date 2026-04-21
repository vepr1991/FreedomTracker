import AppIntents
import Foundation

// 💡 Этот класс отвечает за то, чтобы приложение появилось в приложении "Команды" (Shortcuts) и работало с Siri
struct FreedomShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add expense in \(.applicationName)",
                "Track spending in \(.applicationName)",
                "Log an expense in \(.applicationName)"
            ],
            shortTitle: "Add Expense",
            systemImageName: "creditcard.circle.fill"
        )
    }
}
