//
//  PaymentSelectionView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import SwiftUI
import StoreKit
import SwiftData

struct PaymentSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @StateObject private var storeManager = StoreKitManager()
    @Binding var shouldNavigateToPost: Bool

    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingCreateProfile = false

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
        .sheet(isPresented: $showingCreateProfile) {
            CreateProfileView { name, email in
                let newProfile = UserProfile(
                    appleUserID: "device-\(UUID().uuidString)",
                    email: email.isEmpty ? "rider@onthaset.com" : email
                )
                newProfile.displayName = name
                newProfile.hasActiveSubscription = true
                newProfile.subscriptionStartDate = Date()
                modelContext.insert(newProfile)
                try? modelContext.save()
                print("✅ Profile created after subscription: \(name)")
                dismiss()
                shouldNavigateToPost = true
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
                        // No profile — show setup screen first
                        showingCreateProfile = true
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
}
