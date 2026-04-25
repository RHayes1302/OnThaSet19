//
//  AboutPage.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/4/25.
//

import SwiftUI
import SwiftData

struct AboutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService

    // ✅ Filter by logged in user
    private var currentProfile: UserProfile? {
        guard let userID = authService.currentUser?.id else { return nil }
        return profiles.first { $0.appleUserID == userID }
            ?? profiles.first { $0.appleUserID.lowercased() == userID.lowercased() }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        
                        // WE ACCEPT SECTION
                        VStack(alignment: .leading, spacing: 15) {
                            Text("WE ACCEPT")
                                .font(.caption.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.yellow)
                            
                            HStack(spacing: 15) {
                                VStack(spacing: 8) {
                                    HStack(spacing: 2) {
                                        Image(systemName: "applelogo")
                                            .font(.system(size: 14))
                                        Text("Pay")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .frame(height: 35)
                                    .padding(.horizontal, 10)
                                    .background(Color.white)
                                    .foregroundColor(.black)
                                    .cornerRadius(6)
                                    
                                    Text("Apple Pay")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)

                                PaymentIcon(icon: "v.circle.fill", label: "Venmo", color: .blue)
                                PaymentIcon(icon: "dollarsign.circle.fill", label: "Cash App", color: .green)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }

                        // YOUR ACCOUNT / POST TRACKER
                        if let profile = currentProfile {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("YOUR ACCOUNT")
                                    .font(.caption.bold())
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.yellow)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Logged in: \(profile.email)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        HStack {
                                            Text("Monthly Sets Posted")
                                            Spacer()
                                            Text("\(profile.postsThisMonth) / 4")
                                        }
                                        .font(.caption.bold())
                                        .foregroundColor(.yellow)
                                        
                                        ProgressView(value: Double(profile.postsThisMonth), total: 4.0)
                                            .tint(.yellow)
                                            .background(Color.gray.opacity(0.3))
                                            .scaleEffect(x: 1, y: 2, anchor: .center)
                                    }
                                    .padding(.top, 5)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                                
                                Button(action: { signOut() }) {
                                    Text("SIGN OUT")
                                        .font(.caption.bold())
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(Color.red, lineWidth: 1)
                                        )
                                }
                                .padding(.top, 5)
                            }
                        }

                        // MISSION SECTION
                        VStack(alignment: .leading, spacing: 10) {
                            Text("THE MISSION")
                                .font(.caption.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.yellow)
                            
                            Text("On-Tha-Set was developed by and for people who enjoy riding and spreading love throughout the motorcycle community. Our focus was to create a platform designed to bridge the gap between event organizers and local or traveling motorcycle enthusiasts. We believe in real-time connection to promote and increase your event's profits and attendance for a fraction of the cost compared to the traditional flyers of years prior.")
                                .foregroundColor(.white)
                                .font(.body)
                                .lineSpacing(4)
                        }
                        
                        Divider().background(Color.gray.opacity(0.3))
                        
                        // HOW TO USE SECTION
                        VStack(alignment: .leading, spacing: 15) {
                            Text("HOW TO USE")
                                .font(.caption.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.yellow)
                            
                            VStack(alignment: .leading, spacing: 18) {
                                FeatureRow(icon: "flame.fill", title: "Discover", desc: "Check for 'The Set' events while on the road, traveling, or looking for local MC-friendly establishments.")
                                FeatureRow(icon: "mappin.and.ellipse", title: "Locate", desc: "Find events within 50 miles of your current location.")
                                FeatureRow(icon: "plus.square.fill", title: "Share", desc: "Post your own events to the community.")
                            }
                        }
                        
                        Spacer(minLength: 50)
                        
                        // FOOTER
                        VStack(spacing: 4) {
                            Text("Version 1.0.0")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                            Text("© 2026 ON-THA-SET")
                                .font(.system(size: 10))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(30)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.yellow)
                    .font(.system(size: 20, weight: .bold))
            }
            
            Spacer()
            
            ZStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                VStack(spacing: -2) {
                    Text("ON").font(.system(size: 10, weight: .black))
                    Text("THA").font(.system(size: 8, weight: .black))
                    Text("SET").font(.system(size: 14, weight: .black))
                }
                .foregroundColor(.black)
                .offset(y: -2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.left").opacity(0)
        }
        .padding(.horizontal, 25)
        .padding(.top, 20)
    }
    
    func signOut() {
        authService.logout()
        dismiss()
    }
}

// --- HELPER VIEWS ---

struct FeatureRow: View {
    let icon: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .font(.system(size: 20))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct PaymentIcon: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(height: 35)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}
