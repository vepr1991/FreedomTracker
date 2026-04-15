//
//  SettingsView.swift
//  FreedomTracker
//
//  Created by Владимир Коваленко on 15.04.2026.
//

import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 💡 Читаем и пишем настройки в общую память с виджетом
    @AppStorage("btn1_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Name: String = "Coffee"
    @AppStorage("btn1_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Amount: Double = 2000.0
    @AppStorage("btn1_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn1Icon: String = "cup.and.saucer.fill"
    
    @AppStorage("btn2_name", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Name: String = "Taxi"
    @AppStorage("btn2_amount", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Amount: Double = 3000.0
    @AppStorage("btn2_icon", store: UserDefaults(suiteName: "group.com.vladimirkovalenko.FreedomTracker")) var btn2Icon: String = "car.fill"
    
    private let icons = [
        "cup.and.saucer.fill", "car.fill", "takeoutbag.and.cup.and.straw.fill",
        "cart.fill", "gamecontroller.fill", "basket.fill", "airplane",
        "wineglass.fill", "popcorn.fill", "pills.fill", "tshirt.fill"
    ]
    
    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Left Button (Widget & App)")) {
                    TextField("Category Name", text: $btn1Name)
                    HStack {
                        Text("Amount (\(currencySymbol))")
                        Spacer()
                        TextField("0", value: $btn1Amount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Icon", selection: $btn1Icon) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon).tag(icon)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section(header: Text("Right Button (Widget & App)")) {
                    TextField("Category Name", text: $btn2Name)
                    HStack {
                        Text("Amount (\(currencySymbol))")
                        Spacer()
                        TextField("0", value: $btn2Amount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Icon", selection: $btn2Icon) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon).tag(icon)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
            .navigationTitle("Quick Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    }
                    .foregroundStyle(.green)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
