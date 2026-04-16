//
//  WatchConnector.swift
//  FreedomTracker
//

import Foundation
import Combine
import WatchConnectivity
import SwiftData
import WidgetKit
import SwiftUI

class WatchConnector: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnector()
    
    @Published var availableLimit: Double = 0.0
    var modelContext: ModelContext?
    
    // 💡 "Зал ожидания" для лимита, если мост еще не проснулся
    private var pendingLimit: Double?

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

    // MARK: - Телефон отправляет свежий лимит на Часы
    func syncLimitToWatch(limit: Double) {
        if WCSession.default.activationState == .activated {
            do {
                try WCSession.default.updateApplicationContext(["availableLimit": limit])
                print("✅ Телефон: Лимит \(limit) успешно отправлен на часы")
            } catch {
                print("❌ Телефон: Ошибка отправки лимита: \(error)")
            }
        } else {
            // Если мост еще спит, запоминаем цифру!
            print("⏳ Телефон: Мост еще просыпается. Лимит \(limit) ждет отправки...")
            pendingLimit = limit
        }
    }

    // MARK: - Системные методы (Здесь блютус просыпается)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("🔗 Статус моста: \(activationState.rawValue) (2 = Успешно)")
        
        // Как только мост готов, проверяем, не ждал ли отправки наш лимит
        #if os(iOS)
        if activationState == .activated, let limit = pendingLimit {
            print("🚀 Телефон: Мост готов! Отправляем отложенный лимит...")
            syncLimitToWatch(limit: limit)
            pendingLimit = nil
        }
        #endif
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    #endif

    // Прием сообщений
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) { processReceivedData(message) }
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) { processReceivedData(userInfo) }
    
    // Прием нового лимита на часах
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let limit = applicationContext["availableLimit"] as? Double {
                print("🎯 Часы: Получен новый лимит с телефона: \(limit)")
                self.availableLimit = limit
            }
        }
    }

    // MARK: - Обработка входящих данных на Телефоне
    private func processReceivedData(_ data: [String: Any]) {
        DispatchQueue.main.async {
            #if os(iOS)
            print("📱 Телефон: Получены данные с часов -> \(data)")
            if let action = data["action"] as? String, action == "addExpense",
               let amount = data["amount"] as? Double,
               let category = data["category"] as? String {
                
                if let context = self.modelContext {
                    let expense = ExpenseTransaction(amount: amount, category: category)
                    context.insert(expense)
                    try? context.save()
                    WidgetCenter.shared.reloadAllTimelines()
                    print("💾 Телефон: Трата с часов сохранена в базу!")
                }
            }
            #endif
        }
    }
}
