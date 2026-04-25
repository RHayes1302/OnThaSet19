//
//  Gate.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/21/25.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct GatePage: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthService

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSigningIn = false
    @State private var showEmailAuth = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // LOGO
                ZStack {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 140))
                        .foregroundColor(.yellow)
                    VStack(spacing: -3) {
                        Text("ON").font(.system(size: 22, weight: .black))
                        Text("THA").font(.system(size: 18, weight: .black))
                        Text("SET").font(.system(size: 30, weight: .black))
                    }
                    .foregroundColor(.black)
                    .offset(y: -5)
                }

                // TITLE
                Text("SIGN IN TO POST")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)

                // SUBTITLE
                Text("Log in to manage your 4 monthly events and keep the community updated.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                if isSigningIn {
                    ProgressView()
                        .tint(.yellow)
                        .padding(.bottom, 8)
                }

                // SIGN IN WITH APPLE
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        handleAuthorization(authorization)
                    case .failure(let error):
                        print("❌ Sign in failed: \(error.localizedDescription)")
                        errorMessage = "Sign in failed: \(error.localizedDescription)"
                        showError = true
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .padding(.horizontal, 40)
                .disabled(isSigningIn)

                // DIVIDER
                HStack {
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    Text("or").font(.caption).foregroundColor(.gray)
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                }
                .padding(.horizontal, 40)

                // EMAIL / PASSWORD
                Button(action: { showEmailAuth = true }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Continue with Email")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.yellow)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow, lineWidth: 2)
                    )
                }
                .padding(.horizontal, 40)
                .disabled(isSigningIn)

                // DEMO MODE - App Review Access
                Button(action: createDemoProfile) {
                    Text("Explore Without Signing In")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .underline()
                }
                .padding(.bottom, 4)

                // GO BACK
                Button(action: { }) {
                    Text("GO BACK")
                        .font(.headline.bold())
                        .foregroundColor(.yellow)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.yellow, lineWidth: 2)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView()
                .environmentObject(authService)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Handle Apple Sign In

    private func handleAuthorization(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("❌ Failed to get credential")
            return
        }

        let userID = credential.user
        let email = credential.email ?? "no-email@placeholder.com"
        let displayName = [
            credential.fullName?.givenName,
            credential.fullName?.familyName
        ].compactMap { $0 }.joined(separator: " ")

        isSigningIn = true
        print("🔵 Apple Sign In userID: \(userID)")

        Task {
            await saveUserToSupabase(userID: userID, email: email, displayName: displayName)
            await syncProfileFromSupabase(userID: userID, email: email)
            authService.loginWithApple(userID: userID, email: email)
            isSigningIn = false
            print("✅ Sign in complete — currentUser.id: \(authService.currentUser?.id ?? "nil")")
        }
    }

    // MARK: - Sync Full Profile from Supabase

    private func syncProfileFromSupabase(userID: String, email: String) async {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

        guard let url = URL(string: "\(projectURL)/rest/v1/users?apple_user_id=eq.\(userID)&limit=1") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let userData = json.first else {
            print("⚠️ No Supabase profile found for userID: \(userID) — saving locally")
            saveUserLocally(userID: userID, email: email)
            return
        }

        print("✅ Supabase profile found for: \(userID)")

        let descriptor = FetchDescriptor<UserProfile>(predicate: #Predicate { $0.appleUserID == userID })
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        let profile: UserProfile
        let supabaseDisplayName = (userData["display_name"] as? String ?? "").trimmingCharacters(in: .whitespaces)
        let isReturningUser = !supabaseDisplayName.isEmpty

        if let found = existing.first {
            profile = found
            print("✅ Found existing local profile: \(profile.displayName)")
        } else {
            profile = UserProfile(appleUserID: userID, email: email)
            profile.hasCompletedSetup = isReturningUser
            modelContext.insert(profile)
            print("✅ Created new local profile for: \(userID)")
        }

        profile.appleUserID       = userID
        profile.email             = (userData["email"] as? String) ?? email
        profile.displayName       = (userData["display_name"] as? String) ?? profile.displayName
        profile.bio               = (userData["bio"] as? String) ?? ""
        profile.hometown          = (userData["hometown"] as? String) ?? ""
        profile.club              = (userData["club"] as? String) ?? ""
        profile.favoriteRide      = (userData["favorite_ride"] as? String) ?? ""
        profile.ridingSince       = (userData["riding_since"] as? String) ?? ""
        profile.preferredRideType = (userData["preferred_ride_type"] as? String) ?? ""
        profile.favoriteRoute     = (userData["favorite_route"] as? String) ?? ""
        profile.instagramHandle   = (userData["instagram_handle"] as? String) ?? ""
        profile.tiktokHandle      = (userData["tiktok_handle"] as? String) ?? ""
        profile.youtubeChannel    = (userData["youtube_channel"] as? String) ?? ""
        profile.facebookHandle    = (userData["facebook_handle"] as? String) ?? ""
        // Handle subscription — Supabase may return Bool or Int
        let subValue = userData["has_subscription"]
        if let boolVal = subValue as? Bool {
            profile.hasActiveSubscription = boolVal
        } else if let intVal = subValue as? Int {
            profile.hasActiveSubscription = intVal == 1
        } else {
            profile.hasActiveSubscription = false
        }
        print("✅ has_subscription raw: \(String(describing: subValue)) → \(profile.hasActiveSubscription)")

        // Always download images fresh from Supabase (works across devices)
        if let urlStr = userData["profile_image_url"] as? String,
           !urlStr.isEmpty,
           let imgURL = URL(string: urlStr),
           let (imgData, _) = try? await URLSession.shared.data(from: imgURL) {
            profile.profileImageData = imgData
            profile.profileImageURL = urlStr
            print("✅ Profile image downloaded from Supabase")
        }

        if let urlStr = userData["background_image_url"] as? String,
           !urlStr.isEmpty,
           let imgURL = URL(string: urlStr),
           let (imgData, _) = try? await URLSession.shared.data(from: imgURL) {
            profile.backgroundImageData = imgData
            profile.backgroundImageURL = urlStr
            print("✅ Background image downloaded from Supabase")
        }

        try? modelContext.save()

        await MainActor.run {
            if isReturningUser {
                UserDefaults.standard.set(true, forKey: "hasCompletedProfileSetup")
                profile.hasCompletedSetup = true
                print("✅ Returning user — setup complete")
            } else {
                UserDefaults.standard.set(false, forKey: "hasCompletedProfileSetup")
                profile.hasCompletedSetup = false
                print("🆕 New user — showing setup")
            }
        }
    }

    // MARK: - Save to Supabase

    private func saveUserToSupabase(userID: String, email: String, displayName: String) async {
        do {
            let existing: [[String: String]] = try await supabase
                .from("users").select("apple_user_id")
                .eq("apple_user_id", value: userID).execute().value
            if existing.isEmpty {
                try await supabase.from("users")
                    .insert(["apple_user_id": userID, "email": email, "display_name": displayName])
                    .execute()
            }
        } catch { print("❌ Supabase user save error: \(error)") }
    }

    // MARK: - Demo / Explore Without Signing In
    private func createDemoProfile() {
        let demoUserID = "demo-reviewer-user"
        let demoEmail = "reviewer@apple.com"

        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.appleUserID == demoUserID }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []

        if existing.isEmpty {
            let profile = UserProfile(appleUserID: demoUserID, email: demoEmail)
            profile.displayName = "Guest"
            profile.hasCompletedSetup = true
            modelContext.insert(profile)
            try? modelContext.save()
        } else {
            existing.first?.hasCompletedSetup = true
            try? modelContext.save()
        }

        authService.loginWithApple(userID: demoUserID, email: demoEmail)
    }

    // MARK: - Save Locally

    private func saveUserLocally(userID: String, email: String) {
        let descriptor = FetchDescriptor<UserProfile>(predicate: #Predicate { $0.appleUserID == userID })
        do {
            let existing = try modelContext.fetch(descriptor)
            if existing.isEmpty {
                let newProfile = UserProfile(appleUserID: userID, email: email)
                modelContext.insert(newProfile)
                try? modelContext.save()
                print("✅ Profile saved locally for: \(userID)")
            }
        } catch { print("❌ Local profile error: \(error)") }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let showWelcomeSetup = Notification.Name("showWelcomeSetup")
}
