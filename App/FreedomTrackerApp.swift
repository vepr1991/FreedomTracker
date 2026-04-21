import SwiftUI
import SwiftData

@main
struct FreedomTrackerApp: App {
    @AppStorage("appTheme", store: AppConstants.sharedUserDefaults) var appTheme = 2
    
    var colorScheme: ColorScheme? {
        switch appTheme {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            // 💡 ИСПРАВЛЕНИЕ: Безопасный запуск приложения
            if let container = AppConstants.sharedModelContainer {
                ContentView()
                    .preferredColorScheme(colorScheme)
                    .modelContainer(container)
            } else {
                ContentUnavailableView(
                    "Storage Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Could not access the database. Please restart the device or reinstall the app.")
                )
                .preferredColorScheme(colorScheme)
            }
        }
    }
}
