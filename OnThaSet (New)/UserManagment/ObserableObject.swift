//
//  ObserableObject.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/11/25.
//

import Foundation
import SwiftUI
import SwiftData

class AuthService: ObservableObject {
    @Published var currentUser: AppUser? = nil
    @Published var isLoading = false
    @Published var authError: String? = nil

    // Injected from app level for creating local profiles
    var modelContext: ModelContext?

    var isLoggedIn: Bool {
        currentUser != nil
    }

    // MARK: - Sign in with Apple
    func loginWithApple(userID: String, email: String) {
        currentUser = AppUser(
            id: userID,
            username: email.components(separatedBy: "@").first ?? "User",
            role: .member
        )
    }

    // MARK: - Email Sign Up (brand new user — show setup)
    func signUpWithEmail(email: String, password: String) async -> Bool {
        await MainActor.run { isLoading = true; authError = nil }

        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            let user = response.user
            let userID = user.id.uuidString

            await saveEmailUserToSupabase(userID: userID, email: email)
            await createLocalProfile(userID: userID, email: email, skipSetup: false)

            await MainActor.run {
                self.currentUser = AppUser(
                    id: userID,
                    username: email.components(separatedBy: "@").first ?? "User",
                    role: .member
                )
                self.isLoading = false
            }
            print("✅ Email sign up successful: \(user.id)")
            return true
        } catch {
            await MainActor.run {
                self.authError = error.localizedDescription
                self.isLoading = false
            }
            print("❌ Email sign up error: \(error)")
            return false
        }
    }

    // MARK: - Email Sign In (returning user — always skip setup)
    func signInWithEmail(email: String, password: String) async -> Bool {
        await MainActor.run { isLoading = true; authError = nil }

        // Set immediately — signing in means you already have an account
        UserDefaults.standard.set(true, forKey: "hasCompletedProfileSetup")

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            let user = session.user
            let userID = user.id.uuidString

            await syncOrCreateProfile(userID: userID, email: email)

            await MainActor.run {
                self.currentUser = AppUser(
                    id: userID,
                    username: email.components(separatedBy: "@").first ?? "User",
                    role: .member
                )
                self.isLoading = false
            }
            print("✅ Email sign in successful")
            return true
        } catch {
            UserDefaults.standard.set(false, forKey: "hasCompletedProfileSetup")
            await MainActor.run {
                self.authError = error.localizedDescription
                self.isLoading = false
            }
            print("❌ Email sign in error: \(error)")
            return false
        }
    }

    // MARK: - Fetch profile data from Supabase (email or apple_user_id)
    private func fetchProfileData(userID: String, email: String) async -> [String: Any]? {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

        // Try by email first
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
        if let url = URL(string: "\(projectURL)/rest/v1/users?email=eq.\(encodedEmail)&limit=1") {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
            if let (data, _) = try? await URLSession.shared.data(for: request),
               let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let first = json.first {
                print("✅ Found Supabase profile by email")
                return first
            }
        }

        // Try by apple_user_id as fallback
        if let url = URL(string: "\(projectURL)/rest/v1/users?apple_user_id=eq.\(userID.lowercased())&limit=1") {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
            if let (data, _) = try? await URLSession.shared.data(for: request),
               let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let first = json.first {
                print("✅ Found Supabase profile by apple_user_id")
                return first
            }
        }

        return nil
    }

    // MARK: - Sync or Create Profile (email login)
    private func syncOrCreateProfile(userID: String, email: String) async {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"
        _ = anonKey; _ = projectURL // suppress unused warnings

        // Fetch profile data using separate function — fixes Swift 6 concurrency warning
        let profileData: [String: Any]? = await fetchProfileData(userID: userID, email: email)

        // Download images BEFORE MainActor.run — fixes Swift 6 concurrency error
        let profileImageData: Data? = await {
            guard let urlStr = profileData?["profile_image_url"] as? String,
                  !urlStr.isEmpty,
                  let imgURL = URL(string: urlStr) else { return nil }
            let data = try? await URLSession.shared.data(from: imgURL).0
            if data != nil { print("✅ Downloaded profile image from Supabase") }
            return data
        }()

        let backgroundImageData: Data? = await {
            guard let urlStr = profileData?["background_image_url"] as? String,
                  !urlStr.isEmpty,
                  let imgURL = URL(string: urlStr) else { return nil }
            let data = try? await URLSession.shared.data(from: imgURL).0
            if data != nil { print("✅ Downloaded background image from Supabase") }
            return data
        }()

        await MainActor.run {
            guard let context = self.modelContext else { return }

            let descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { $0.appleUserID == userID }
            )
            let existing = (try? context.fetch(descriptor)) ?? []
            let profile: UserProfile

            if let found = existing.first {
                profile = found
                print("✅ Using existing local profile")
            } else {
                profile = UserProfile(appleUserID: userID, email: email)
                context.insert(profile)
                print("✅ Created new local profile")
            }

            // Sync all fields from Supabase
            if let data = profileData {
                profile.email             = (data["email"] as? String) ?? email
                profile.displayName       = (data["display_name"] as? String) ?? profile.displayName
                profile.bio               = (data["bio"] as? String) ?? ""
                profile.hometown          = (data["hometown"] as? String) ?? ""
                profile.club              = (data["club"] as? String) ?? ""
                profile.favoriteRide      = (data["favorite_ride"] as? String) ?? ""
                profile.ridingSince       = (data["riding_since"] as? String) ?? ""
                profile.preferredRideType = (data["preferred_ride_type"] as? String) ?? ""
                profile.favoriteRoute     = (data["favorite_route"] as? String) ?? ""
                profile.instagramHandle   = (data["instagram_handle"] as? String) ?? ""
                profile.tiktokHandle      = (data["tiktok_handle"] as? String) ?? ""
                profile.youtubeChannel    = (data["youtube_channel"] as? String) ?? ""
                profile.facebookHandle    = (data["facebook_handle"] as? String) ?? ""
                // Handle subscription — Supabase may return Bool or Int
                let subValue = data["has_subscription"]
                if let boolVal = subValue as? Bool {
                    profile.hasActiveSubscription = boolVal
                } else if let intVal = subValue as? Int {
                    profile.hasActiveSubscription = intVal == 1
                } else {
                    profile.hasActiveSubscription = false
                }

                // Store image URLs for future reference
                if let url = data["profile_image_url"] as? String { profile.profileImageURL = url }
                if let url = data["background_image_url"] as? String { profile.backgroundImageURL = url }
            }

            // Save downloaded images locally
            if let imgData = profileImageData { profile.profileImageData = imgData }
            if let bgData = backgroundImageData { profile.backgroundImageData = bgData }

            // Always skip setup on sign in
            profile.hasCompletedSetup = true
            UserDefaults.standard.set(true, forKey: "hasCompletedProfileSetup")

            try? context.save()
            print("✅ Profile synced with images: \(profile.displayName)")
        }
    }

    // MARK: - Save Email User to Supabase
    private func saveEmailUserToSupabase(userID: String, email: String) async {
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
                        "display_name": email.components(separatedBy: "@").first ?? "Rider"
                    ])
                    .execute()
                print("✅ Email user saved to Supabase: \(email)")
            } else {
                print("✅ Email user already exists in Supabase")
            }
        } catch {
            print("❌ Supabase email user save error: \(error)")
        }
    }

    // MARK: - Create Local Profile
    @MainActor
    private func createLocalProfile(userID: String, email: String, skipSetup: Bool) async {
        guard let context = modelContext else {
            print("⚠️ No modelContext in AuthService")
            return
        }

        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.appleUserID == userID }
        )
        let existing = (try? context.fetch(descriptor)) ?? []

        if existing.isEmpty {
            let profile = UserProfile(appleUserID: userID, email: email)
            profile.hasCompletedSetup = skipSetup
            UserDefaults.standard.set(skipSetup, forKey: "hasCompletedProfileSetup")
            context.insert(profile)
            try? context.save()
            print("✅ Local profile created — skipSetup: \(skipSetup)")
        } else {
            if skipSetup {
                existing.first?.hasCompletedSetup = true
                UserDefaults.standard.set(true, forKey: "hasCompletedProfileSetup")
                try? context.save()
            }
            print("✅ Existing local profile found")
        }
    }

    // MARK: - Password Reset
    func resetPassword(email: String) async -> Bool {
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            print("✅ Password reset email sent to \(email)")
            return true
        } catch {
            await MainActor.run { self.authError = error.localizedDescription }
            print("❌ Password reset error: \(error)")
            return false
        }
    }

    // MARK: - Logout
    func logout() {
        Task {
            try? await supabase.auth.signOut()
        }
        // ✅ Clear profile setup flag so next login starts fresh
        // This prevents the wrong profile from loading on account switch
        UserDefaults.standard.set(false, forKey: "hasCompletedProfileSetup")
        currentUser = nil
    }
}
