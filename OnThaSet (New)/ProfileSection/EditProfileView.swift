//
//  EditProfileView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile
    
    @State private var profilePickerItem: PhotosPickerItem?
    @State private var backgroundPickerItem: PhotosPickerItem?
    @State private var isSaving = false
    @State private var showSaveError = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    Text("EDIT PROFILE")
                        .font(.title.bold())
                        .foregroundColor(.yellow)
                        .padding(.top, 20)
                    
                    // PROFILE & BACKGROUND IMAGES
                    imageSection
                    
                    // BASIC INFO
                    basicInfoSection
                    
                    // RIDING INFO
                    ridingInfoSection
                    
                    // SOCIAL LINKS
                    socialLinksSection
                    
                    // SAVE BUTTON
                    Button(action: {
                        Task { await saveProfile() }
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.black)
                            } else {
                                Text("SAVE PROFILE")
                                    .font(.headline.bold())
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(12)
                    }
                    .disabled(isSaving)
                    .padding(.bottom, 40)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Save Failed", isPresented: $showSaveError) {
            Button("OK") { }
        } message: {
            Text("Your profile was saved locally but could not sync to the server. It will retry next time.")
        }
        .onChange(of: profilePickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    profile.profileImageData = data
                }
            }
        }
        .onChange(of: backgroundPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    profile.backgroundImageData = data
                }
            }
        }
    }
    
    // MARK: - Image Section
    
    private var imageSection: some View {
        VStack(spacing: 20) {
            // Profile Picture
            VStack(spacing: 10) {
                Text("Profile Picture")
                    .font(.headline)
                    .foregroundColor(.white)
                
                PhotosPicker(selection: $profilePickerItem, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        if let data = profile.profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.yellow)
                        }
                        
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "camera.fill")
                                    .font(.caption)
                                    .foregroundColor(.black)
                                    .padding(8)
                                    .background(Color.yellow)
                                    .clipShape(Circle())
                                    .offset(x: -10, y: -10)
                            }
                        }
                        .frame(width: 120, height: 120)
                    }
                }
            }
            
            // Background Image
            VStack(spacing: 10) {
                Text("Background Image")
                    .font(.headline)
                    .foregroundColor(.white)
                
                PhotosPicker(selection: $backgroundPickerItem, matching: .images) {
                    ZStack {
                        if let data = profile.backgroundImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 150)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.title)
                                            .foregroundColor(.yellow)
                                        Text("Tap to add background")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(title: "BASIC INFO")
            
            fieldContainer(label: "Display Name") {
                TextField("Your name", text: $profile.displayName)
                    .textFieldStyle(ProfileTextFieldStyle())
            }
            
            fieldContainer(label: "Bio") {
                TextField("Tell us about yourself", text: $profile.bio, axis: .vertical)
                    .textFieldStyle(ProfileTextFieldStyle())
                    .lineLimit(3...5)
            }
            
            fieldContainer(label: "Hometown") {
                TextField("Where you're from", text: $profile.hometown)
                    .textFieldStyle(ProfileTextFieldStyle())
            }
            
            fieldContainer(label: "Club") {
                TextField("Motorcycle club (optional)", text: $profile.club)
                    .textFieldStyle(ProfileTextFieldStyle())
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
    
    // MARK: - Riding Info Section
    
    private var ridingInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(title: "RIDING INFO")
            
            fieldContainer(label: "Favorite Ride") {
                TextField("Your motorcycle", text: $profile.favoriteRide)
                    .textFieldStyle(ProfileTextFieldStyle())
            }
            
            fieldContainer(label: "Riding Since") {
                TextField("Year", text: $profile.ridingSince)
                    .textFieldStyle(ProfileTextFieldStyle())
                    .keyboardType(.numberPad)
            }
            
            fieldContainer(label: "Preferred Ride Type") {
                TextField("Solo, Group, Long Distance, etc.", text: $profile.preferredRideType)
                    .textFieldStyle(ProfileTextFieldStyle())
            }
            
            fieldContainer(label: "Favorite Route") {
                TextField("Your favorite place to ride", text: $profile.favoriteRoute)
                    .textFieldStyle(ProfileTextFieldStyle())
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
    
    // MARK: - Social Links Section
    
    private var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(title: "SOCIAL MEDIA")

            Text("Paste your full profile URL or just your username")
                .font(.caption).foregroundColor(.gray)

            socialField(
                label: "Instagram", icon: "camera.fill", iconColor: .purple,
                placeholder: "username or full URL",
                text: $profile.instagramHandle,
                previewPrefix: "instagram.com/"
            )

            socialField(
                label: "TikTok", icon: "music.note", iconColor: .pink,
                placeholder: "username or full URL",
                text: $profile.tiktokHandle,
                previewPrefix: "tiktok.com/@"
            )

            socialField(
                label: "YouTube", icon: "play.rectangle.fill", iconColor: .red,
                placeholder: "channel name or full URL",
                text: $profile.youtubeChannel,
                previewPrefix: "youtube.com/@"
            )

            socialField(
                label: "Facebook", icon: "person.2.fill", iconColor: .blue,
                placeholder: "Paste your full Facebook profile URL",
                text: $profile.facebookHandle,
                previewPrefix: ""
            )
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }

    private func socialField(
        label: String,
        icon: String,
        iconColor: Color,
        placeholder: String,
        text: Binding<String>,
        previewPrefix: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption).foregroundColor(iconColor)
                Text(label)
                    .font(.caption.bold()).foregroundColor(.gray)
            }

            TextField(placeholder, text: text)
                .textFieldStyle(ProfileTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: text.wrappedValue) { _, newValue in
                    // Strip to handle on the fly as user types
                    let cleaned = extractHandle(from: newValue)
                    if cleaned != newValue {
                        text.wrappedValue = cleaned
                    }
                }

            // Preview how it will look
            if !text.wrappedValue.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2).foregroundColor(.green)
                    Text(previewPrefix.isEmpty ? text.wrappedValue : "Will link to: \(previewPrefix)\(text.wrappedValue)")
                        .font(.caption2).foregroundColor(.green)
                        .lineLimit(1)
                }
            }
        }
    }

    /// Extracts just the handle/username from a full social media URL
    private func extractHandle(from input: String) -> String {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Facebook — keep full URL since short names can lead to wrong profiles
        if value.contains("facebook.com") || value.contains("fb.com") || value.contains("fb.me") {
            // Just ensure it has https:// prefix for proper linking
            if !value.hasPrefix("http") { value = "https://\(value)" }
            return value
        }

        // If it doesn't look like a URL, return as-is
        guard value.contains("://") || value.contains(".com/") else {
            return value.hasPrefix("@") ? String(value.dropFirst()) : value
        }

        // Remove URL scheme
        if let range = value.range(of: "://") {
            value = String(value[range.upperBound...])
        }

        // Remove www.
        value = value.replacingOccurrences(of: "www.", with: "")

        // Remove domain for non-Facebook platforms
        let domains = ["instagram.com/", "tiktok.com/@", "tiktok.com/",
                       "youtube.com/@", "youtube.com/"]
        for domain in domains {
            if value.hasPrefix(domain) {
                value = String(value.dropFirst(domain.count))
                break
            }
        }

        // Remove query parameters and fragments
        if let qIndex = value.firstIndex(of: "?") { value = String(value[..<qIndex]) }
        if let hIndex = value.firstIndex(of: "#") { value = String(value[..<hIndex]) }

        // Remove trailing slash
        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        // Remove leading @
        if value.hasPrefix("@") { value = String(value.dropFirst()) }

        return value
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.headline.bold())
            .foregroundColor(.yellow)
    }
    
    private func fieldContainer<Content: View>(label: String, icon: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(.gray)
            }
            content()
        }
    }

    // MARK: - Save to Supabase

    private func saveProfile() async {
        isSaving = true

        // Upload profile image
        var profileImageURL: String? = nil
        if let imageData = profile.profileImageData {
            let fileName = "profile-\(profile.appleUserID).jpg"
            profileImageURL = try? await SupabaseManager.shared.uploadImage(
                data: imageData, bucket: "profile-images", fileName: fileName
            )
            if let url = profileImageURL {
                profile.profileImageURL = url
                print("✅ Profile image uploaded: \(url)")
            } else {
                print("❌ Profile image upload failed — using existing URL: \(profile.profileImageURL)")
            }
        }

        // Upload background image
        var backgroundImageURL: String? = nil
        if let bgData = profile.backgroundImageData {
            let fileName = "background-\(profile.appleUserID).jpg"
            backgroundImageURL = try? await SupabaseManager.shared.uploadImage(
                data: bgData, bucket: "profile-images", fileName: fileName
            )
            if let url = backgroundImageURL {
                profile.backgroundImageURL = url
                print("✅ Background image uploaded: \(url)")
            } else {
                print("❌ Background image upload failed — using existing URL: \(profile.backgroundImageURL)")
            }
        }

        // Build update payload — always include current image URLs
        var body: [String: Any] = [
            "display_name":       profile.displayName,
            "bio":                profile.bio,
            "hometown":           profile.hometown,
            "club":               profile.club,
            "favorite_ride":      profile.favoriteRide,
            "riding_since":       profile.ridingSince,
            "preferred_ride_type": profile.preferredRideType,
            "favorite_route":     profile.favoriteRoute,
            "instagram_handle":   profile.instagramHandle,
            "tiktok_handle":      profile.tiktokHandle,
            "youtube_channel":    profile.youtubeChannel,
            "facebook_handle":    profile.facebookHandle
        ]

        // Use newly uploaded URL, or fall back to existing stored URL
        let finalProfileURL = profileImageURL ?? (profile.profileImageURL.isEmpty ? nil : profile.profileImageURL)
        let finalBackgroundURL = backgroundImageURL ?? (profile.backgroundImageURL.isEmpty ? nil : profile.backgroundImageURL)
        if let url = finalProfileURL    { body["profile_image_url"]    = url }
        if let url = finalBackgroundURL { body["background_image_url"] = url }

        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

        guard let url = URL(string: "\(projectURL)/rest/v1/users?apple_user_id=eq.\(profile.appleUserID)") else {
            isSaving = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status >= 200 && status < 300 {
                print("✅ Profile synced to Supabase")
            } else {
                print("⚠️ Supabase profile sync returned status \(status)")
                showSaveError = true
            }
        } catch {
            print("❌ Profile sync error: \(error)")
            showSaveError = true
        }

        isSaving = false
        dismiss()
    }
}

// MARK: - Text Field Style

struct ProfileTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}
