//
//  LoginView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @State private var isSigningIn = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {

                // BRANDED HIGHWAY SIGN LOGO
                VStack(spacing: -5) {
                    ZStack {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.yellow)
                        VStack(spacing: -2) {
                            Text("ON")
                                .font(.system(size: 16, weight: .black))
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

                // MESSAGING
                VStack(spacing: 10) {
                    Text("SIGN IN TO POST")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)

                    Text("Log in to manage your 4 monthly events and keep the community updated.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Loading indicator
                if isSigningIn {
                    ProgressView()
                        .tint(.yellow)
                }

                // APPLE SIGN IN
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    handleLogin(result: result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .padding(.horizontal, 40)
                .disabled(isSigningIn)

                // BACK BUTTON
                Button(action: { dismiss() }) {
                    Text("GO BACK")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .border(Color.yellow, width: 1)
                }
                .padding(.top, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.yellow)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    func handleLogin(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }

            let userID = credential.user
            let email = credential.email ?? "no-email@placeholder.com"
            let displayName = [
                credential.fullName?.givenName,
                credential.fullName?.familyName
            ].compactMap { $0 }.joined(separator: " ")

            isSigningIn = true

            Task {
                await saveToSupabase(
                    userID: userID,
                    email: email,
                    displayName: displayName
                )
                saveLocally(userID: userID, email: email)
                isSigningIn = false
                dismiss()
            }

        case .failure(let error):
            print("❌ Auth failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Save to Supabase

    private func saveToSupabase(
        userID: String,
        email: String,
        displayName: String
    ) async {
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
                print("✅ LoginView: New user saved to Supabase")
            } else {
                print("✅ LoginView: User already exists in Supabase")
            }
        } catch {
            print("❌ LoginView: Supabase error: \(error)")
        }
    }

    // MARK: - Save Locally

    private func saveLocally(userID: String, email: String) {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { profile in
                profile.appleUserID == userID
            }
        )
        do {
            let existing = try modelContext.fetch(descriptor)
            if existing.isEmpty {
                let newProfile = UserProfile(appleUserID: userID, email: email)
                modelContext.insert(newProfile)
                try? modelContext.save()
                print("✅ LoginView: Profile saved locally")
            }
        } catch {
            print("❌ LoginView: Local save error: \(error)")
        }
    }
}
