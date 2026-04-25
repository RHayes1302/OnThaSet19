//
//  MyAccountView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/8/26.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct MyAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @Query private var profiles: [UserProfile]
    @Query(sort: \Event.date, order: .reverse) private var allEvents: [Event]

    @State private var showingEditProfile = false
    @State private var showingPostEvent = false
    @State private var showingUploadPhoto = false
    @State private var isSigningIn = false
    @State private var showingUploadBikeProgress = false
    @State private var showingSettings = false
    @State private var showingWelcomeSetup = false
    @State private var showingPaymentSheet = false
    @StateObject private var storeManager = StoreKitManager()

    // ✅ Always filter by logged in user
    private var currentProfile: UserProfile? {
        guard let userID = authService.currentUser?.id else { return nil }
        return profiles.first { $0.appleUserID == userID }
            ?? profiles.first { $0.appleUserID.lowercased() == userID.lowercased() }
    }

    private var isNewUser: Bool {
        guard let profile = currentProfile else { return false }
        return !profile.hasCompletedSetup
    }

    var body: some View {
        Group {
            if let profile = currentProfile {
                ZStack {
                    PublicProfileView(profile: profile)

                    VStack {
                        Spacer()
                        actionButtonsOverlay
                            .padding(.bottom, 20)
                    }
                }
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: { showingEditProfile = true }) {
                                Label("Edit Profile", systemImage: "pencil")
                            }
                            Button(action: { showingSettings = true }) {
                                Label("Settings", systemImage: "gear")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .sheet(isPresented: $showingWelcomeSetup) {
                    WelcomeSetupView(profile: profile, onComplete: {
                        showingWelcomeSetup = false
                    })
                }
                .sheet(isPresented: $showingEditProfile) {
                    NavigationStack {
                        EditProfileView(profile: profile)
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    NavigationStack {
                        SettingsView()
                    }
                }
                .sheet(isPresented: $showingPostEvent) {
                    NavigationStack {
                        PostEventView()
                    }
                }
                .sheet(isPresented: $showingUploadPhoto) {
                    NavigationStack {
                        UploadEventPhotoView()
                    }
                }
                .sheet(isPresented: $showingUploadBikeProgress) {
                    NavigationStack {
                        UploadBikeProgressView()
                    }
                }
                .sheet(isPresented: $showingPaymentSheet) {
                    PaymentSelectionView(shouldNavigateToPost: $showingPostEvent)
                }
            } else {
                noProfileView
            }
        }
        .onAppear {
            if isNewUser {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingWelcomeSetup = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showWelcomeSetup)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingWelcomeSetup = true
            }
        }
    }

    // MARK: - No Profile View

    private var noProfileView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                ZStack {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.yellow)
                    VStack(spacing: -2) {
                        Text("ON").font(.system(size: 16, weight: .black))
                        Text("THA").font(.system(size: 12, weight: .black))
                        Text("SET").font(.system(size: 20, weight: .black))
                    }
                    .foregroundColor(.black)
                    .offset(y: -4)
                }

                VStack(spacing: 10) {
                    Text("Welcome to On Tha Set")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Sign in with Apple to post events and connect with the riding community.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                VStack(spacing: 15) {
                    if isSigningIn {
                        ProgressView()
                            .tint(.yellow)
                            .padding(.bottom, 8)
                    }
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            handleAppleSignIn(authorization)
                        case .failure(let error):
                            print("❌ Sign in failed: \(error.localizedDescription)")
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .padding(.horizontal, 40)
                    .disabled(isSigningIn)
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
        }
    }

    // MARK: - Apple Sign In Handler

    private func handleAppleSignIn(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

        let userID = credential.user
        let email = credential.email ?? "no-email@placeholder.com"
        let displayName = [
            credential.fullName?.givenName,
            credential.fullName?.familyName
        ].compactMap { $0 }.joined(separator: " ")

        isSigningIn = true

        Task {
            do {
                let existing: [[String: String]] = try await supabase
                    .from("users")
                    .select("apple_user_id")
                    .eq("apple_user_id", value: userID)
                    .execute()
                    .value

                if existing.isEmpty {
                    try await supabase
                        .from("users")
                        .insert([
                            "apple_user_id": userID,
                            "email": email,
                            "display_name": displayName
                        ])
                        .execute()
                }
            } catch {
                print("❌ Supabase error: \(error)")
            }

            let descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { $0.appleUserID == userID }
            )
            if let existing = try? modelContext.fetch(descriptor), existing.isEmpty {
                let profile = UserProfile(appleUserID: userID, email: email)
                if !displayName.isEmpty { profile.displayName = displayName }
                modelContext.insert(profile)
                try? modelContext.save()
            }

            authService.loginWithApple(userID: userID, email: email)
            isSigningIn = false
        }
    }

    // MARK: - Action Buttons Overlay

    private var actionButtonsOverlay: some View {
        VStack(spacing: 12) {
            if currentProfile != nil {
                subscriberActionButtons
            }
        }
    }

    private var subscriberActionButtons: some View {
        HStack(spacing: 12) {
            postEventButton
            uploadPhotoButton
            uploadBikeButton
        }
        .padding(.horizontal, 20)
    }

    private var postEventButton: some View {
        actionButton(icon: "plus.circle.fill", label: "Post Event", color: .yellow) {
            handlePostAttempt()
        }
    }

    private var uploadPhotoButton: some View {
        actionButton(icon: "camera.fill", label: "Event Photo", color: .purple) {
            handlePostAttempt(for: .photo)
        }
    }

    private var uploadBikeButton: some View {
        actionButton(icon: "wrench.and.screwdriver.fill", label: "Bike Build", color: .orange) {
            handlePostAttempt(for: .bike)
        }
    }

    enum PostType { case event, photo, bike }

    private func handlePostAttempt(for type: PostType = .event) {
        guard let profile = currentProfile else { showingPaymentSheet = true; return }
        let userID = authService.currentUser?.id

        let canPost: Bool = {
            // 1. Owner account — always can post
            if AppConfig.isOwner(userID) { return true }
            // 2. Demo accounts — bypass when review mode is ON
            if AppConfig.isDemoUser(userID) { return true }
            // 3. Paid single post or subscription
            return storeManager.purchasedProductIDs.contains("com.onthaset.singlepost") ||
                   storeManager.hasActiveSubscription ||
                   profile.hasActiveSubscription
        }()

        if canPost {
            switch type {
            case .event: showingPostEvent = true
            case .photo: showingUploadPhoto = true
            case .bike:  showingUploadBikeProgress = true
            }
        } else {
            showingPaymentSheet = true
        }
    }

    private func actionButton(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.black)
                Text(label)
                    .font(.caption2.bold())
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.5), radius: 5)
        }
    }
}


// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    @State private var showingSignOutAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            List {
                Section {
                    Button(action: { }) {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                    Button(action: {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("Manage Subscription", systemImage: "creditcard")
                    }
                }

                Section {
                    Button(role: .destructive, action: { showingSignOutAlert = true }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundColor(.yellow)
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.logout()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Post Event View

struct PostEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @Query private var profiles: [UserProfile]

    // ✅ Filter by logged in user
    private var currentProfile: UserProfile? {
        guard let userID = authService.currentUser?.id else { return nil }
        return profiles.first { $0.appleUserID == userID }
            ?? profiles.first { $0.appleUserID.lowercased() == userID.lowercased() }
    }

    var body: some View {
        if let profile = currentProfile {
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
                    postedByUserID: profile.appleUserID,
                    postedByName: profile.displayName.isEmpty
                        ? profile.email
                        : profile.displayName
                ),
                onSave: { newEvent in
                    newEvent.postedByUserID = profile.appleUserID
                    newEvent.postedByName = profile.displayName.isEmpty
                        ? profile.email
                        : profile.displayName
                    modelContext.insert(newEvent)
                    if profile.hasActiveSubscription {
                        profile.incrementPostCount()
                    }
                    try? modelContext.save()
                    dismiss()
                }
            )
        } else {
            ZStack {
                Color.black.ignoresSafeArea()
                Text("Please sign in to post events")
                    .foregroundColor(.white)
            }
        }
    }
}
