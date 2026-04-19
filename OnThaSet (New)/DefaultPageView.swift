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
    @State private var showingAdminLock = false
    @State private var secretTapCount = 0
    @State private var showingAbout = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    @State private var showingExtraPostSheet = false
    @State private var showingWelcomeSetup = false
    @State private var navigateToProfile = false

    private var currentProfile: UserProfile? { profiles.first }
    private var needsSetup: Bool {
        guard let p = currentProfile else { return false }
        return !p.hasCompletedSetup
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {

                        // BRANDED SHIELD HEADER
                        VStack(spacing: 0) {
                            ZStack {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 85))
                                    .foregroundColor(.yellow)
                                VStack(spacing: -2) {
                                    Text("ON").font(.system(size: 15, weight: .black)).foregroundColor(.black)
                                    Text("THA").font(.system(size: 12, weight: .black)).foregroundColor(.black)
                                    Text("SET").font(.system(size: 20, weight: .black)).foregroundColor(.black)
                                }
                                .offset(y: -4)
                            }
                            .onTapGesture(count: 5) {
                                showingAdminLock = true
                                secretTapCount = 0
                            }
                        }
                        .padding(.top, 50)
                        .padding(.bottom, 10)

                        // LOGO
                        Image("ONTHASET")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 280, height: 280)
                            .clipped()
                            .border(Color.yellow.opacity(0.5), width: 1)

                        Text("What's On Tha Set Nearby")
                            .font(.title2.bold())
                            .foregroundColor(.yellow)

                        // LIVE AD BANNER
                        LiveAdStripView()

                        // ACTION BUTTONS
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

                            // NATIONAL RUN CALENDAR
                            NavigationLink(destination: NationalRunCalendarView()) {
                                HStack {
                                    Image(systemName: "map.fill").font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("NATIONAL RUN CALENDAR")
                                            .font(.headline.bold())
                                        Text("Rallies • Annuals • Unity Runs • Charity")
                                            .font(.system(size: 9, weight: .bold))
                                            .opacity(0.8)
                                    }
                                    Spacer()
                                    Text("🗺️").font(.title3)
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .background(Color.yellow)
                                .cornerRadius(8)
                            }

                            NavigationLink(destination: WeatherView()) {
                                makeMenuButton(text: "RIDE FORECAST")
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                locationManager.requestLocation()
                            })

                            // MY ACCOUNT — profile hub with photo
                            Button(action: {
                                if needsSetup {
                                    showingWelcomeSetup = true
                                } else {
                                    navigateToProfile = true
                                }
                            }) {
                                HStack(spacing: 14) {
                                    // Profile photo
                                    ZStack {
                                        Circle()
                                            .fill(Color.yellow.opacity(0.2))
                                            .frame(width: 56, height: 56)
                                        if let profile = currentProfile,
                                           let data = profile.profileImageData,
                                           let img = UIImage(data: data) {
                                            Image(uiImage: img)
                                                .resizable().scaledToFill()
                                                .frame(width: 54, height: 54)
                                                .clipShape(Circle())
                                        } else if let profile = currentProfile,
                                                  !profile.profileImageURL.isEmpty,
                                                  let url = URL(string: profile.profileImageURL) {
                                            AsyncImage(url: url) { phase in
                                                if case .success(let img) = phase {
                                                    img.resizable().scaledToFill()
                                                        .frame(width: 54, height: 54)
                                                        .clipShape(Circle())
                                                } else {
                                                    Image(systemName: "person.fill")
                                                        .font(.title2).foregroundColor(.yellow)
                                                }
                                            }
                                        } else {
                                            Image(systemName: "person.fill")
                                                .font(.title2).foregroundColor(.yellow)
                                        }
                                    }
                                    .overlay(Circle().stroke(Color.yellow, lineWidth: 2))

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(currentProfile?.displayName.isEmpty == false ? currentProfile!.displayName : "MY ACCOUNT")
                                            .font(.headline.bold())
                                            .foregroundColor(.yellow)
                                        Text("Post Events • Photos • Bike Builds")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                        .foregroundColor(.yellow)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 40)

                        // ADVERTISE WITH US — premium glowing banner
                        NavigationLink(destination: AdvertiserSignupView()) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.yellow, lineWidth: 2)
                                    )
                                    .shadow(color: .yellow.opacity(0.5), radius: 12)

                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "megaphone.fill")
                                                .foregroundColor(.yellow).font(.title2)
                                            Text("ADVERTISE WITH US")
                                                .font(.headline.bold()).foregroundColor(.yellow)
                                        }
                                        Text("Reach thousands of riders across the community")
                                            .font(.caption).foregroundColor(.gray)
                                        HStack(spacing: 4) {
                                            Text("Plans from")
                                                .font(.caption2).foregroundColor(.gray)
                                            Text("$19.99/mo")
                                                .font(.caption2.bold()).foregroundColor(.yellow)
                                            Text("•")
                                                .font(.caption2).foregroundColor(.gray)
                                            Text("Basic")
                                                .font(.caption2).foregroundColor(.gray)
                                            Text("⭐ Featured")
                                                .font(.caption2).foregroundColor(.orange)
                                            Text("👑 Premium")
                                                .font(.caption2).foregroundColor(.yellow)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.yellow).font(.title3.bold())
                                }
                                .padding(.horizontal, 20).padding(.vertical, 16)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAbout = true }) {
                            Label("About On Tha Set", systemImage: "info.circle")
                        }
                        Button(action: { showingPrivacyPolicy = true }) {
                            Label("Privacy Policy", systemImage: "hand.raised")
                        }
                        Button(action: { showingTerms = true }) {
                            Label("Terms of Service", systemImage: "doc.text")
                        }
                        Button(action: { contactUs() }) {
                            Label("Contact Us", systemImage: "envelope")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.yellow)
                            .font(.title3)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToProfile) {
                MyAccountView()
                    .navigationBarBackButtonHidden(true)
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
                        price: "0.00",
                        latitude: 0.0,
                        longitude: 0.0,
                        postedByUserID: profiles.first?.appleUserID ?? "",
                        postedByName: profiles.first?.displayName ?? ""
                    ),
                    onSave: { newEvent in
                        if let profile = profiles.first {
                            newEvent.postedByUserID = profile.appleUserID
                            newEvent.postedByName = profile.displayName.isEmpty
                                ? profile.email
                                : profile.displayName
                        }
                        modelContext.insert(newEvent)
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
        .sheet(isPresented: $showingAdminLock) {
            AdminLockView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingExtraPostSheet) {
            ExtraPostPurchaseView(shouldNavigateToPost: $navigateToPost)
        }
        .onChange(of: navigateToPost) { oldValue, newValue in
            print("🔄 navigateToPost changed from \(oldValue) to \(newValue)")
        }
        .alert("Post Limit Reached", isPresented: $showingLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(limitAlertMessage)
        }
        .sheet(isPresented: $showingWelcomeSetup, onDismiss: {
            navigateToProfile = true
        }) {
            if let profile = currentProfile {
                WelcomeSetupView(profile: profile, onComplete: {
                    showingWelcomeSetup = false
                })
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showWelcomeSetup)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingWelcomeSetup = true
            }
        }
        .onAppear {
            if let profile = profiles.first {
                profile.hasActiveSubscription = storeManager.hasActiveSubscription
            }
            Task {
                await SupabaseManager.shared.fetchActiveAds()
                await SupabaseManager.shared.fetchAllEvents()
                // Sync: remove local events that no longer exist in Supabase
                let supabaseTitles = Set(SupabaseManager.shared.events.map { $0.title.lowercased() })
                if !supabaseTitles.isEmpty {
                    for event in allEvents {
                        if !supabaseTitles.contains(event.title.lowercased()) {
                            modelContext.delete(event)
                        }
                    }
                    try? modelContext.save()
                } else {
                    // No Supabase events — delete all local events
                    for event in allEvents { modelContext.delete(event) }
                    try? modelContext.save()
                }
            }
        }
    }

    func contactUs() {
        if let url = URL(string: "mailto:contact.onthaset@gmail.com?subject=On%20Tha%20Set%20Inquiry") {
            UIApplication.shared.open(url)
        }
    }

    func handlePostAttempt() {
        guard let profile = profiles.first else {
            showingPaymentSheet = true
            return
        }
        profile.hasActiveSubscription = storeManager.hasActiveSubscription
        if storeManager.purchasedProductIDs.contains("com.onthaset.singlepost") {
            navigateToPost = true
            return
        }
        if profile.hasActiveSubscription {
            profile.checkAndResetMonthlyCount()
            if profile.postsThisMonth >= 4 {
                showingExtraPostSheet = true
            } else {
                navigateToPost = true
            }
        } else {
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
