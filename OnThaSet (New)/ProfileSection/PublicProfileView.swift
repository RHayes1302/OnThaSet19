//
//  PublicProfileView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import SwiftUI
import SwiftData

struct PublicProfileView: View {
    let profile: UserProfile
    @Query(sort: \Event.date, order: .reverse) private var allEvents: [Event]
    @Query(sort: \EventPhoto.eventDate, order: .reverse) private var allPhotos: [EventPhoto]
    // Note: Update this sort key if BikeProgress has a different date property
    // Common property names: date, createdDate, timestamp, dateCreated
    @Query private var allBikeProgress: [BikeProgress]
    
    private var userEvents: [Event] {
        // Filter by user if you add userID to Event
        allEvents.prefix(6).map { $0 }
    }
    
    private var userPhotos: [EventPhoto] {
        // Filter photos by this user's ID
        allPhotos.filter { $0.userID == profile.appleUserID }.prefix(6).map { $0 }
    }
    
    private var userBikeProgress: [BikeProgress] {
        // Filter bike progress by this user's ID
        allBikeProgress.filter { $0.userID == profile.appleUserID }.prefix(6).map { $0 }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // BACKGROUND IMAGE (like MySpace profile background)
                    backgroundSection
                    
                    // PROFILE HEADER
                    profileHeaderSection
                        .offset(y: -50)
                    
                    // ABOUT ME SECTION
                    aboutMeSection
                        .padding(.horizontal)
                    
                    // STATS ROW
                    statsSection
                        .padding(.horizontal)
                    
                    // RIDING INFO
                    ridingInfoSection
                        .padding(.horizontal)
                    
                    // SOCIAL LINKS
                    socialLinksSection
                        .padding(.horizontal)
                    
                    // LATEST EVENTS
                    if !userEvents.isEmpty {
                        latestEventsSection
                            .padding(.horizontal)
                    }
                    
                    // PHOTO GALLERY
                    if !userPhotos.isEmpty {
                        photoGallerySection
                            .padding(.horizontal)
                    }
                    
                    // BIKE PROGRESS
                    if !userBikeProgress.isEmpty {
                        bikeProgressSection
                            .padding(.horizontal)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Background Section
    
    private var backgroundSection: some View {
        ZStack {
            if let data = profile.backgroundImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [Color.yellow.opacity(0.3), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeaderSection: some View {
        VStack(spacing: 15) {
            // Profile Picture
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(Color.yellow, lineWidth: 4)
                    )
                
                if let data = profile.profileImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                }
            }
            .shadow(radius: 10)
            
            // Name & Bio
            VStack(spacing: 5) {
                if !profile.displayName.isEmpty {
                    Text(profile.displayName)
                        .font(.title.bold())
                        .foregroundColor(.yellow)
                } else {
                    Text(profile.email.components(separatedBy: "@").first ?? "Rider")
                        .font(.title.bold())
                        .foregroundColor(.yellow)
                }
                
                if !profile.bio.isEmpty {
                    Text(profile.bio)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - About Me Section
    
    private var aboutMeSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(icon: "person.text.rectangle", title: "ABOUT ME")
            
            VStack(alignment: .leading, spacing: 10) {
                if !profile.hometown.isEmpty {
                    infoRow(icon: "house.fill", label: "Hometown", value: profile.hometown)
                }
                
                if !profile.club.isEmpty {
                    infoRow(icon: "person.3.fill", label: "Club", value: profile.club)
                }
                
                if !profile.favoriteRide.isEmpty {
                    infoRow(icon: "figure.outdoor.cycle", label: "Favorite Ride", value: profile.favoriteRide)
                }
                
                if !profile.ridingSince.isEmpty {
                    infoRow(icon: "calendar", label: "Riding Since", value: profile.ridingSince)
                }
                
                infoRow(
                    icon: "star.fill",
                    label: "Member Since",
                    value: profile.memberSince.formatted(date: .abbreviated, time: .omitted)
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .padding(.bottom, 15)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 20) {
            statBox(
                icon: "calendar.badge.plus",
                count: userEvents.count,
                label: "Events"
            )
            
            statBox(
                icon: "photo.fill",
                count: profile.totalPhotosPosted,
                label: "Photos"
            )
            
            statBox(
                icon: "wrench.and.screwdriver.fill",
                count: profile.totalBikeProgressPosts,
                label: "Updates"
            )
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .padding(.bottom, 15)
    }
    
    private func statBox(icon: String, count: Int, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
            
            Text("\(count)")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Riding Info Section
    
    private var ridingInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(icon: "bicycle", title: "RIDING INFO")
            
            VStack(alignment: .leading, spacing: 10) {
                if !profile.preferredRideType.isEmpty {
                    infoRow(icon: "person.2.fill", label: "Ride Style", value: profile.preferredRideType)
                }
                
                if !profile.favoriteRoute.isEmpty {
                    infoRow(icon: "map.fill", label: "Favorite Route", value: profile.favoriteRoute)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .padding(.bottom, 15)
    }
    
    // MARK: - Social Links Section
    
    private var socialLinksSection: some View {
        Group {
            if !profile.instagramHandle.isEmpty || !profile.tiktokHandle.isEmpty || !profile.youtubeChannel.isEmpty || !profile.facebookHandle.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    sectionHeader(icon: "link", title: "CONNECT")
                    
                    HStack(spacing: 15) {
                        if !profile.instagramHandle.isEmpty {
                            socialButton(
                                icon: "camera.fill",
                                color: .purple,
                                handle: "@\(profile.instagramHandle)",
                                url: "https://instagram.com/\(profile.instagramHandle)"
                            )
                        }
                        
                        if !profile.tiktokHandle.isEmpty {
                            socialButton(
                                icon: "music.note",
                                color: .pink,
                                handle: "@\(profile.tiktokHandle)",
                                url: "https://tiktok.com/@\(profile.tiktokHandle)"
                            )
                        }
                        
                        if !profile.youtubeChannel.isEmpty {
                            socialButton(
                                icon: "play.rectangle.fill",
                                color: .red,
                                handle: profile.youtubeChannel,
                                url: "https://youtube.com/@\(profile.youtubeChannel)"
                            )
                        }
                        
                        if !profile.facebookHandle.isEmpty {
                            socialButton(
                                icon: "person.2.fill",
                                color: .blue,
                                handle: "@\(profile.facebookHandle)",
                                url: "https://facebook.com/\(profile.facebookHandle)"
                            )
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(15)
                .padding(.bottom, 15)
            }
        }
    }
    
    private func socialButton(icon: String, color: Color, handle: String, url: String) -> some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(handle)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.2))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Latest Events Section
    
    private var latestEventsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(icon: "calendar", title: "LATEST EVENTS")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(userEvents) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        VStack(spacing: 8) {
                            if let data = event.imageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 100)
                                    .clipped()
                                    .cornerRadius(10)
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 100)
                            }
                            
                            Text(event.title)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .padding(.bottom, 15)
    }
    
    // MARK: - Photo Gallery Section
    
    private var photoGallerySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(icon: "photo.on.rectangle", title: "PHOTO GALLERY")
            
            if userPhotos.isEmpty {
                Text("No photos yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(userPhotos) { photo in
                        Button(action: {
                            // TODO: Show full-size photo in modal
                        }) {
                            Group {
                                if let imageData = loadPhotoImage(filename: photo.photoFileName) {
                                    Image(uiImage: imageData)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(8)
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            VStack {
                                                Image(systemName: "photo")
                                                    .foregroundColor(.yellow)
                                                Text(photo.eventName)
                                                    .font(.caption2)
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                            }
                                        )
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .padding(.bottom, 15)
    }
    
    // MARK: - Bike Progress Section
    
    private var bikeProgressSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(icon: "wrench.and.screwdriver", title: "BIKE PROGRESS")
            
            if userBikeProgress.isEmpty {
                Text("No bike updates yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(userBikeProgress) { progress in
                        Button(action: {
                            // TODO: Show full-size before/after in modal
                        }) {
                            VStack(spacing: 5) {
                                // Show AFTER image (the result)
                                if let afterImage = loadPhotoImage(filename: progress.afterImage) {
                                    Image(uiImage: afterImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 100)
                                        .clipped()
                                        .cornerRadius(8)
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 100)
                                        .overlay(
                                            Image(systemName: "wrench.and.screwdriver")
                                                .font(.title2)
                                                .foregroundColor(.yellow)
                                        )
                                }
                                
                                // Title
                                Text(progress.modificationTitle)
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                
                                // Bike info
                                if !progress.bikeMake.isEmpty {
                                    Text("\(progress.bikeYear) \(progress.bikeMake)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .padding(.bottom, 15)
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.yellow)
            
            Text(title)
                .font(.headline.bold())
                .foregroundColor(.white)
        }
    }
    
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.yellow)
                .frame(width: 20)
            
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.gray)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    // MARK: - Image Loading Helper
    
    private func loadPhotoImage(filename: String) -> UIImage? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsPath.appendingPathComponent(filename)
        
        if let imageData = try? Data(contentsOf: imagePath) {
            return UIImage(data: imageData)
        }
        return nil
    }
}
