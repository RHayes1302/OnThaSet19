//
//  WelcomeSetupView.swift
//  OnThaSet (New)
//
//  First-time profile setup — 4 steps with all profile fields

import SwiftUI
import PhotosUI

struct WelcomeSetupView: View {
    let profile: UserProfile
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var displayName = ""
    @State private var bio = ""
    @State private var hometown = ""
    @State private var favoriteRide = ""
    @State private var ridingSince = ""
    @State private var preferredRideType = ""
    @State private var favoriteRoute = ""
    @State private var club = ""
    @State private var instagramHandle = ""
    @State private var tiktokHandle = ""
    @State private var youtubeChannel = ""
    @State private var facebookHandle = ""
    @State private var profilePickerItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var backgroundPickerItem: PhotosPickerItem?
    @State private var backgroundImage: UIImage?
    @State private var isSaving = false
    @State private var currentStep = 0
    private let totalSteps = 4

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.white.opacity(0.1)).frame(height: 3)
                        Rectangle().fill(Color.yellow)
                            .frame(width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 3)
                            .animation(.easeInOut, value: currentStep)
                    }
                }
                .frame(height: 3)

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 6) {
                            ZStack {
                                Image(systemName: "shield.fill").font(.system(size: 55)).foregroundColor(.yellow)
                                VStack(spacing: -1) {
                                    Text("ON").font(.system(size: 7, weight: .black))
                                    Text("THA").font(.system(size: 6, weight: .black))
                                    Text("SET").font(.system(size: 9, weight: .black))
                                }.foregroundColor(.black).offset(y: -2)
                            }
                            Text("Welcome to On Tha Set!")
                                .font(.title2.bold()).foregroundColor(.white)
                            Text("Step \(currentStep + 1) of \(totalSteps) — \(stepTitle)")
                                .font(.caption).foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // Step content
                        switch currentStep {
                        case 0: stepOne
                        case 1: stepTwo
                        case 2: stepThree
                        case 3: stepFour
                        default: EmptyView()
                        }

                        // Nav buttons
                        HStack(spacing: 12) {
                            if currentStep > 0 {
                                Button(action: { withAnimation { currentStep -= 1 } }) {
                                    Text("Back").font(.headline).foregroundColor(.yellow)
                                        .frame(maxWidth: .infinity).frame(height: 50)
                                        .background(Color.yellow.opacity(0.15)).cornerRadius(12)
                                }
                            }
                            Button(action: {
                                if currentStep < totalSteps - 1 { withAnimation { currentStep += 1 } }
                                else { Task { await saveAndFinish() } }
                            }) {
                                HStack(spacing: 8) {
                                    if isSaving { ProgressView().tint(.black).scaleEffect(0.8) }
                                    Text(currentStep < totalSteps - 1 ? "Next →" : "Let's Ride! 🏍️")
                                        .font(.headline.bold()).foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(canProceed ? Color.yellow : Color.gray).cornerRadius(12)
                            }
                            .disabled(!canProceed || isSaving)
                        }
                        .padding(.horizontal)

                        Button(action: {
                            profile.hasCompletedSetup = true
                            try? modelContext.save()
                            UserDefaults.standard.set(true, forKey: "hasCompletedProfileSetup")
                            onComplete()
                        }) {
                            Text("Skip for now").font(.caption).foregroundColor(.gray)
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onChange(of: profilePickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    await MainActor.run { profileImage = img }
                }
            }
        }
        .onChange(of: backgroundPickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    await MainActor.run { backgroundImage = img }
                }
            }
        }
    }

    private var stepTitle: String {
        ["Photos & Name", "Your Ride", "Crew & Bio", "Social Media"][currentStep]
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0: return !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return !favoriteRide.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }

    // MARK: Step 1 - Photo & Name
    private var stepOne: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                if let bg = backgroundImage {
                    Image(uiImage: bg).resizable().scaledToFill()
                        .frame(maxWidth: .infinity).frame(height: 130).clipped().cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)).frame(height: 130)
                        .overlay(VStack(spacing: 4) {
                            Image(systemName: "photo").foregroundColor(.gray)
                            Text("Banner photo").font(.caption2).foregroundColor(.gray)
                        })
                }
                ZStack {
                    Circle().fill(Color.black).frame(width: 82, height: 82)
                    if let img = profileImage {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 78, height: 78).clipShape(Circle())
                    } else {
                        Circle().fill(Color.white.opacity(0.1)).frame(width: 78, height: 78)
                            .overlay(Image(systemName: "person.fill").foregroundColor(.yellow.opacity(0.6)).font(.largeTitle))
                    }
                }
                .offset(y: 38)
            }
            .padding(.bottom, 42)

            HStack(spacing: 10) {
                PhotosPicker(selection: $profilePickerItem, matching: .images) {
                    Label("Profile Photo", systemImage: "person.crop.circle.badge.plus")
                        .font(.caption.bold()).foregroundColor(.yellow)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.yellow.opacity(0.15)).cornerRadius(8)
                }
                PhotosPicker(selection: $backgroundPickerItem, matching: .images) {
                    Label("Banner Photo", systemImage: "photo.badge.plus")
                        .font(.caption.bold()).foregroundColor(.yellow)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.yellow.opacity(0.15)).cornerRadius(8)
                }
            }

            field(icon: "person.fill", placeholder: "Rider name (required)", text: $displayName)
        }
    }

    // MARK: Step 2 - Riding Info
    private var stepTwo: some View {
        VStack(spacing: 14) {
            field(icon: "motorcycle", placeholder: "What do you ride? e.g. Road Glide (required)", text: $favoriteRide)
            field(icon: "flag.fill", placeholder: "Riding since — year e.g. 2009", text: $ridingSince)
            field(icon: "location.fill", placeholder: "Hometown e.g. Las Vegas, NV", text: $hometown)
            field(icon: "map.fill", placeholder: "Favorite route or road (optional)", text: $favoriteRoute)

            VStack(alignment: .leading, spacing: 8) {
                Label("Preferred Ride Style", systemImage: "road.lanes").font(.caption.bold()).foregroundColor(.yellow)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(["Solo", "Group Rides", "Long Distance", "Track Days", "Weekend Warrior", "Any"], id: \.self) { style in
                        Button(action: { preferredRideType = style }) {
                            Text(style).font(.caption.bold())
                                .foregroundColor(preferredRideType == style ? .black : .white)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(preferredRideType == style ? Color.yellow : Color.white.opacity(0.08))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    // MARK: Step 3 - Club & Bio
    private var stepThree: some View {
        VStack(spacing: 14) {
            field(icon: "person.3.fill", placeholder: "Club or organization (optional)", text: $club)
            VStack(alignment: .leading, spacing: 6) {
                Label("Bio", systemImage: "text.quote").font(.caption.bold()).foregroundColor(.yellow)
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)).frame(minHeight: 120)
                    if bio.isEmpty {
                        Text("Tell the community about yourself...").foregroundColor(.gray.opacity(0.5)).padding(14).allowsHitTesting(false)
                    }
                    TextEditor(text: $bio)
                        .frame(minHeight: 120).padding(8)
                        .scrollContentBackground(.hidden).background(Color.clear)
                        .foregroundColor(.white).colorScheme(.dark)
                }
            }
        }
    }

    // MARK: Step 4 - Social Media
    private var stepFour: some View {
        VStack(spacing: 14) {
            Text("Connect your socials so other riders can follow you")
                .font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)

            socialField(icon: "camera.fill", color: Color(red: 0.8, green: 0.1, blue: 0.5),
                       placeholder: "Instagram username", text: $instagramHandle)
            socialField(icon: "music.note", color: .black,
                       placeholder: "TikTok username", text: $tiktokHandle)
            socialField(icon: "play.rectangle.fill", color: .red,
                       placeholder: "YouTube channel", text: $youtubeChannel)
            socialField(icon: "person.2.fill", color: .blue,
                       placeholder: "Facebook name or URL", text: $facebookHandle)
        }
    }

    // MARK: Helper Views
    private func field(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.yellow).frame(width: 20)
            TextField(placeholder, text: text).foregroundColor(.white)
        }
        .padding(14).background(Color.white.opacity(0.08)).cornerRadius(10)
    }

    private func socialField(icon: String, color: Color, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6).fill(color).frame(width: 28, height: 28)
                Image(systemName: icon).font(.caption.bold()).foregroundColor(.white)
            }
            TextField(placeholder, text: text).foregroundColor(.white)
                .autocapitalization(.none).autocorrectionDisabled()
        }
        .padding(14).background(Color.white.opacity(0.08)).cornerRadius(10)
    }

    // MARK: - Save and Finish
    private func saveAndFinish() async {
        await MainActor.run { isSaving = true }

        profile.displayName       = displayName
        profile.bio               = bio
        profile.hometown          = hometown
        profile.favoriteRide      = favoriteRide
        profile.ridingSince       = ridingSince
        profile.preferredRideType = preferredRideType
        profile.favoriteRoute     = favoriteRoute
        profile.club              = club
        profile.instagramHandle   = instagramHandle.replacingOccurrences(of: "@", with: "")
        profile.tiktokHandle      = tiktokHandle.replacingOccurrences(of: "@", with: "")
        profile.youtubeChannel    = youtubeChannel
        profile.facebookHandle    = facebookHandle
        profile.hasCompletedSetup = true
        UserDefaults.standard.set(true, forKey: "hasCompletedProfileSetup")

        // Upload profile image
        var profileImageURL: String? = nil
        if let img = profileImage, let data = img.jpegData(compressionQuality: 0.8) {
            profile.profileImageData = data
            profileImageURL = try? await SupabaseManager.shared.uploadImage(
                data: data, bucket: "profile-images", fileName: "profile-\(profile.appleUserID.lowercased()).jpg")
            if let url = profileImageURL {
                profile.profileImageURL = url
                print("✅ Profile image uploaded: \(url)")
            } else {
                print("❌ Profile image upload failed")
            }
        }

        // Upload background image
        var backgroundImageURL: String? = nil
        if let img = backgroundImage, let data = img.jpegData(compressionQuality: 0.8) {
            profile.backgroundImageData = data
            backgroundImageURL = try? await SupabaseManager.shared.uploadImage(
                data: data, bucket: "profile-images", fileName: "background-\(profile.appleUserID.lowercased()).jpg")
            if let url = backgroundImageURL {
                profile.backgroundImageURL = url
                print("✅ Background image uploaded: \(url)")
            } else {
                print("❌ Background image upload failed")
            }
        }

        try? modelContext.save()
        await saveToSupabase(profileImageURL: profileImageURL, backgroundImageURL: backgroundImageURL)
        await MainActor.run { isSaving = false }
        onComplete()
    }

    // MARK: - Save to Supabase
    private func saveToSupabase(profileImageURL: String?, backgroundImageURL: String?) async {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

        var body: [String: Any] = [
            "display_name":        displayName,
            "bio":                 bio,
            "hometown":            hometown,
            "favorite_ride":       favoriteRide,
            "riding_since":        ridingSince,
            "preferred_ride_type": preferredRideType,
            "favorite_route":      favoriteRoute,
            "club":                club,
            "instagram_handle":    instagramHandle.replacingOccurrences(of: "@", with: ""),
            "tiktok_handle":       tiktokHandle.replacingOccurrences(of: "@", with: ""),
            "youtube_channel":     youtubeChannel,
            "facebook_handle":     facebookHandle
        ]
        if let u = profileImageURL    { body["profile_image_url"]    = u }
        if let u = backgroundImageURL { body["background_image_url"] = u }

        let bodyData = try? JSONSerialization.data(withJSONObject: body)

        // Try 1 — PATCH by apple_user_id (lowercased to match Supabase)
        if let url = URL(string: "\(projectURL)/rest/v1/users?apple_user_id=eq.\(profile.appleUserID.lowercased())") {
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
            request.setValue("return=representation", forHTTPHeaderField: "Prefer")
            request.httpBody = bodyData

            if let (data, response) = try? await URLSession.shared.data(for: request) {
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                if status == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   !json.isEmpty {
                    print("✅ Profile saved to Supabase by apple_user_id")
                    return
                }
                print("📡 PATCH by apple_user_id — status: \(status)")
            }
        }

        // Try 2 — PATCH by email (fallback for email users)
        let encodedEmail = profile.email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? profile.email
        if let url = URL(string: "\(projectURL)/rest/v1/users?email=eq.\(encodedEmail)") {
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
            request.setValue("return=representation", forHTTPHeaderField: "Prefer")
            request.httpBody = bodyData

            if let (data, response) = try? await URLSession.shared.data(for: request) {
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                if status == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   !json.isEmpty {
                    print("✅ Profile saved to Supabase by email")
                    return
                }
                print("📡 PATCH by email — status: \(status)")
            }
        }

        // Try 3 — INSERT if neither PATCH worked (brand new user)
        if let url = URL(string: "\(projectURL)/rest/v1/users") {
            body["apple_user_id"] = profile.appleUserID.lowercased()
            body["email"] = profile.email
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
            request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            if let (_, response) = try? await URLSession.shared.data(for: request) {
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                print("📡 INSERT new user — status: \(status)")
                if status == 201 {
                    print("✅ New user inserted to Supabase")
                }
            }
        }
    }
}
