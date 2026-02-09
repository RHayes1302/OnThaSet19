//
//  SimpleDebugView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import SwiftUI
import SwiftData

struct SimpleDebugView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    
    @State private var refreshTrigger = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("🐛 DEBUG MODE")
                        .font(.title.bold())
                        .foregroundColor(.red)
                        .padding(.top, 40)
                    
                    if let profile = profiles.first {
                        VStack(alignment: .leading, spacing: 15) {
                            Group {
                                debugRow("Email", profile.email)
                                debugRow("Apple ID", String(profile.appleUserID.prefix(20)) + "...")
                                debugRow("Has Subscription", profile.hasActiveSubscription ? "✅ YES" : "❌ NO")
                                debugRow("Posts This Month", "\(profile.postsThisMonth)/4")
                                debugRow("Remaining Posts", "\(profile.remainingPosts())")
                            }
                            
                            if let startDate = profile.subscriptionStartDate {
                                debugRow("Subscription Start", startDate.formatted(date: .abbreviated, time: .omitted))
                            }
                            
                            if let lastReset = profile.lastResetDate {
                                debugRow("Last Reset", lastReset.formatted(date: .abbreviated, time: .omitted))
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(15)
                        
                        // BUTTONS
                        VStack(spacing: 15) {
                            Button(action: {
                                profile.hasActiveSubscription = true
                                profile.subscriptionStartDate = Date()
                                profile.postsThisMonth = 0
                                profile.lastResetDate = Date()
                                
                                do {
                                    try modelContext.save()
                                    print("✅ ACTIVATED")
                                    refreshTrigger += 1
                                } catch {
                                    print("❌ ERROR: \(error)")
                                }
                            }) {
                                Text("✅ ACTIVATE SUBSCRIPTION")
                                    .font(.headline.bold())
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                profile.hasActiveSubscription = false
                                
                                do {
                                    try modelContext.save()
                                    print("❌ DEACTIVATED")
                                    refreshTrigger += 1
                                } catch {
                                    print("❌ ERROR: \(error)")
                                }
                            }) {
                                Text("❌ DEACTIVATE SUBSCRIPTION")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.7))
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                profile.postsThisMonth = 0
                                profile.lastResetDate = Date()
                                
                                do {
                                    try modelContext.save()
                                    print("🔄 RESET")
                                    refreshTrigger += 1
                                } catch {
                                    print("❌ ERROR: \(error)")
                                }
                            }) {
                                Text("🔄 RESET POST COUNT")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.7))
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("CLOSE")
                                    .font(.headline.bold())
                                    .foregroundColor(.yellow)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                        
                    } else {
                        Text("❌ NO PROFILE FOUND")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
        }
        .id(refreshTrigger) // Force refresh when changed
    }
    
    func debugRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.gray)
                .frame(width: 140, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}
