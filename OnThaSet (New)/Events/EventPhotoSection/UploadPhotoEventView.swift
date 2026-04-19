//
//  UploadPhotoEventView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/8/26.
//

import SwiftUI
import PhotosUI
import SwiftData

struct UploadEventPhotoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    
    @State private var eventName = ""
    @State private var eventDate = Date()
    @State private var location = ""
    @State private var caption = ""
    
    // Multiple photos
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    
    @State private var showingSuccessAlert = false
    @State private var isSaving = false
    @State private var uploadError = ""
    @State private var showingError = false
    
    private var currentProfile: UserProfile? {
        profiles.first
    }
    
    private var canSave: Bool {
        guard currentProfile != nil else { return false }
        return !eventName.isEmpty &&
               !location.isEmpty &&
               !selectedImages.isEmpty
    }

    private var photoLimitBanner: some View {
        Group {
            if let profile = currentProfile, profile.hasActiveSubscription {
                let monthly = profile.remainingPhotosThisMonth()
                let total = profile.remainingPhotoSlots()
                let atLimit = monthly == 0 || total == 0

                HStack(spacing: 8) {
                    Image(systemName: atLimit ? "exclamationmark.circle.fill" : "photo.stack")
                        .foregroundColor(atLimit ? .red : .yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(atLimit ? "Photo limit reached" : "Photo storage")
                            .font(.caption.bold())
                            .foregroundColor(atLimit ? .red : .white)
                        Text("\(monthly) uploads left this month  •  \(total)/\(UserProfile.totalPhotoLimit) slots used")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(10)
                .background(atLimit ? Color.red.opacity(0.1) : Color.white.opacity(0.05))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(atLimit ? Color.red.opacity(0.3) : Color.yellow.opacity(0.2), lineWidth: 1))
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    photoLimitBanner
                    headerSection
                    eventInfoSection
                    photosSection
                    captionSection
                    saveButton
                }
                .padding()
            }
        }
        .navigationTitle("Event Photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(.yellow)
            }
        }
        .overlay {
            if isSaving {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: 15) {
                        ProgressView().tint(.yellow).scaleEffect(1.5)
                        Text("Uploading photos...").foregroundColor(.white)
                    }
                }
            }
        }
        .onChange(of: selectedPhotos) { _, newValue in
            loadPhotos(from: newValue)
        }
        .alert("Upload Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(uploadError)
        }
        .alert("Success!", isPresented: $showingSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your event photos have been posted!")
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Share Event Photos")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Upload photos from events you attended")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 10)
    }
    
    private var eventInfoSection: some View {
        VStack(spacing: 15) {
            // Event Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Event Name")
                    .font(.caption.bold())
                    .foregroundColor(.yellow)
                
                TextField("e.g., Annual Bike Rally 2026", text: $eventName)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            // Event Date
            VStack(alignment: .leading, spacing: 8) {
                Text("Event Date")
                    .font(.caption.bold())
                    .foregroundColor(.yellow)
                
                DatePicker("", selection: $eventDate, displayedComponents: .date)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Location
            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(.caption.bold())
                    .foregroundColor(.yellow)
                
                TextField("City, State", text: $location)
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PHOTOS")
                    .font(.caption.bold())
                    .foregroundColor(.yellow)
                
                Text("(Required)")
                    .font(.caption2)
                    .foregroundColor(.orange)
                
                Spacer()
                
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: min(10, currentProfile?.remainingPhotoSlots() ?? 10),
                    matching: .images
                ) {
                    Label("Add Photos", systemImage: "plus.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                }
            }
            
            if selectedImages.isEmpty {
                emptyPhotosView
            } else {
                photosGrid
            }
        }
    }
    
    private var emptyPhotosView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No photos selected")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("Tap 'Add Photos' to select up to 10 photos")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var photosGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                photoThumbnail(image: image, index: index)
            }
        }
    }
    
    private func photoThumbnail(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Photo number badge
            Text("\(index + 1)")
                .font(.caption2.bold())
                .foregroundColor(.black)
                .padding(6)
                .background(Color.yellow)
                .clipShape(Circle())
                .offset(x: -5, y: 5)
            
            // Remove button
            Button(action: {
                selectedImages.remove(at: index)
                selectedPhotos.remove(at: index)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white.clipShape(Circle()))
            }
            .offset(x: 5, y: -5)
        }
    }
    
    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Caption (Optional)")
                .font(.caption.bold())
                .foregroundColor(.yellow)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 100)

                if caption.isEmpty {
                    Text("Add a caption for your photos...")
                        .foregroundColor(.gray.opacity(0.5))
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $caption)
                    .frame(height: 100)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundColor(.white)
                    .colorScheme(.dark)
            }
            .cornerRadius(8)
        }
    }
    
    private var saveButton: some View {
        Button(action: savePhotos) {
            Text("POST \(selectedImages.count) PHOTO\(selectedImages.count == 1 ? "" : "S")")
                .font(.headline.bold())
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSave ? Color.yellow : Color.gray)
                .cornerRadius(10)
        }
        .disabled(!canSave)
    }
    
    // MARK: - Functions
    
    private func loadPhotos(from items: [PhotosPickerItem]) {
        Task {
            var images: [UIImage] = []
            
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            
            await MainActor.run {
                selectedImages = images
            }
        }
    }
    
    private func savePhotos() {
        Task { await performSave() }
    }

    private func performSave() async {
        guard let profile = currentProfile else { return }
        await MainActor.run { isSaving = true }

        var savedCount = 0
        for (index, image) in selectedImages.enumerated() {
            guard let data = image.jpegData(compressionQuality: 0.8) else { continue }
            let filename = "event_photo_\(profile.appleUserID)_\(UUID().uuidString).jpg"

            do {
                let photoURL = try await SupabaseManager.shared.uploadImage(
                    data: data, bucket: "event-photos", fileName: filename
                )

                // Save metadata to Supabase so other users can see it
                await SupabaseManager.shared.saveEventPhotoMetadata(
                    userID: profile.appleUserID,
                    eventName: eventName,
                    eventDate: eventDate,
                    location: location,
                    caption: caption.isEmpty ? "Photo \(index + 1)" : caption,
                    photoURL: photoURL
                )

                let eventPhoto = EventPhoto(
                    eventName: eventName,
                    eventDate: eventDate,
                    location: location,
                    caption: caption.isEmpty ? "Photo \(index + 1)" : caption,
                    photoFileName: photoURL,
                    userID: profile.appleUserID
                )
                await MainActor.run { modelContext.insert(eventPhoto) }
                savedCount += 1
                print("✅ Event photo uploaded: \(photoURL)")
            } catch {
                print("❌ Event photo upload failed: \(error)")
            }
        }

        await MainActor.run {
            if savedCount > 0 {
                profile.totalPhotosPosted += savedCount
                // Increment photo limits if the new fields are available
                for _ in 0..<savedCount { profile.incrementPhotoCount() }
                try? modelContext.save()
                isSaving = false
                showingSuccessAlert = true
            } else {
                isSaving = false
                uploadError = "Failed to upload photos. Please try again."
                showingError = true
            }
        }
    }
}
