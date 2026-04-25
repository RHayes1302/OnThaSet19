//
//  WelcomeFlowView.swift
//  OnThaSet (New)
//
//  Root-level wrapper that shows WelcomeSetupView for new users
//  before they access the main app

import SwiftUI
import SwiftData

struct WelcomeFlowView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthService

    var body: some View {
        WelcomeSetupView(profile: profile) {
            profile.hasCompletedSetup = true
            try? modelContext.save()
        }
    }
}
