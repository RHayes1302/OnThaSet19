//
//  AppConfig.swift
//  OnThaSet (New)
//
//  Global configuration — controlled from Admin Dashboard (5-tap shield)
//  No resubmission needed to toggle review mode
//

import Foundation

struct AppConfig {

    // Reads from UserDefaults — toggled from Admin Dashboard
    // Default: true (safe for App Review submissions)
    static var isAppReviewMode: Bool {
        if UserDefaults.standard.object(forKey: "adminReviewModeOn") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "adminReviewModeOn")
    }

    // Owner account — ALWAYS has free posting access regardless of toggle
    static let ownerUserIDs: [String] = [
        "000366.ce60803dfe5742d2888b18ee5a388623.0248"
    ]

    // Demo user IDs that get free posting access when review mode is ON
    static let demoUserIDs: [String] = [
        "demo-reviewer-user",
        "55f91a3c-2e28-4d7e-8106-1b2ac2d86681"
    ]

    // Check if current user is the app owner — always can post
    static func isOwner(_ userID: String?) -> Bool {
        guard let id = userID else { return false }
        return ownerUserIDs.contains(id.lowercased())
    }

    // Check if current user is a demo/review account
    static func isDemoUser(_ userID: String?) -> Bool {
        guard isAppReviewMode, let id = userID else { return false }
        return demoUserIDs.contains(id.lowercased())
    }
}
