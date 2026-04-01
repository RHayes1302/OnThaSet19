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

                // Loading indicator while signing in
                if isSigningIn {
                    ProgressView()
                        .tint(.yellow)
                        .padding(.bottom, 8)
                }

                // SIGN IN WITH APPLE BUTTON
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

                // GO BACK BUTTON
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
        print("🔵 Signing in: \(userID)")

        Task {
            await saveUserToSupabase(
                userID: userID,
                email: email,
                displayName: displayName
            )
            saveUserLocally(userID: userID, email: email)
            authService.loginWithApple(userID: userID, email: email)
            isSigningIn = false
            print("✅ Sign in complete")
        }
    }

    // MARK: - Save to Supabase

    private func saveUserToSupabase(
        userID: String,
        email: String,
        displayName: String
    ) async {
        do {
            // Check if user already exists in Supabase
            let existing: [[String: String]] = try await supabase
                .from("users")
                .select("apple_user_id")
                .eq("apple_user_id", value: userID)
                .execute()
                .value

            if existing.isEmpty {
                // New user — insert into Supabase
                try await supabase
                    .from("users")
                    .insert([
                        "apple_user_id": userID,
                        "email": email,
                        "display_name": displayName
                    ])
                    .execute()
                print("✅ New user saved to Supabase")
            } else {
                print("✅ Existing user found in Supabase")
            }
        } catch {
            print("❌ Supabase user save error: \(error)")
        }
    }

    // MARK: - Save Locally (SwiftData)

    private func saveUserLocally(userID: String, email: String) {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { profile in
                profile.appleUserID == userID
            }
        )
        do {
            let existing = try modelContext.fetch(descriptor)
            if existing.isEmpty {
                let newProfile = UserProfile(
                    appleUserID: userID,
                    email: email
                )
                modelContext.insert(newProfile)
                try? modelContext.save()
                print("✅ Profile saved locally")
            } else {
                print("✅ Local profile already exists")
            }
        } catch {
            print("❌ Local profile error: \(error)")
        }
    }
}
