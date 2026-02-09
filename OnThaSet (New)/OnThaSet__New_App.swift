//
//  OnThaSet__New_App.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/4/25.
//
import SwiftUI
import SwiftData

@main
struct OnThaSetApp: App {
    @StateObject private var authService = AuthService()
    
    var body: some Scene {
        WindowGroup {
            // Wrap DefaultPageView with AppCoordinatorView for location authorization
            AppCoordinatorView {
                DefaultPageView()
                    .environmentObject(authService)
            }
        }
        // 🆕 Added EventPhoto and BikeProgress models
        .modelContainer(for: [Event.self, UserProfile.self, EventPhoto.self, BikeProgress.self])
    }
}
