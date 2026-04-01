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
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query(sort: \Event.date, order: .reverse) private var allEvents: [Event]

    @State private var showingEditProfile = false
    @State private var showingPostEvent = false
    @State private var showingUploadPhoto = false
    @State private var showingUploadBikeProgress = false
    @State private var showingSettings = false
    @State private var showingCreateProfile = false

    private var currentProfile: UserProfile? {
        profiles.first
    }

    var body: some View {
        Group {
            if let profile = currentProfile {
                ZStack {
                    PublicProfileView(profile: profile)

                    VStack {
                        Spacer()
                        actionButtonsOverlay
                            .padding(.bottom, 20)
                    }
                }
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: { showingEditProfile = true }) {
                                Label("Edit Profile", systemImage: "pencil")
                            }
                            Button(action: { showingSettings = true }) {
                                Label("Settings", systemImage: "gear")
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
            } else {
                noProfileView
            }
        }
    }

    // MARK: - No Profile View

    private var noProfileView: some View {
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
                    .foregroundColor(.black)
                    .offset(y: -4)
                }

                VStack(spacing: 10) {
                    Text("Welcome to On Tha Set")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Sign in with Apple to post events and connect with the riding community.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                VStack(spacing: 15) {
                    Button(action: { showingCreateProfile = true }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("SET UP PROFILE").fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)

                    Text("Use Apple Sign In on your real iPhone for full access")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
        }
        .sheet(isPresented: $showingCreateProfile) {
            CreateProfileView { name, email in
                let profile = UserProfile(
                    appleUserID: "device-\(UUID().uuidString)",
                    email: email
                )
                profile.displayName = name
                profile.hasActiveSubscription = true
                modelContext.insert(profile)
                try? modelContext.save()
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
        actionButton(icon: "plus.circle.fill", label: "Post Event", color: .yellow) {
            showingPostEvent = true
        }
    }

    private var uploadPhotoButton: some View {
        actionButton(icon: "camera.fill", label: "Event Photo", color: .purple) {
            showingUploadPhoto = true
        }
    }

    private var uploadBikeButton: some View {
        actionButton(icon: "wrench.and.screwdriver.fill", label: "Bike Update", color: .orange) {
            showingUploadBikeProgress = true
        }
    }

    private func actionButton(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
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

// MARK: - Create Profile View

struct CreateProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, String) -> Void

    @State private var displayName = ""
    @State private var email = ""

    var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    ZStack {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.yellow)
                        VStack(spacing: -2) {
                            Text("ON").font(.system(size: 13, weight: .black))
                            Text("THA").font(.system(size: 10, weight: .black))
                            Text("SET").font(.system(size: 16, weight: .black))
                        }
                        .foregroundColor(.black)
                        .offset(y: -3)
                    }

                    Text("CREATE YOUR PROFILE")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    VStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("RIDER NAME")
                                .font(.caption.bold())
                                .foregroundColor(.yellow)
                            TextField("Your name or handle", text: $displayName)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("EMAIL (OPTIONAL)")
                                .font(.caption.bold())
                                .foregroundColor(.yellow)
                            TextField("your@email.com", text: $email)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                        }
                    }
                    .padding(.horizontal, 30)

                    Spacer()

                    Button(action: {
                        let emailToUse = email.isEmpty ? "rider@onthaset.com" : email
                        onSave(displayName, emailToUse)
                        dismiss()
                    }) {
                        Text("LET'S RIDE")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValid ? Color.yellow : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!isValid)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.yellow)
                }
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    @State private var showingSignOutAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            List {
                Section {
                    Button(action: { }) {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                    Button(action: {
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

// MARK: - Post Event View

struct PostEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    private var currentProfile: UserProfile? { profiles.first }

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
                    postedByName: profile.displayName.isEmpty
                        ? profile.email
                        : profile.displayName
                ),
                onSave: { newEvent in
                    newEvent.postedByUserID = profile.appleUserID
                    newEvent.postedByName = profile.displayName.isEmpty
                        ? profile.email
                        : profile.displayName
                    modelContext.insert(newEvent)
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
