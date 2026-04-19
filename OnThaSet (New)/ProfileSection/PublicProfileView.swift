//
//  PublicProfileView.swift
//  OnThaSet (New)
//
//  Updated: 2/16/26 - Shows ALL photos (removed 6-photo limit)
//

//
//  PublicProfileView.swift
//  OnThaSet (New)
//
//  Updated: 2/16/26 - Shows ALL photos (removed 6-photo limit)
//

import SwiftUI
import SwiftData

struct PublicProfileView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Event.date, order: .reverse) private var allEvents: [Event]
    @Query(sort: \EventPhoto.eventDate, order: .reverse) private var allPhotos: [EventPhoto]
    @Query private var allBikeProgress: [BikeProgress]
    
    // State for photo expansion and deletion
    @State private var showingFullImage = false
    @State private var selectedImage: UIImage?
    @State private var galleryImages: [UIImage] = []
    @State private var galleryIndex: Int = 0
    @State private var showingGallery = false
    @State private var selectedPhoto: EventPhoto?
    @State private var selectedBikeEntry: BikeProgress?
    @State private var showingDeleteAlert = false
    
    // ✅ REMOVED .prefix(6) LIMIT - NOW SHOWS ALL PHOTOS
    private var userEvents: [Event] {
        allEvents.filter { event in
            // You can add user filtering here if needed
            true
        }
    }
    
    private var userPhotos: [EventPhoto] {
        // ✅ REMOVED .prefix(6) - Shows ALL photos
        allPhotos.filter { $0.userID == profile.appleUserID }
    }
    
    private var userBikeProgress: [BikeProgress] {
        // ✅ REMOVED .prefix(6) - Shows ALL bike mods
        allBikeProgress.filter { $0.userID == profile.appleUserID }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    backgroundSection
                    profileHeaderSection.offset(y: -50)
                    aboutMeSection.padding(.horizontal)
                    statsSection.padding(.horizontal)
                    ridingInfoSection.padding(.horizontal)
                    socialLinksSection.padding(.horizontal)

                    if !userEvents.isEmpty {
                        latestEventsSection.padding(.horizontal)
                    }

                    if !userPhotos.isEmpty {
                        photoGallerySection.padding(.horizontal)
                    }

                    if !userBikeProgress.isEmpty {
                        bikeProgressSection.padding(.horizontal)
                    }

                    // Bottom padding so floating action buttons don't overlap content
                    Color.clear.frame(height: 160)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingFullImage, onDismiss: {
            // Clear all state when dismissed
            selectedImage = nil
            selectedPhoto = nil
            selectedBikeEntry = nil
        }) {
            if let image = selectedImage {
                FullScreenImageView(
                    image: image,
                    onDelete: profile.hasActiveSubscription ? {
                        showingDeleteAlert = true
                    } : nil  // No delete button for non-subscribers
                )
                .alert("Delete This Photo?", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        deleteSelectedItem()
                    }
                } message: {
                    if selectedBikeEntry != nil {
                        Text("This will delete both the before and after photos. This cannot be undone.")
                    } else {
                        Text("Are you sure you want to delete this photo? This cannot be undone.")
                    }
                }
            }
        }
        .sheet(isPresented: $showingGallery) {
            ZStack {
                Color.black.ignoresSafeArea()
                TabView(selection: $galleryIndex) {
                    ForEach(galleryImages.indices, id: \.self) { index in
                        Image(uiImage: galleryImages[index])
                            .resizable().scaledToFit()
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showingGallery = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title).foregroundColor(.white)
                                .shadow(color: .black, radius: 4).padding()
                        }
                    }
                    Spacer()
                    Text("\(galleryIndex + 1) / \(galleryImages.count)")
                        .font(.caption).foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 40)
                }
            }
            .presentationBackground(.black)
        }
        .onChange(of: showingFullImage) { oldValue, newValue in
            print("📊 showingFullImage changed: \(oldValue) → \(newValue)")
            if newValue {
                print("   selectedImage: \(selectedImage != nil ? "SET" : "NIL")")
                print("   selectedPhoto: \(selectedPhoto?.photoFileName ?? "NIL")")
                print("   selectedBikeEntry: \(selectedBikeEntry?.modificationTitle ?? "NIL")")
            }
        }
    }
    
    // MARK: - Delete Selected Item
    
    private func deleteSelectedItem() {
        let imageStore = ImageFileStore()
        
        if let photoToDelete = selectedPhoto {
            imageStore.deleteIMG(fileName: photoToDelete.photoFileName)
            modelContext.delete(photoToDelete)
        }
        
        if let entryToDelete = selectedBikeEntry {
            imageStore.deleteIMG(fileName: entryToDelete.beforeImage)
            imageStore.deleteIMG(fileName: entryToDelete.afterImage)
            modelContext.delete(entryToDelete)
        }
        
        try? modelContext.save()
        
        showingFullImage = false
        selectedPhoto = nil
        selectedBikeEntry = nil
        selectedImage = nil
    }
    
    // MARK: - Photo Gallery Section (NOW SHOWS ALL PHOTOS)
    
    private var photoGallerySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                sectionHeader(icon: "photo.on.rectangle", title: "PHOTO GALLERY")
                Spacer()
                Text("\(userPhotos.count)").font(.headline.bold()).foregroundColor(.yellow)
            }

            if userPhotos.isEmpty {
                Text("No photos yet").font(.subheadline).foregroundColor(.gray)
                    .frame(maxWidth: .infinity).padding()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(userPhotos) { photo in
                        ZStack(alignment: .topTrailing) {
                            // Photo thumbnail
                            photoThumbnail(photo: photo)

                            // Delete button — always visible
                            Button(action: {
                                selectedPhoto = photo
                                showingDeleteAlert = true
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                                    .background(Color.black.clipShape(Circle()))
                                    .padding(4)
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
        .alert("Delete Photo?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { selectedPhoto = nil }
            Button("Delete", role: .destructive) {
                if let photo = selectedPhoto {
                    let url = photo.photoFileName
                    Task {
                        // Delete from storage
                        await SupabaseManager.shared.deleteStorageFile(imageURL: url, bucket: "event-photos")
                        // Delete from event_photos Supabase table
                        await SupabaseManager.shared.deleteEventPhotoRecord(imageURL: url, userID: profile.appleUserID)
                    }
                    profile.decrementPhotoCount()
                    modelContext.delete(photo)
                    try? modelContext.save()
                    selectedPhoto = nil
                }
            }
        } message: {
            Text("This will permanently delete this photo.")
        }
    }

    @ViewBuilder
    private func photoThumbnail(photo: EventPhoto) -> some View {
        if photo.photoFileName.hasPrefix("http"), let url = URL(string: photo.photoFileName) {
            Button(action: {
                // Build gallery from all event photos
                let allPhotos = (try? modelContext.fetch(FetchDescriptor<EventPhoto>())) ?? []
                let urls = allPhotos.compactMap { URL(string: $0.photoFileName) }
                let idx = allPhotos.firstIndex(where: { $0.photoFileName == photo.photoFileName }) ?? 0
                Task {
                    var images: [UIImage] = []
                    for u in urls {
                        if let (data, _) = try? await URLSession.shared.data(from: u),
                           let img = UIImage(data: data) { images.append(img) }
                    }
                    await MainActor.run {
                        galleryImages = images
                        galleryIndex = min(idx, max(0, images.count - 1))
                        selectedPhoto = photo
                        showingGallery = true
                    }
                }
            }) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(width: 100, height: 100).clipped().cornerRadius(8)
                    case .failure:
                        photoPlaceholder
                    default:
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05))
                                .frame(width: 100, height: 100)
                            ProgressView().tint(.yellow)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        } else if let img = loadPhotoImage(filename: photo.photoFileName) {
            Button(action: {
                selectedImage = img
                selectedPhoto = photo
                showingFullImage = true
            }) {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: 100, height: 100).clipped().cornerRadius(8)
            }
            .buttonStyle(.plain)
        } else {
            photoPlaceholder
        }
    }

    private var photoPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05))
            .frame(width: 100, height: 100)
            .overlay(Image(systemName: "photo").foregroundColor(.gray))
    }

    private var bikeProgressSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                sectionHeader(icon: "wrench.and.screwdriver", title: "MY BIKE BUILDS")
                Spacer()
                Text("\(userBikeProgress.count)")
                    .font(.headline.bold())
                    .foregroundColor(.yellow)
            }

            if userBikeProgress.isEmpty {
                Text("No bike builds yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(userBikeProgress) { progress in
                    BikeProgressCard(
                        entry: progress,
                        imageStore: ImageFileStore(),
                        onImageTap: { image in
                            selectedBikeEntry = progress
                            selectedImage = image
                            showingFullImage = true
                        },
                        onDelete: {
                            selectedBikeEntry = progress
                            showingDeleteAlert = true
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .padding(.bottom, 15)
        .alert("Delete Bike Build?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                selectedBikeEntry = nil
            }
            Button("Delete", role: .destructive) {
                if let entry = selectedBikeEntry {
                    let beforeURL = entry.beforeImage
                    let afterURL = entry.afterImage
                    Task {
                        await SupabaseManager.shared.deleteStorageFile(imageURL: beforeURL, bucket: "bike-progress")
                        await SupabaseManager.shared.deleteStorageFile(imageURL: afterURL, bucket: "bike-progress")
                        await SupabaseManager.shared.deleteBikeBuildRecord(afterImageURL: afterURL, userID: profile.appleUserID)
                    }
                    modelContext.delete(entry)
                    try? modelContext.save()
                    selectedBikeEntry = nil
                }
            }
        } message: {
            Text("This will delete both photos. This cannot be undone.")
        }
    }
    // [REST OF THE FILE STAYS THE SAME - ALL OTHER SECTIONS]
    // I'll include the helper sections below for completeness...
    
    private var backgroundSection: some View {
        ZStack {
            if let data = profile.backgroundImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable().scaledToFit().frame(maxWidth: .infinity)
            } else if !profile.backgroundImageURL.isEmpty, let url = URL(string: profile.backgroundImageURL) {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFit().frame(maxWidth: .infinity)
                    } else {
                        LinearGradient(colors: [Color.yellow.opacity(0.3), Color.black], startPoint: .top, endPoint: .bottom)
                            .frame(maxWidth: .infinity).frame(height: 220)
                    }
                }
            } else {
                LinearGradient(colors: [Color.yellow.opacity(0.3), Color.black], startPoint: .top, endPoint: .bottom)
                    .frame(maxWidth: .infinity).frame(height: 220)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle().fill(Color.black).frame(width: 120, height: 120).overlay(Circle().stroke(Color.yellow, lineWidth: 4))
                if let data = profile.profileImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 110, height: 110).clipShape(Circle())
                } else if !profile.profileImageURL.isEmpty, let url = URL(string: profile.profileImageURL) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill().frame(width: 110, height: 110).clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill").font(.system(size: 50)).foregroundColor(.yellow)
                        }
                    }
                } else {
                    Image(systemName: "person.fill").font(.system(size: 50)).foregroundColor(.yellow)
                }
            }
            .shadow(radius: 10)
            VStack(spacing: 5) {
                if !profile.displayName.isEmpty {
                    Text(profile.displayName).font(.title.bold()).foregroundColor(.yellow)
                } else {
                    Text(profile.email.components(separatedBy: "@").first ?? "Rider").font(.title.bold()).foregroundColor(.yellow)
                }
                if !profile.bio.isEmpty {
                    Text(profile.bio).font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 40)
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    private var aboutMeSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(icon: "person.text.rectangle", title: "ABOUT ME")
            VStack(alignment: .leading, spacing: 10) {
                if !profile.hometown.isEmpty { infoRow(icon: "house.fill", label: "Hometown", value: profile.hometown) }
                if !profile.club.isEmpty { infoRow(icon: "person.3.fill", label: "Club", value: profile.club) }
                if !profile.favoriteRide.isEmpty { infoRow(icon: "figure.outdoor.cycle", label: "Favorite Ride", value: profile.favoriteRide) }
                if !profile.ridingSince.isEmpty { infoRow(icon: "calendar", label: "Riding Since", value: profile.ridingSince) }
                infoRow(icon: "star.fill", label: "Member Since", value: profile.memberSince.formatted(date: .abbreviated, time: .omitted))
            }
        }.padding().background(Color.white.opacity(0.05)).cornerRadius(15).padding(.bottom, 15)
    }
    
    private var statsSection: some View {
        HStack(spacing: 20) {
            statBox(icon: "calendar.badge.plus", count: userEvents.count, label: "Events")
            photoStatBox
            statBox(icon: "wrench.and.screwdriver.fill", count: userBikeProgress.count, label: "Builds")
        }.padding().background(Color.white.opacity(0.05)).cornerRadius(15).padding(.bottom, 15)
    }

    private var photoStatBox: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.fill").font(.title2).foregroundColor(.yellow)
            Text("\(profile.photosStoredTotal)/\(UserProfile.totalPhotoLimit)")
                .font(.title3.bold()).foregroundColor(.white)
            Text("Photos").font(.caption2).foregroundColor(.gray)
        }.frame(maxWidth: .infinity)
    }
    
    private func statBox(icon: String, count: Int, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(.yellow)
            Text("\(count)").font(.title3.bold()).foregroundColor(.white)
            Text(label).font(.caption2).foregroundColor(.gray)
        }.frame(maxWidth: .infinity)
    }
    
    private var ridingInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(icon: "bicycle", title: "RIDING INFO")
            VStack(alignment: .leading, spacing: 10) {
                if !profile.preferredRideType.isEmpty { infoRow(icon: "person.2.fill", label: "Ride Style", value: profile.preferredRideType) }
                if !profile.favoriteRoute.isEmpty { infoRow(icon: "map.fill", label: "Favorite Route", value: profile.favoriteRoute) }
            }
        }.padding().background(Color.white.opacity(0.05)).cornerRadius(15).padding(.bottom, 15)
    }
    
    private var socialLinksSection: some View {
        Group {
            if !profile.instagramHandle.isEmpty || !profile.tiktokHandle.isEmpty || !profile.youtubeChannel.isEmpty || !profile.facebookHandle.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    sectionHeader(icon: "link", title: "CONNECT")
                    HStack(spacing: 15) {
                        if !profile.instagramHandle.isEmpty { socialButton(icon: "camera.fill", color: .purple, handle: "Instagram", url: "https://instagram.com/\(profile.instagramHandle)") }
                        if !profile.tiktokHandle.isEmpty { socialButton(icon: "music.note", color: .pink, handle: "TikTok", url: "https://tiktok.com/@\(profile.tiktokHandle)") }
                        if !profile.youtubeChannel.isEmpty { socialButton(icon: "play.rectangle.fill", color: .red, handle: "YouTube", url: "https://youtube.com/@\(profile.youtubeChannel)") }
                        if !profile.facebookHandle.isEmpty { socialButton(icon: "person.2.fill", color: .blue, handle: "Facebook", url: profile.facebookHandle.hasPrefix("http") ? profile.facebookHandle : "https://facebook.com/\(profile.facebookHandle)") }
                    }
                }.padding().background(Color.white.opacity(0.05)).cornerRadius(15).padding(.bottom, 15)
            }
        }
    }
    
    private func socialButton(icon: String, color: Color, handle: String, url: String) -> some View {
        Button(action: { if let url = URL(string: url) { UIApplication.shared.open(url) } }) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2).foregroundColor(color)
                Text(handle).font(.caption2).foregroundColor(.white).lineLimit(1)
            }.frame(maxWidth: .infinity).padding().background(color.opacity(0.2)).cornerRadius(10)
        }
    }
    
    private var latestEventsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(icon: "calendar", title: "LATEST EVENTS")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(userEvents.prefix(6)) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        VStack(spacing: 8) {
                            if let data = event.imageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage).resizable().scaledToFill().frame(height: 100).clipped().cornerRadius(10)
                            } else {
                                RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)).frame(height: 100)
                            }
                            Text(event.title).font(.caption.bold()).foregroundColor(.white).lineLimit(2)
                        }
                    }
                }
            }
        }.padding().background(Color.white.opacity(0.05)).cornerRadius(15).padding(.bottom, 15)
    }
    
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon).font(.title3).foregroundColor(.yellow)
            Text(title).font(.headline.bold()).foregroundColor(.white)
        }
    }
    
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).font(.caption).foregroundColor(.yellow).frame(width: 20)
            Text(label).font(.caption.bold()).foregroundColor(.gray).frame(width: 100, alignment: .leading)
            Text(value).font(.caption).foregroundColor(.white)
            Spacer()
        }
    }
    
    private func loadPhotoImage(filename: String) -> UIImage? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsPath.appendingPathComponent(filename)
        if let imageData = try? Data(contentsOf: imagePath) {
            return UIImage(data: imageData)
        }
        return nil
    }
}
