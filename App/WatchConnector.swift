import Foundation
import Combine
import WatchConnectivity
import SwiftData
import WidgetKit
import SwiftUI

class WatchConnector: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnector()
    
    @Published var availableLimit: Double = 0.0
    // 💡 Массив для отображения на часах
    @Published var quickActions: [QuickAction] = defaultQuickActions
    
    private var pendingContext: [String: Any]?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendExpenseToPhone(amount: Double, category: String) {
        let data: [String: Any] = ["action": "addExpense", "amount": amount, "category": category]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(data, replyHandler: nil)
            print("⌚️ Часы: Трата \(amount) отправлена мгновенно")
        } else {
            WCSession.default.transferUserInfo(data)
            print("⌚️ Часы: Телефон недоступен, трата \(amount) поставлена в очередь")
        }
    }

    #if os(iOS)
    // 💡 Телефон отправляет массив кнопок на часы
    func syncDataToWatch(limit: Double, actions: [QuickAction]) {
        let context: [String: Any] = [
            "availableLimit": limit,
            "quickActionsData": (try? JSONEncoder().encode(actions)) ?? Data()
        ]
        
        if WCSession.default.activationState == .activated {
            do {
                try WCSession.default.updateApplicationContext(context)
                print("✅ Телефон: Настройки и лимит отправлены на часы")
            } catch {
                print("❌ Телефон: Ошибка отправки контекста: \(error)")
            }
        } else {
            print("⏳ Телефон: Мост еще просыпается. Данные ждут отправки...")
            pendingContext = context
        }
    }
    #endif

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        #if os(iOS)
        if activationState == .activated, let context = pendingContext {
            try? WCSession.default.updateApplicationContext(context)
            pendingContext = nil
        }
        #endif
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    #endif

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) { processReceivedData(message) }
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) { processReceivedData(userInfo) }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let limit = applicationContext["availableLimit"] as? Double { self.availableLimit = limit }
            
            // 💡 Распаковываем массив кнопок на часах
            if let data = applicationContext["quickActionsData"] as? Data,
               let decoded = try? JSONDecoder().decode([QuickAction].self, from: data) {
                self.quickActions = decoded
            }
            print("🎯 Часы: Получены новые данные с телефона")
        }
    }

    private func processReceivedData(_ data: [String: Any]) {
        DispatchQueue.main.async {
            #if os(iOS)
            if let action = data["action"] as? String, action == "addExpense",
               let amount = data["amount"] as? Double,
               let category = data["category"] as? String {
                
                let context = AppConstants.sharedModelContainer.mainContext
                let expense = ExpenseTransaction(amount: amount, category: category)
                context.insert(expense)
                try? context.save()
                
                WidgetCenter.shared.reloadAllTimelines()
                print("💾 Телефон: Трата с часов сохранена в базу!")
            }
            #endif
        }
    }
}
