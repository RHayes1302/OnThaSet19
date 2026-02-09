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
                
                // SIGN IN WITH APPLE BUTTON
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email]
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
                
                // GO BACK BUTTON
                Button(action: {
                    // Handle go back - dismiss or navigate
                }) {
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
        print("🔵 handleAuthorization called")
        
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("❌ Failed to get credential")
            return
        }
        
        let userID = credential.user
        let email = credential.email ?? "no-email@placeholder.com"
        
        print("🔵 User ID: \(userID)")
        print("🔵 Email: \(email)")
        
        // Check if profile already exists
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { profile in
                profile.appleUserID == userID
            }
        )
        
        do {
            let existingProfiles = try modelContext.fetch(descriptor)
            print("🔵 Found \(existingProfiles.count) existing profiles")
            
            if let existingProfile = existingProfiles.first {
                // User exists, just log them in
                print("✅ Existing user logged in")
                print("   Email: \(existingProfile.email)")
                print("   Has subscription: \(existingProfile.hasActiveSubscription)")
            } else {
                // Create new profile
                print("🔵 Creating new profile...")
                
                let newProfile = UserProfile(
                    appleUserID: userID,
                    email: email
                )
                
                print("🔵 Profile created in memory")
                print("   Apple ID: \(newProfile.appleUserID)")
                print("   Email: \(newProfile.email)")
                print("   Has subscription: \(newProfile.hasActiveSubscription)")
                
                modelContext.insert(newProfile)
                print("🔵 Profile inserted into context")
                
                do {
                    try modelContext.save()
                    print("✅ NEW USER CREATED AND SAVED!")
                    
                    // Verify it was saved
                    let verifyDescriptor = FetchDescriptor<UserProfile>()
                    let allProfiles = try modelContext.fetch(verifyDescriptor)
                    print("🔵 Total profiles in database: \(allProfiles.count)")
                    
                } catch {
                    print("❌ FAILED TO SAVE PROFILE: \(error)")
                    errorMessage = "Failed to create profile: \(error.localizedDescription)"
                    showError = true
                    return
                }
            }
            
            // Mark as logged in using Apple Sign In
            authService.loginWithApple(userID: userID, email: email)
            print("✅ User logged in via AuthService")
            
        } catch {
            print("❌ ERROR FETCHING PROFILES: \(error)")
            errorMessage = "Database error: \(error.localizedDescription)"
            showError = true
        }
    }
}
