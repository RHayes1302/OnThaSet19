//
//  ProfileView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    @Query private var profiles: [UserProfile]
    @Query(sort: \Event.date, order: .reverse) private var allEvents: [Event]
    
    @StateObject private var storeManager = StoreKitManager()
    
    @State private var showingSignOutAlert = false
    @State private var showingCancelSubscriptionAlert = false
    @State private var showingManageSubscription = false
    @State private var showingPaymentSheet = false
    @State private var showDebugScreen = false  // 🐛 DEBUG - Changed from showDebugMenu
    @State private var refreshTrigger = UUID()  // Force refresh
    
    private var currentProfile: UserProfile? {
        profiles.first
    }
    
    private var userEvents: [Event] {
        guard let profile = currentProfile else { return [] }
        // Filter events by user's apple ID (you'll need to add userID to Event model)
        // For now, showing all events as placeholder
        return allEvents
    }
    
    var body: some View {
        let _ = print("🟢 ProfileView body is rendering")
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // HEADER
                    headerSection
                    
                    // SUBSCRIPTION STATUS CARD
                    subscriptionStatusCard
                    
                    // SUBSCRIBER-ONLY FEATURES (if subscribed)
                    if let profile = currentProfile, profile.hasActiveSubscription {
                        subscriberFeaturesCard
                    }
                    
                    // POST TRACKING CARD (if subscribed)
                    if let profile = currentProfile, profile.hasActiveSubscription {
                        postTrackingCard
                    }
                    
                    // MY EVENTS SECTION
                    myEventsSection
                    
                    // ACCOUNT ACTIONS
                    accountActionsSection
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
            
            ToolbarItem(placement: .principal) {
                ZStack {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.yellow)
                    VStack(spacing: -1) {
                        Text("ON").font(.system(size: 6, weight: .black))
                        Text("THA").font(.system(size: 5, weight: .black))
                        Text("SET").font(.system(size: 8, weight: .black))
                    }
                    .foregroundColor(.black)
                    .offset(y: -1)
                }
            }
            
            // 🐛 DEBUG BUTTON - Remove for production
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showDebugScreen = true }) {
                    Image(systemName: "ant.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.logout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Cancel Subscription", isPresented: $showingCancelSubscriptionAlert) {
            Button("Not Now", role: .cancel) { }
            Button("Manage in Settings", role: .destructive) {
                openSubscriptionSettings()
            }
        } message: {
            Text("To cancel your subscription, go to Settings > Apple ID > Subscriptions")
        }
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentSelectionView(shouldNavigateToPost: .constant(false))
        }
        .fullScreenCover(isPresented: $showDebugScreen) {
            SimpleDebugView()
        }
        .id(refreshTrigger)
        .onAppear {
            print("🟢 ProfileView appeared!")
            print("🟢 Number of profiles in database: \(profiles.count)")
            
            if let profile = currentProfile {
                print("🟢 Profile found!")
                print("   Email: \(profile.email)")
                print("   Apple ID: \(profile.appleUserID)")
                print("   Has subscription: \(profile.hasActiveSubscription)")
                print("   Posts this month: \(profile.postsThisMonth)")
            } else {
                print("🔴 NO PROFILE FOUND IN DATABASE!")
            }
            
            // Sync subscription status
            if let profile = currentProfile {
                profile.hasActiveSubscription = storeManager.hasActiveSubscription
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            // Profile Icon
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)
            }
            
            // User Info
            if let profile = currentProfile {
                VStack(spacing: 5) {
                    Text(profile.email)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Apple ID: \(profile.appleUserID.prefix(8))...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Subscription Status Card
    
    private var subscriberFeaturesCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("SUBSCRIBER FEATURES")
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            
            Divider().background(Color.yellow.opacity(0.3))
            
            // Feature List
            VStack(spacing: 12) {
                featureRow(
                    icon: "photo.on.rectangle.angled",
                    title: "Event Photos",
                    description: "Share your event photos with the community",
                    destination: AnyView(EventPhotosFeedView())
                )
                
                featureRow(
                    icon: "wrench.and.screwdriver.fill",
                    title: "Pimp My Ride",
                    description: "Document your bike's transformation",
                    destination: AnyView(BikeProgressFeedView())
                )
                
                featureRow(
                    icon: "person.crop.rectangle.fill",
                    title: "Public Profile",
                    description: "MySpace-style profile page for your riding persona",
                    destination: AnyView(PublicProfileView(profile: currentProfile!))
                )
                
                featureRow(
                    icon: "pencil.circle.fill",
                    title: "Edit Profile",
                    description: "Customize your profile, add photos & social links",
                    destination: AnyView(EditProfileView(profile: currentProfile!))
                )
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.15), Color.yellow.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
        )
    }
    
    private func featureRow(icon: String, title: String, description: String, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.yellow)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Subscription Status Card
    
    private var subscriptionStatusCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("SUBSCRIPTION STATUS")
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            
            Divider().background(Color.yellow.opacity(0.3))
            
            if let profile = currentProfile, profile.hasActiveSubscription {
                // Active Subscription
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Monthly Subscription")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        Text("$9.00 / month")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let startDate = profile.subscriptionStartDate {
                            Text("Active since \(startDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                }
                
                // Manage Subscription Button
                Button(action: {
                    showingCancelSubscriptionAlert = true
                }) {
                    Text("MANAGE SUBSCRIPTION")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                
            } else {
                // No Active Subscription
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("No Active Subscription")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        Text("Subscribe to post 4 events per month")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
                
                // Subscribe Button
                Button(action: {
                    showingPaymentSheet = true
                }) {
                    Text("SUBSCRIBE NOW - $9/MONTH")
                        .font(.caption.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.yellow)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Post Tracking Card
    
    private var postTrackingCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("THIS MONTH'S POSTS")
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            
            Divider().background(Color.yellow.opacity(0.3))
            
            if let profile = currentProfile {
                // Progress Bar
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("\(profile.postsThisMonth) of 4 posts used")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(profile.remainingPosts()) remaining")
                            .font(.caption.bold())
                            .foregroundColor(profile.remainingPosts() > 0 ? .green : .orange)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 12)
                            
                            RoundedRectangle(cornerRadius: 10)
                                .fill(profile.postsThisMonth >= 4 ? Color.orange : Color.yellow)
                                .frame(width: geometry.size.width * (CGFloat(profile.postsThisMonth) / 4.0), height: 12)
                        }
                    }
                    .frame(height: 12)
                    
                    // Reset Date
                    if let lastReset = profile.lastResetDate {
                        let calendar = Calendar.current
                        let nextMonth = calendar.date(byAdding: .month, value: 1, to: lastReset) ?? Date()
                        let firstOfNextMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) ?? Date()
                        
                        Text("Resets on \(firstOfNextMonth.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - My Events Section
    
    private var myEventsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("MY EVENTS")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(userEvents.count)")
                    .font(.title3.bold())
                    .foregroundColor(.yellow)
            }
            
            Divider().background(Color.yellow.opacity(0.3))
            
            if userEvents.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No events posted yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(userEvents.prefix(5)) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        HStack(spacing: 12) {
                            // Thumbnail
                            if let data = event.imageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                                    .clipped()
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .foregroundColor(.yellow)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                if userEvents.count > 5 {
                    NavigationLink(destination: EventHomeView(initialMode: .list)) {
                        Text("VIEW ALL \(userEvents.count) EVENTS")
                            .font(.caption.bold())
                            .foregroundColor(.yellow)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Account Actions Section
    
    private var accountActionsSection: some View {
        VStack(spacing: 12) {
            // Restore Purchases
            Button(action: {
                Task {
                    await storeManager.restorePurchases()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Restore Purchases")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Sign Out
            Button(action: {
                showingSignOutAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.right.square")
                    Text("Sign Out")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func openSubscriptionSettings() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}
