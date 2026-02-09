//
//  PostedByProfileView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/8/26.
//

import SwiftUI
import SwiftData

struct PostedByProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProfiles: [UserProfile]
    
    let userID: String
    
    private var profile: UserProfile? {
        allProfiles.first { $0.appleUserID == userID }
    }
    
    var body: some View {
        Group {
            if let profile = profile {
                // Show the user's public profile
                PublicProfileView(profile: profile)
            } else {
                // Profile not found
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("Profile Not Found")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("This user's profile is not available.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
