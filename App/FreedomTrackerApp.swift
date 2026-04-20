import SwiftUI
import SwiftData

@main
struct FreedomTrackerApp: App {
    var container: ModelContainer?

    init() {
        do {
            let schema = Schema([BudgetCycle.self, ExpenseTransaction.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("ModelContainer initialization failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container = container {
                ContentView()
                    .modelContainer(container)
            } else {
                ContentUnavailableView(
                    "Storage Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Failed to load your data. Please try restarting the app or checking your storage.")
                )
            }
        }
    }
}
