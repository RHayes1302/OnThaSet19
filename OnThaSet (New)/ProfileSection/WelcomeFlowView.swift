//
//  WelcomeFlowView.swift
//  OnThaSet (New)
//
//  Root-level wrapper that shows WelcomeSetupView for new users
//  before they access the main app

import SwiftUI
import SwiftData

struct WelcomeFlowView: View {
    @Binding var hasCompletedSetup: Bool
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if let profile = profiles.first {
                WelcomeSetupView(profile: profile) {
                    // Mark complete in both SwiftData and AppStorage
                    profile.hasCompletedSetup = true
                    try? modelContext.save()
                    hasCompletedSetup = true
                }
            } else {
                // Profile not created yet — show spinner
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.yellow)
                            .overlay(
                                VStack(spacing: -1) {
                                    Text("ON").font(.system(size: 10, weight: .black))
                                    Text("THA").font(.system(size: 8, weight: .black))
                                    Text("SET").font(.system(size: 12, weight: .black))
                                }.foregroundColor(.black).offset(y: -2)
                            )
                        ProgressView().tint(.yellow)
                        Text("Setting up your profile...")
                            .font(.subheadline).foregroundColor(.gray)
                    }
                }
            }
        }
    }
}
