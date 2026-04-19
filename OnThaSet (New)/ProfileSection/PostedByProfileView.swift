//
//  PostedByProfileView.swift
//  OnThaSet (New)
//
//  Fetches the poster's profile from Supabase and displays
//  their full public profile including social media links.
//

import SwiftUI

// MARK: - Supabase User Profile Model

struct SupabaseUserProfile: Codable {
    var appleUserID: String
    var displayName: String
    var email: String
    var bio: String?
    var hometown: String?
    var club: String?
    var favoriteRide: String?
    var ridingSince: String?
    var preferredRideType: String?
    var favoriteRoute: String?
    var instagramHandle: String?
    var tiktokHandle: String?
    var youtubeChannel: String?
    var facebookHandle: String?
    var profileImageURL: String?
    var backgroundImageURL: String?

    enum CodingKeys: String, CodingKey {
        case appleUserID        = "apple_user_id"
        case displayName        = "display_name"
        case email
        case bio
        case hometown
        case club
        case favoriteRide       = "favorite_ride"
        case ridingSince        = "riding_since"
        case preferredRideType  = "preferred_ride_type"
        case favoriteRoute      = "favorite_route"
        case instagramHandle    = "instagram_handle"
        case tiktokHandle       = "tiktok_handle"
        case youtubeChannel     = "youtube_channel"
        case facebookHandle     = "facebook_handle"
        case profileImageURL    = "profile_image_url"
        case backgroundImageURL = "background_image_url"
    }
}

// MARK: - Supporting Models

struct PublicEventPhoto: Codable, Identifiable {
    var id: UUID?
    var uploadedBy: String
    var eventName: String?
    var caption: String?
    var imageURL: String
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case uploadedBy = "uploaded_by"
        case eventName = "event_name"
        case caption
        case imageURL = "image_url"
        case createdAt = "created_at"
    }
}

struct PublicBikeBuild: Codable, Identifiable {
    var id: UUID?
    var userID: String
    var modificationTitle: String
    var note: String
    var beforeImageURL: String
    var afterImageURL: String
    var bikeMake: String
    var bikeModel: String
    var bikeYear: String
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case modificationTitle = "modification_title"
        case note
        case beforeImageURL = "before_image_url"
        case afterImageURL = "after_image_url"
        case bikeMake = "bike_make"
        case bikeModel = "bike_model"
        case bikeYear = "bike_year"
        case createdAt = "created_at"
    }
}

// MARK: - PostedByProfileView

struct PostedByProfileView: View {
    let userID: String
    let posterName: String
    @Environment(\.dismiss) private var dismiss

