import SwiftUI
import SwiftData

@main
struct FreedomTrackerApp: App {
    // 0: Системная, 1: Светлая, 2: Темная
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
            ContentView()
                .preferredColorScheme(colorScheme) // 💡 Применяем тему глобально
        }
        .modelContainer(AppConstants.sharedModelContainer)
    }
}
