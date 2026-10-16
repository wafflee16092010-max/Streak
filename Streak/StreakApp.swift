//
//  StreakApp.swift
//  Streak
//
//  Created by Артем Ткачев on 22.09.2026.
//

import SwiftUI

@main
struct StreakApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationManager.shared.requestPermission()
                }
        }
    }
}
