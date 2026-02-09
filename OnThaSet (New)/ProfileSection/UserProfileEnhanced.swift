//
//  UserProfileEnhanced.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var appleUserID: String
    var email: String
    
    // Post tracking for subscription users
    var postsThisMonth: Int = 0
    var lastPostDate: Date?
    var lastResetDate: Date?
    
    // Subscription status
    var hasActiveSubscription: Bool = false
    var subscriptionStartDate: Date?
    
    // 🆕 MYSPACE-STYLE PROFILE FIELDS
    var displayName: String = ""
    var bio: String = ""
    var hometown: String = ""
    var club: String = "" // Motorcycle club affiliation
    var favoriteRide: String = "" // Their motorcycle
    var ridingSince: String = "" // Year they started riding
    var profileImageData: Data? = nil
    var backgroundImageData: Data? = nil
    
    // Social links
    var instagramHandle: String = ""
    var tiktokHandle: String = ""
    var youtubeChannel: String = ""
    var facebookHandle: String = ""
    
    // Riding preferences
    var preferredRideType: String = "" // Solo, Group, Long Distance, etc.
    var favoriteRoute: String = ""
    
    // Stats
    var totalPhotosPosted: Int = 0
    var totalBikeProgressPosts: Int = 0
    var memberSince: Date = Date()
    
    init(appleUserID: String, email: String) {
        self.appleUserID = appleUserID
        self.email = email
        self.postsThisMonth = 0
        self.lastPostDate = nil
        self.lastResetDate = Date()
        self.hasActiveSubscription = false
        self.subscriptionStartDate = nil
        self.memberSince = Date()
    }
    
    // Check if user can post
    func canPost() -> Bool {
        // If they have a subscription, check if they have posts remaining this month
        if hasActiveSubscription {
            checkAndResetMonthlyCount()
            return postsThisMonth < 4  // 4 posts per month limit
        }
        
        // Non-subscribers can't post (must purchase single post or subscribe)
        return false
    }
    
    // Reset count if new month
    func checkAndResetMonthlyCount() {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastReset = lastResetDate {
            let currentMonth = calendar.component(.month, from: now)
            let lastResetMonth = calendar.component(.month, from: lastReset)
            let currentYear = calendar.component(.year, from: now)
            let lastResetYear = calendar.component(.year, from: lastReset)
            
            // Reset if it's a new month or year
            if currentMonth != lastResetMonth || currentYear != lastResetYear {
                postsThisMonth = 0
                lastResetDate = now
                print("📅 Monthly post count reset to 0")
            }
        } else {
            lastResetDate = now
        }
    }
    
    // Increment post count
    func incrementPostCount() {
        postsThisMonth += 1
        lastPostDate = Date()
        print("📊 Posts this month: \(postsThisMonth)/4")
    }
    
    // Get remaining posts
    func remainingPosts() -> Int {
        if !hasActiveSubscription {
            return 0
        }
        checkAndResetMonthlyCount()
        return max(0, 4 - postsThisMonth)
    }
    
    // 🆕 Check if profile is complete
    func isProfileComplete() -> Bool {
        return !displayName.isEmpty && !bio.isEmpty && !favoriteRide.isEmpty
    }
}
