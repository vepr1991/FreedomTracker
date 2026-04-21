import Foundation
import Combine
import WatchConnectivity
import SwiftData
import WidgetKit
import SwiftUI

class WatchConnector: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnector()
    
    @Published var availableLimit: Double = 0.0
    
    // 💡 Настройки кнопок для отображения на часах
    @Published var btn1Name: String = "Coffee"
    @Published var btn1Amount: Double = 5.0
    @Published var btn1Icon: String = "cup.and.saucer.fill"
    
    @Published var btn2Name: String = "Taxi"
    @Published var btn2Amount: Double = 15.0
    @Published var btn2Icon: String = "car.fill"
    
    private var pendingContext: [String: Any]?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Часы отправляют трату на Телефон
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

    // MARK: - Телефон отправляет свежие данные на Часы
    #if os(iOS)
    func syncDataToWatch(limit: Double, b1Name: String, b1Amount: Double, b1Icon: String, b2Name: String, b2Amount: Double, b2Icon: String) {
        let context: [String: Any] = [
            "availableLimit": limit,
            "btn1Name": b1Name, "btn1Amount": b1Amount, "btn1Icon": b1Icon,
            "btn2Name": b2Name, "btn2Amount": b2Amount, "btn2Icon": b2Icon
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

    // MARK: - Системные методы
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
    
    // Прием нового лимита и настроек на часах
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let limit = applicationContext["availableLimit"] as? Double { self.availableLimit = limit }
            
            if let n1 = applicationContext["btn1Name"] as? String { self.btn1Name = n1 }
            if let a1 = applicationContext["btn1Amount"] as? Double { self.btn1Amount = a1 }
            if let i1 = applicationContext["btn1Icon"] as? String { self.btn1Icon = i1 }
            
            if let n2 = applicationContext["btn2Name"] as? String { self.btn2Name = n2 }
            if let a2 = applicationContext["btn2Amount"] as? Double { self.btn2Amount = a2 }
            if let i2 = applicationContext["btn2Icon"] as? String { self.btn2Icon = i2 }
            
            print("🎯 Часы: Получены новые данные с телефона")
        }
    }

    // Обработка входящих данных на Телефоне
    private func processReceivedData(_ data: [String: Any]) {
        DispatchQueue.main.async {
            #if os(iOS)
            if let action = data["action"] as? String, action == "addExpense",
               let amount = data["amount"] as? Double,
               let category = data["category"] as? String {
                
                // 💡 Используем единый контейнер из AppConstants
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
