//
//  MyAccountView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/8/26.
//

import SwiftUI
import SwiftData

struct MyAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \Event.date, order: .reverse) private var allEvents: [Event]
    @Query(sort: \EventPhoto.eventDate, order: .reverse) private var allPhotos: [EventPhoto]
    @Query private var allBikeProgress: [BikeProgress]
    
    @State private var showingEditProfile = false
    @State private var showingPostEvent = false
    @State private var showingUploadPhoto = false
    @State private var showingUploadBikeProgress = false
    @State private var showingSettings = false
    @State private var showingDebugScreen = false  // 🐛 DEBUG
    
    private var currentProfile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        Group {
            if let profile = currentProfile {
                ZStack {
                    // Show user's public profile as background
                    PublicProfileView(profile: profile)
                    
                    // Floating action buttons overlay
                    VStack {
                        Spacer()
                        
                        actionButtonsOverlay
                            .padding(.bottom, 20)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: { showingEditProfile = true }) {
                                Label("Edit Profile", systemImage: "pencil")
                            }
                            
                            Button(action: { showingSettings = true }) {
                                Label("Settings", systemImage: "gear")
                            }
                            
                            // 🐛 DEBUG - Remove for production
                            Button(action: { showingDebugScreen = true }) {
                                Label("Debug Subscription", systemImage: "ant.fill")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .sheet(isPresented: $showingEditProfile) {
                    NavigationStack {
                        EditProfileView(profile: profile)
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    NavigationStack {
                        SettingsView()
                    }
                }
                .sheet(isPresented: $showingPostEvent) {
                    NavigationStack {
                        PostEventView()
                    }
                }
                .sheet(isPresented: $showingUploadPhoto) {
                    NavigationStack {
                        UploadEventPhotoView()
                    }
                }
                .sheet(isPresented: $showingUploadBikeProgress) {
                    NavigationStack {
                        UploadBikeProgressView()
                    }
                }
                .fullScreenCover(isPresented: $showingDebugScreen) {
                    if let profile = currentProfile {
                        SimpleDebugView()
                    }
                }
            } else {
                // No profile - show sign in prompt
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 80))
                            .foregroundColor(.yellow)
                        
                        Text("No Profile Found")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        
                        Text("Please sign in to view your profile")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons Overlay
    
    private var actionButtonsOverlay: some View {
        VStack(spacing: 12) {
            if let profile = currentProfile, profile.hasActiveSubscription {
                subscriberActionButtons
            }
        }
    }
    
    private var subscriberActionButtons: some View {
        HStack(spacing: 12) {
            postEventButton
            uploadPhotoButton
            uploadBikeButton
        }
        .padding(.horizontal, 20)
    }
    
    private var postEventButton: some View {
        actionButton(
            icon: "plus.circle.fill",
            label: "Post Event",
            color: .yellow
        ) {
            showingPostEvent = true
        }
    }
    
    private var uploadPhotoButton: some View {
        actionButton(
            icon: "camera.fill",
            label: "Event Photo",
            color: .purple
        ) {
            showingUploadPhoto = true
        }
    }
    
    private var uploadBikeButton: some View {
        actionButton(
            icon: "wrench.and.screwdriver.fill",
            label: "Bike Update",
            color: .orange
        ) {
            showingUploadBikeProgress = true
        }
    }
    
    private func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.black)
                
                Text(label)
                    .font(.caption2.bold())
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.5), radius: 5)
        }
    }
}

// MARK: - Settings View (Placeholder)

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var showingSignOutAlert = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            List {
                Section {
                    Button(action: {
                        // Restore purchases
                    }) {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                    
                    Button(action: {
                        // Manage subscription
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("Manage Subscription", systemImage: "creditcard")
                    }
                }
                
                Section {
                    Button(role: .destructive, action: { showingSignOutAlert = true }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundColor(.yellow)
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.logout()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Placeholder Views

struct PostEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    
    private var currentProfile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        if let profile = currentProfile {
            AddEditEventView(
                eventToEdit: Event(
                    title: "",
                    date: Date(),
                    category: .community,
                    locationName: "",
                    details: "",
                    securityCode: "",
                    price: "0.00",
                    latitude: 0.0,
                    longitude: 0.0,
                    postedByUserID: profile.appleUserID,
                    postedByName: profile.displayName.isEmpty ? profile.email : profile.displayName
                ),
                onSave: { newEvent in
                    // Set poster info
                    newEvent.postedByUserID = profile.appleUserID
                    newEvent.postedByName = profile.displayName.isEmpty ? profile.email : profile.displayName
                    
                    modelContext.insert(newEvent)
                    
                    // Update post count for subscribers
                    if profile.hasActiveSubscription {
                        profile.incrementPostCount()
                    }
                    
                    try? modelContext.save()
                    dismiss()
                }
            )
        } else {
            ZStack {
                Color.black.ignoresSafeArea()
                Text("Please sign in to post events")
                    .foregroundColor(.white)
            }
        }
    }
}
