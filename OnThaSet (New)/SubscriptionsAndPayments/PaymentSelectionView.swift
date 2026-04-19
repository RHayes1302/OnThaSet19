//
//  PaymentSelectionView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import SwiftUI
import StoreKit
import SwiftData
import AuthenticationServices

struct PaymentSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @StateObject private var storeManager = StoreKitManager()
    @Binding var shouldNavigateToPost: Bool

    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSignIn = false
    @State private var pendingSubscriptionAfterSignIn = false

    private var currentProfile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // CLOSE BUTTON
                HStack {
                    Button(action: { dismiss() }) {
                        Text("Close")
                            .font(.title3)
                            .foregroundColor(.yellow)
                    }
                    Spacer()
                }
                .padding(.horizontal, 25)
                .padding(.top, 20)

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
                .padding(.bottom, 40)

                // CONTENT AREA
                if storeManager.isLoading && storeManager.products.isEmpty {
                    VStack(spacing: 20) {
                        ProgressView().tint(.yellow).scaleEffect(1.5)
                        Text("Loading...")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 100)

                } else if storeManager.products.isEmpty {
                    VStack(spacing: 30) {
                        Text("UNABLE TO LOAD")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.white)

                        Text("Could not connect to payment services. Please check your connection and try again.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Button(action: { Task { await storeManager.loadProducts() } }) {
                            Text("RETRY")
                                .font(.headline.bold())
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.yellow)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 100)

                } else {
                    VStack(spacing: 30) {
                        Text("CHOOSE YOUR PLAN")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.white)

                        Text("Select how you'd like to post events to the community.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        VStack(spacing: 20) {
                            // MONTHLY SUBSCRIPTION
                            if let subscription = storeManager.subscriptionProduct {
                                Button(action: { Task { await purchaseProduct(subscription) } }) {
                                    VStack(spacing: 10) {
                                        HStack {
                                            Image(systemName: "star.fill").font(.caption)
                                            Text("BEST VALUE").font(.caption.bold())
                                        }
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.yellow.opacity(0.3))
                                        .cornerRadius(12)

                                        Text("Monthly Subscription")
                                            .font(.title3.bold())
                                            .foregroundColor(.black)

                                        Text(subscription.displayPrice + "/month")
                                            .font(.title2.bold())
                                            .foregroundColor(.black)

                                        Text("4 posts per month • Cancel anytime")
                                            .font(.caption)
                                            .foregroundColor(.black.opacity(0.7))

                                        if let profile = currentProfile, !profile.displayName.isEmpty {
                                            HStack(spacing: 4) {
                                                Image(systemName: "person.circle.fill").font(.caption)
                                                Text("Links to: \(profile.displayName)").font(.caption)
                                            }
                                            .foregroundColor(.black.opacity(0.6))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 25)
                                    .background(Color.yellow)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal, 40)
                                .disabled(storeManager.isLoading)
                            }

                            Text("or").font(.subheadline).foregroundColor(.gray)

                            // SINGLE POST
                            if let singlePost = storeManager.singlePostProduct {
                                Button(action: { Task { await purchaseProduct(singlePost) } }) {
                                    VStack(spacing: 10) {
                                        Text("Single Event Post")
                                            .font(.title3.bold())
                                            .foregroundColor(.white)

                                        Text(singlePost.displayPrice)
                                            .font(.title2.bold())
                                            .foregroundColor(.yellow)

                                        Text("One-time payment • No account needed")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 25)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.yellow, lineWidth: 2)
                                    )
                                }
                                .padding(.horizontal, 40)
                                .disabled(storeManager.isLoading)
                            }
                        }
                    }
                }

                Spacer()

                // GO BACK
                Button(action: { dismiss() }) {
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
        .alert("Purchase Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if storeManager.isLoading && !storeManager.products.isEmpty {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: 15) {
                        ProgressView().tint(.yellow).scaleEffect(1.5)
                        Text("Processing...").foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSignIn) {
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
                        .foregroundColor(.black).offset(y: -4)
                    }
                    VStack(spacing: 8) {
                        Text("SIGN IN TO CONTINUE")
                            .font(.title2.bold()).foregroundColor(.white)
                        Text("Sign in with Apple to activate your subscription and start posting events.")
                            .font(.subheadline).foregroundColor(.gray)
                            .multilineTextAlignment(.center).padding(.horizontal, 40)
                    }
                    Spacer()
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            handlePostPurchaseSignIn(auth)
                        case .failure(let error):
                            print("❌ Sign in failed: \(error.localizedDescription)")
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
        }
    }

    // MARK: - Purchase Function

    private func purchaseProduct(_ product: Product) async {
        do {
            let transaction = try await storeManager.purchase(product)

            if transaction != nil {
                print("✅ Purchase completed: \(product.id)")

                if product.id == "com.onthaset.monthlysubscription" {
                    if let profile = currentProfile {
                        // Link to existing profile
                        profile.hasActiveSubscription = true
                        profile.subscriptionStartDate = Date()
                        try? modelContext.save()
                        print("✅ Subscription linked to profile: \(profile.displayName)")
                        dismiss()
                        shouldNavigateToPost = true
                    } else {
                        // No profile — show real Sign in with Apple
                        pendingSubscriptionAfterSignIn = true
                        showingSignIn = true
                    }
                } else {
                    // Single post — no profile needed
                    dismiss()
                    shouldNavigateToPost = true
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    // MARK: - Post-Purchase Sign In Handler

    private func handlePostPurchaseSignIn(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

        let userID = credential.user
        let email = credential.email ?? "no-email@placeholder.com"
        let displayName = [
            credential.fullName?.givenName,
            credential.fullName?.familyName
        ].compactMap { $0 }.joined(separator: " ")

        Task {
            // Save to Supabase
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

            // Save locally with subscription active
            let descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { $0.appleUserID == userID }
            )
            if let existing = try? modelContext.fetch(descriptor), existing.isEmpty {
                let profile = UserProfile(appleUserID: userID, email: email)
                if !displayName.isEmpty { profile.displayName = displayName }
                if pendingSubscriptionAfterSignIn {
                    profile.hasActiveSubscription = true
                    profile.subscriptionStartDate = Date()
                }
                modelContext.insert(profile)
                try? modelContext.save()
                print("✅ Profile created with subscription after Apple Sign In")
            } else if let profile = try? modelContext.fetch(descriptor).first,
                      pendingSubscriptionAfterSignIn {
                profile.hasActiveSubscription = true
                profile.subscriptionStartDate = Date()
                try? modelContext.save()
            }

            showingSignIn = false
            pendingSubscriptionAfterSignIn = false
            dismiss()
            shouldNavigateToPost = true
        }
    }
}