    @State private var profile: SupabaseUserProfile? = nil
    @State private var eventPhotos: [PublicEventPhoto] = []
    @State private var bikeBuilds: [PublicBikeBuild] = []
    @State private var isLoading = true
    @State private var selectedPhotoURL: URL? = nil
    @State private var selectedPhotoImage: UIImage? = nil
    @State private var showingFullPhoto = false
    @State private var selectedPhotoIndex: Int = 0
    @State private var galleryPhotos: [URL] = []

    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
    private let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.yellow)
            } else if let profile = profile {
                profileContent(profile)
            } else {
                // Supabase returned data but decode failed — show basic profile
                profileContent(SupabaseUserProfile(
                    appleUserID: userID,
                    displayName: posterName,
                    email: ""
                ))
            }
        }
        .navigationTitle("Rider Profile")
        .navigationBarTitleDisplayMode(.inline)
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
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchProfile()
            await fetchEventPhotos()
            await fetchBikeBuilds()
        }
        .sheet(isPresented: $showingFullPhoto) {
            ZStack {
                Color.black.ignoresSafeArea()
                if !galleryPhotos.isEmpty {
                    TabView(selection: $selectedPhotoIndex) {
                        ForEach(galleryPhotos.indices, id: \.self) { index in
                            AsyncImage(url: galleryPhotos[index]) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable().scaledToFit()
                                case .failure:
                                    Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray)
                                default:
                                    ProgressView().tint(.yellow).scaleEffect(1.5)
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                } else {
                    ProgressView().tint(.yellow).scaleEffect(1.5)
                }
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showingFullPhoto = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 4)
                                .padding()
                        }
                    }
                    Spacer()
                    Text("\(selectedPhotoIndex + 1) / \(galleryPhotos.count)")
                        .font(.caption).foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 40)
                }
            }
            .presentationBackground(.black)
        }
    }

    // MARK: - Full Profile Content

    private func profileContent(_ p: SupabaseUserProfile) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {

                    // BACKGROUND — exact match to PublicProfileView backgroundSection
                ZStack {
                    if let bgURL = p.backgroundImageURL, !bgURL.isEmpty, let url = URL(string: bgURL) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                            } else {
                                LinearGradient(
                                    colors: [Color.yellow.opacity(0.3), Color.black],
                                    startPoint: .top, endPoint: .bottom
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                            }
                        }
                    } else {
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.3), Color.black],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                    }
                }

                // PROFILE PHOTO + NAME
                VStack(spacing: 10) {
                    if let imgURL = p.profileImageURL, !imgURL.isEmpty, let url = URL(string: imgURL) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.yellow, lineWidth: 3))
                                    .shadow(color: .yellow.opacity(0.4), radius: 8)
                            } else {
                                defaultAvatar
                            }
                        }
                    } else {
                        defaultAvatar
                    }

                    Text(p.displayName.isEmpty ? posterName : p.displayName)
                        .font(.title2.bold()).foregroundColor(.white)

                    if let club = p.club, !club.isEmpty {
                        Text(club)
                            .font(.caption.bold()).foregroundColor(.black)
                            .padding(.horizontal, 12).padding(.vertical, 4)
                            .background(Color.yellow).cornerRadius(20)
                    }
                }
                .offset(y: -50)
                .padding(.bottom, -30)

                // BIO
                if let bio = p.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline).foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                }

                // RIDING INFO
                let hasRidingInfo = !(p.favoriteRide ?? "").isEmpty ||
                                    !(p.ridingSince ?? "").isEmpty ||
                                    !(p.hometown ?? "").isEmpty ||
                                    !(p.preferredRideType ?? "").isEmpty

                if hasRidingInfo {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RIDING INFO")
                            .font(.caption.bold()).foregroundColor(.yellow)

                        if let ride = p.favoriteRide, !ride.isEmpty {
                            infoRow(icon: "motorcycle", label: "Ride", value: ride)
                        }
                        if let since = p.ridingSince, !since.isEmpty {
                            infoRow(icon: "flag.fill", label: "Riding Since", value: since)
                        }
                        if let hometown = p.hometown, !hometown.isEmpty {
                            infoRow(icon: "mappin.circle.fill", label: "Hometown", value: hometown)
                        }
                        if let rideType = p.preferredRideType, !rideType.isEmpty {
                            infoRow(icon: "road.lanes", label: "Ride Style", value: rideType)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }

                // SOCIAL LINKS
                let hasSocial = !(p.instagramHandle ?? "").isEmpty ||
                                !(p.tiktokHandle ?? "").isEmpty ||
                                !(p.youtubeChannel ?? "").isEmpty ||
                                !(p.facebookHandle ?? "").isEmpty

                if hasSocial {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SOCIAL MEDIA")
                            .font(.caption.bold()).foregroundColor(.yellow)

                        VStack(spacing: 10) {
                            if let ig = p.instagramHandle, !ig.isEmpty {
                                socialButton(icon: "camera.fill", color: .purple,
                                    label: "Instagram", handle: "Instagram",
                                    url: "https://instagram.com/\(ig)")
                            }
                            if let tt = p.tiktokHandle, !tt.isEmpty {
                                socialButton(icon: "music.note", color: .pink,
                                    label: "TikTok", handle: "TikTok",
                                    url: "https://tiktok.com/@\(tt)")
                            }
                            if let yt = p.youtubeChannel, !yt.isEmpty {
                                socialButton(icon: "play.rectangle.fill", color: .red,
                                    label: "YouTube", handle: "YouTube",
                                    url: "https://youtube.com/@\(yt)")
                            }
                            if let fb = p.facebookHandle, !fb.isEmpty {
                                socialButton(icon: "person.2.fill", color: .blue,
                                    label: "Facebook", handle: "Facebook",
                                    url: fb.hasPrefix("http") ? fb : "https://facebook.com/\(fb)")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }

                // EVENT PHOTOS
                if !eventPhotos.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "photo.on.rectangle").foregroundColor(.yellow)
                        Text("EVENT PHOTOS").font(.caption.bold()).foregroundColor(.yellow)
                        Spacer()
                        Text("\(eventPhotos.count)").font(.caption.bold()).foregroundColor(.yellow)
                    }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(eventPhotos) { photo in
                            if let url = URL(string: photo.imageURL) {
                                Button(action: {
                                    let allURLs = eventPhotos.compactMap { URL(string: $0.imageURL) }
                                    let idx = allURLs.firstIndex(of: url) ?? 0
                                    galleryPhotos = allURLs
                                    selectedPhotoIndex = idx
                                    showingFullPhoto = true
                                }) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img.resizable().scaledToFill()
                                                .frame(height: 90).clipped().cornerRadius(8)
                                        default:
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.05)).frame(height: 90)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    if !eventPhotos.isEmpty {
                        Text(eventPhotos.first?.eventName ?? "").font(.caption2).foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }

            // BIKE BUILDS
                if !bikeBuilds.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver").foregroundColor(.yellow)
                        Text("MY BIKE BUILDS").font(.caption.bold()).foregroundColor(.yellow)
                        Spacer()
                        Text("\(bikeBuilds.count)").font(.caption.bold()).foregroundColor(.yellow)
                    }
                    ForEach(bikeBuilds) { build in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(build.modificationTitle).font(.subheadline.bold()).foregroundColor(.white)
                            if !build.bikeMake.isEmpty {
                                Text("\(build.bikeYear) \(build.bikeMake) \(build.bikeModel)"
                                    .trimmingCharacters(in: .whitespaces))
                                    .font(.caption).foregroundColor(.yellow)
                            }
                            HStack(spacing: 8) {
                                if !build.beforeImageURL.isEmpty, let url = URL(string: build.beforeImageURL) {
                                    buildPhotoPanel(url: url, label: "BEFORE", color: .gray)
                                }
                                if !build.afterImageURL.isEmpty, let url = URL(string: build.afterImageURL) {
                                    buildPhotoPanel(url: url, label: "AFTER", color: .yellow)
                                }
                            }
                            if !build.note.isEmpty {
                                Text(build.note).font(.caption).foregroundColor(.gray)
                            }
                        }
                        .padding(10)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.bottom, 30)
            } else {
                Color.clear.frame(height: 30)
            }
                    } // end VStack(spacing: 0)
            } // end ScrollView
        } // end ZStack
    }

    // MARK: - Fallback

    private var fallbackView: some View {
        VStack(spacing: 20) {
            defaultAvatar
            Text(posterName.isEmpty ? "Community Member" : posterName)
                .font(.title2.bold()).foregroundColor(.white)
            Text("This rider hasn't set up their profile yet.")
                .font(.subheadline).foregroundColor(.gray)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
    }

    private var defaultAvatar: some View {
        ZStack {
            Circle().fill(Color.yellow.opacity(0.2)).frame(width: 100, height: 100)
            Image(systemName: "person.fill")
                .font(.system(size: 50)).foregroundColor(.yellow)
        }
    }

    // MARK: - Helper Views

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.yellow).frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundColor(.gray)
                Text(value).font(.subheadline).foregroundColor(.white)
            }
        }
    }

    private func socialButton(icon: String, color: Color, label: String, handle: String, url: String) -> some View {
        Button(action: { openURL(url) }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3).foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(color)
                    .cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.caption.bold()).foregroundColor(.gray)
                    Text(handle).font(.subheadline.bold()).foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption).foregroundColor(.gray)
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }

    private func buildPhotoPanel(url: URL, label: String, color: Color) -> some View {
        Button(action: {
            galleryPhotos = [url]
            selectedPhotoIndex = 0
            showingFullPhoto = true
        }) {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(maxWidth: .infinity).frame(height: 130)
                            .clipped().cornerRadius(8)
                    default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.05))
                            .frame(maxWidth: .infinity).frame(height: 130)
                    }
                }
                Text(label)
                    .font(.system(size: 9, weight: .black)).foregroundColor(.black)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(color).cornerRadius(4).padding(6)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Fetch Profile

    private func fetchProfile() async {
        print("🔍 PostedByProfileView: Looking up userID = '\(userID)'")

        guard !userID.isEmpty, !userID.hasPrefix("device-") else {
            print("⚠️ userID is empty or fake — skipping Supabase lookup")
            isLoading = false
            return
        }

        guard let url = URL(string: "\(projectURL)/rest/v1/users?apple_user_id=eq.\(userID)&limit=1") else {
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let rawString = String(data: data, encoding: .utf8) ?? "nil"
            print("📦 Supabase users response: \(rawString)")

            let decoder = JSONDecoder()
            // Note: do NOT use .convertFromSnakeCase here — CodingKeys handles mapping

            if let profiles = try? decoder.decode([SupabaseUserProfile].self, from: data),
               let first = profiles.first {
                print("✅ Decoded \(profiles.count) profile(s)")
                profile = first
            } else {
                // Full decode failed (likely missing columns) — decode base fields only
                struct BaseProfile: Codable {
                    var appleUserID: String
                    var displayName: String
                    var email: String
                    enum CodingKeys: String, CodingKey {
                        case appleUserID = "apple_user_id"
                        case displayName = "display_name"
                        case email
                    }
                }
                if let bases = try? JSONDecoder().decode([BaseProfile].self, from: data),
                   let base = bases.first {
                    print("✅ Decoded base profile for: \(base.displayName)")
                    profile = SupabaseUserProfile(
                        appleUserID: base.appleUserID,
                        displayName: base.displayName,
                        email: base.email
                    )
                } else {
                    print("❌ Could not decode any profile — using posterName fallback")
                    // Still set a minimal profile so profileContent shows instead of nil
                    profile = SupabaseUserProfile(
                        appleUserID: userID,
                        displayName: posterName,
                        email: ""
                    )
                }
            }
        } catch {
            print("❌ Failed to fetch poster profile: \(error)")
        }

        isLoading = false
    }

    private func fetchEventPhotos() async {
        guard !userID.isEmpty,
              let url = URL(string: "\(projectURL)/rest/v1/event_photos?uploaded_by=eq.\(userID)&order=created_at.desc&limit=50") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        if let (data, _) = try? await URLSession.shared.data(for: request),
           let photos = try? JSONDecoder().decode([PublicEventPhoto].self, from: data) {
            await MainActor.run { eventPhotos = photos }
            print("✅ Fetched \(photos.count) event photos for \(userID)")
        }
    }

    private func fetchBikeBuilds() async {
        guard !userID.isEmpty,
              let url = URL(string: "\(projectURL)/rest/v1/bike_builds?user_id=eq.\(userID)&order=created_at.desc") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        if let (data, _) = try? await URLSession.shared.data(for: request),
           let builds = try? JSONDecoder().decode([PublicBikeBuild].self, from: data) {
            await MainActor.run { bikeBuilds = builds }
            print("✅ Fetched \(builds.count) bike builds for \(userID)")
        }
    }

    private func openURL(_ urlString: String) {
        var formatted = urlString
        if !formatted.hasPrefix("http") { formatted = "https://\(formatted)" }
        if let url = URL(string: formatted) {
            UIApplication.shared.open(url)
        }
    }
}
