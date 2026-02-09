//
//  DefaultPageView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/4/25.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct DefaultPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Event.date) private var allEvents: [Event]
    @Query private var profiles: [UserProfile]
    
    @ObservedObject private var locationManager = LocationManager.shared
    @StateObject private var storeManager = StoreKitManager()
    
    @State private var showingPaymentSheet = false
    @State private var showingLimitAlert = false
    @State private var navigateToPost = false
    @State private var limitAlertMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        
                        // 1. BRANDED HIGHWAY SHIELD HEADER
                        VStack(spacing: 0) {
                            ZStack {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 85))
                                    .foregroundColor(.yellow)
                                
                                VStack(spacing: -2) {
                                    Text("ON")
                                        .font(.system(size: 15, weight: .black))
                                        .foregroundColor(.black)
                                    Text("THA")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(.black)
                                    Text("SET")
                                        .font(.system(size: 20, weight: .black))
                                        .foregroundColor(.black)
                                }
                                .offset(y: -4)
                            }
                        }
                        .padding(.top, 50)
                        .padding(.bottom, 10)

                        // 2. LOGO PLACEHOLDER (Always visible)
                        Image("ONTHASET")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 280, height: 280)
                            .clipped()
                            .border(Color.yellow.opacity(0.5), width: 1)

                        Text("What's On Tha Set Nearby")
                            .font(.title2.bold())
                            .foregroundColor(.yellow)

                        // 3. ACTION BUTTONS
                        VStack(spacing: 12) {
                            
                            NavigationLink(destination: EventHomeView(initialMode: .list)) {
                                makeMenuButton(text: "VIEW POSTED EVENTS")
                            }

                            NavigationLink(destination: NearbyEventsView()) {
                                makeMenuButton(text: "EVENTS NEARBY")
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                locationManager.requestLocation()
                            })
                            
                            // NEW: WEATHER FORECAST BUTTON
                            NavigationLink(destination: WeatherView()) {
                                makeMenuButton(text: "RIDE FORECAST")
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                locationManager.requestLocation()
                            })

                            // POST EVENT BUTTON - WITH PAYMENT & LIMITS
                            Button(action: {
                                handlePostAttempt()
                            }) {
                                VStack(spacing: 4) {
                                    Text("POST EVENT")
                                        .font(.headline.bold())
                                    
                                    // Show status
                                    if let profile = profiles.first, profile.hasActiveSubscription {
                                        let remaining = profile.remainingPosts()
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption2)
                                            Text("\(remaining) post\(remaining == 1 ? "" : "s") remaining")
                                                .font(.caption2.bold())
                                        }
                                        .foregroundColor(remaining > 0 ? .green : .orange)
                                    } else {
                                        Text("$3 per post or $9/month")
                                            .font(.caption2)
                                            .foregroundColor(.black.opacity(0.7))
                                    }
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.yellow)
                                .cornerRadius(8)
                            }

                            NavigationLink(destination: AboutView()) {
                                makeMenuButton(text: "ABOUT")
                            }
                            
                            // 🆕 PROFILE/ACCOUNT BUTTON (moved below ABOUT)
                            NavigationLink(destination: MyAccountView()) {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title3)
                                    Text("MY ACCOUNT")
                                        .font(.headline.bold())
                                }
                                .foregroundColor(.yellow)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.yellow, lineWidth: 2)
                                )
                            }
                            
                            // 🔧 TEMPORARY DEBUG BUTTON - Remove after testing
                            Button(action: {
                                let testProfile = UserProfile(
                                    appleUserID: "TEST_USER_123",
                                    email: "test@test.com"
                                )
                                modelContext.insert(testProfile)
                                do {
                                    try modelContext.save()
                                    print("✅ Test profile created!")
                                } catch {
                                    print("❌ Failed to create test profile: \(error)")
                                }
                            }) {
                                Text("🔧 CREATE TEST PROFILE")
                                    .font(.headline.bold())
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToPost) {
                AddEditEventView(
                    eventToEdit: Event(
                        title: "",
                        date: Date(),
                        category: .community,
                        locationName: "",
                        details: "",
                        securityCode: "",
                        price: "0.00",  // No payment field - handled before this screen
                        latitude: 0.0,
                        longitude: 0.0,
                        postedByUserID: profiles.first?.appleUserID ?? "",
                        postedByName: profiles.first?.displayName ?? ""
                    ),
                    onSave: { newEvent in
                        // Set poster info if not already set
                        if let profile = profiles.first {
                            newEvent.postedByUserID = profile.appleUserID
                            newEvent.postedByName = profile.displayName.isEmpty ? profile.email : profile.displayName
                        }
                        
                        modelContext.insert(newEvent)
                        
                        // Update post count for subscribers
                        if let profile = profiles.first, profile.hasActiveSubscription {
                            profile.incrementPostCount()
                        }
                        
                        try? modelContext.save()
                    }
                )
            }
        }
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentSelectionView(shouldNavigateToPost: $navigateToPost)
        }
        .onChange(of: navigateToPost) { oldValue, newValue in
            print("🔄 navigateToPost changed from \(oldValue) to \(newValue)")
            if newValue {
                print("✅ Should now navigate to AddEditEventView")
            }
        }
        .alert("Post Limit Reached", isPresented: $showingLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(limitAlertMessage)
        }
        .onAppear {
            // Sync subscription status with StoreKit
            if let profile = profiles.first {
                profile.hasActiveSubscription = storeManager.hasActiveSubscription
            }
        }
    }

    // MARK: - Logic Helpers

    func handlePostAttempt() {
        guard let profile = profiles.first else {
            // No profile - shouldn't happen but handle gracefully
            showingPaymentSheet = true
            return
        }
        
        // Sync subscription status with StoreKit
        profile.hasActiveSubscription = storeManager.hasActiveSubscription
        
        // Check if user recently purchased a single post (consumable)
        // Single posts are consumable, so they allow one immediate post
        if storeManager.purchasedProductIDs.contains("com.onthaset.singlepost") {
            // User just bought a single post - let them post immediately
            navigateToPost = true
            return
        }
        
        // Check if user has active subscription
        if profile.hasActiveSubscription {
            // They have a subscription - check monthly limit
            profile.checkAndResetMonthlyCount()
            
            if profile.postsThisMonth >= 4 {
                // Hit monthly limit
                limitAlertMessage = "You've used all 4 posts for this month. Your posts will reset on the 1st of next month."
                showingLimitAlert = true
            } else {
                // Can post!
                navigateToPost = true
            }
        } else {
            // No subscription or single post - show payment options
            showingPaymentSheet = true
        }
    }

    func makeMenuButton(text: String) -> some View {
        Text(text)
            .font(.headline.bold())
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.yellow)
            .cornerRadius(8)
    }
}
