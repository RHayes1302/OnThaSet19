//
//  ExtraPostPurchaseView.swift
//  OnThaSet (New)
//

import SwiftUI
import SwiftData

struct ExtraPostPurchaseView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var shouldNavigateToPost: Bool
    @Query private var profiles: [UserProfile]
    @StateObject private var storeManager = StoreKitManager()
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var resetDate: String {
        let calendar = Calendar.current
        let now = Date()
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) else { return "next month" }
        var components = calendar.dateComponents([.year, .month], from: nextMonth)
        components.day = 1
        let firstOfMonth = calendar.date(from: components) ?? nextMonth
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM 1st"
        return formatter.string(from: firstOfMonth)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {

                        // HEADER
                        VStack(spacing: 12) {
                            ZStack {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 80)).foregroundColor(.yellow)
                                VStack(spacing: -2) {
                                    Text("ON").font(.system(size: 13, weight: .black))
                                    Text("THA").font(.system(size: 10, weight: .black))
                                    Text("SET").font(.system(size: 16, weight: .black))
                                }.foregroundColor(.black).offset(y: -3)
                            }

                            Text("POST LIMIT REACHED")
                                .font(.title2.bold()).foregroundColor(.yellow)

                            Text("You've used all 4 posts this month")
                                .font(.subheadline).foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)

                        // RESET INFO CARD
                        HStack(spacing: 15) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.title2).foregroundColor(.yellow)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("FREE POSTS RESET")
                                    .font(.caption.bold()).foregroundColor(.yellow)
                                Text("Your 4 free posts reset on \(resetDate)")
                                    .font(.subheadline).foregroundColor(.white)
                                Text("Or purchase additional posts below")
                                    .font(.caption).foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // PURCHASE OPTIONS
                        VStack(spacing: 15) {
                            Text("GET MORE POSTS NOW")
                                .font(.caption.bold()).foregroundColor(.yellow)

                            // SINGLE POST
                            Button(action: { Task { await purchaseSinglePost() } }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Single Post")
                                            .font(.headline.bold()).foregroundColor(.white)
                                        Text("Post one event right now")
                                            .font(.caption).foregroundColor(.gray)
                                    }
                                    Spacer()
                                    if isPurchasing {
                                        ProgressView().tint(.black)
                                            .padding(.horizontal, 20)
                                    } else {
                                        VStack(spacing: 2) {
                                            Text("$0.99")
                                                .font(.title3.bold()).foregroundColor(.black)
                                            Text("one time")
                                                .font(.caption2).foregroundColor(.black.opacity(0.7))
                                        }
                                        .padding(.horizontal, 16).padding(.vertical, 10)
                                        .background(Color.yellow).cornerRadius(10)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                                )
                            }
                            .disabled(isPurchasing)

                            // UPGRADE SUBSCRIPTION
                            VStack(spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Text("Monthly Subscription")
                                                .font(.headline.bold()).foregroundColor(.white)
                                            Text("BEST VALUE")
                                                .font(.system(size: 8, weight: .black))
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 6).padding(.vertical, 2)
                                                .background(Color.green).cornerRadius(4)
                                        }
                                        Text("4 posts every month — auto-renews")
                                            .font(.caption).foregroundColor(.gray)
                                        Text("Never run out of posts again")
                                            .font(.caption2).foregroundColor(.green)
                                    }
                                    Spacer()
                                    VStack(spacing: 2) {
                                        Text("$2.99")
                                            .font(.title3.bold()).foregroundColor(.black)
                                        Text("per month")
                                            .font(.caption2).foregroundColor(.black.opacity(0.7))
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                    .background(Color.green).cornerRadius(10)
                                }
                                .padding()
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.4), lineWidth: 1)
                                )
                            }

                            Text("Subscriptions managed through Apple ID settings")
                                .font(.caption2).foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)

                        // WAIT OPTION
                        Button(action: { dismiss() }) {
                            Text("I'll wait until \(resetDate)")
                                .font(.subheadline).foregroundColor(.gray)
                                .underline()
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.yellow).font(.title3.bold())
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Get More Posts").font(.caption.bold()).foregroundColor(.yellow)
                }
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Purchase Single Post
    private func purchaseSinglePost() async {
        isPurchasing = true
        do {
            await storeManager.loadProducts()
            if let product = storeManager.singlePostProduct {
                let transaction = try await storeManager.purchase(product)
                if transaction != nil {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        shouldNavigateToPost = true
                    }
                }
            } else {
                errorMessage = "Product not found. Please check your connection and try again."
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }
}
