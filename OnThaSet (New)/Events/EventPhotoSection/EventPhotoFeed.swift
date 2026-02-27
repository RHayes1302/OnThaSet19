//
//  EventPhotoFeed.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//  Updated: 2/16/26 - With FullScreenImageView, delete, and all photos
//

import SwiftUI
import SwiftData

// MARK: - Event Photos Feed View
/// Main list view displaying all event photos from ON Tha Set
struct EventPhotosFeedView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EventPhoto.eventDate, order: .reverse)
    private var photos: [EventPhoto]
    @Query private var profiles: [UserProfile]  // ✅ ADDED: Get current user profile
    
    private let imageStore = ImageFileStore()
    
    @State private var showingFullImage = false
    @State private var selectedImage: UIImage?
    @State private var selectedPhoto: EventPhoto?
    @State private var showingDeleteAlert = false
    
    private var currentProfile: UserProfile? {
        profiles.first
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Group {
                // MARK: Empty State
                if photos.isEmpty {
                    ContentUnavailableView(
                        "No Event Photos Yet",
                        systemImage: "camera.on.rectangle",
                        description: Text("Capture memories from your events!")
                    )
                    .background(Color.black)
                } else {
                    // MARK: List of Event Photos
                    List {
                        ForEach(photos) { photo in
                            EventPhotoRow(photo: photo, imageStore: imageStore) {
                                // When thumbnail tapped, show full screen
                                if let img = imageStore.loadIMG(fileName: photo.photoFileName) {
                                    selectedImage = img
                                    selectedPhoto = photo
                                    showingFullImage = true
                                }
                            }
                            .listRowBackground(Color.black)
                        }
                        .onDelete(perform: deletePhotos)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                }
            }
            // MARK: Navigation Styling
            .navigationTitle("ON Tha Set")
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                // MARK: Add Button
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AddEventPhotoView()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            if let image = selectedImage {
                FullScreenImageView(
                    image: image,
                    onDelete: currentProfile?.hasActiveSubscription == true ? {
                        showingDeleteAlert = true
                    } : nil  // No delete button for non-subscribers
                )
                .alert("Delete Photo?", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        if let photoToDelete = selectedPhoto {
                            // Delete the photo
                            imageStore.deleteIMG(fileName: photoToDelete.photoFileName)
                            modelContext.delete(photoToDelete)
                            try? modelContext.save()
                            
                            // Close the full screen view
                            showingFullImage = false
                            selectedPhoto = nil
                            selectedImage = nil
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete this photo? This cannot be undone.")
                }
            }
        }
    }
    
    // MARK: - Delete Function
    /// Deletes event photo and associated image from storage (swipe to delete)
    func deletePhotos(_ indexSet: IndexSet) {
        for index in indexSet {
            let photo = photos[index]
            // Delete image from file system
            imageStore.deleteIMG(fileName: photo.photoFileName)
            // Delete entry from database
            modelContext.delete(photo)
        }
        try? modelContext.save()
    }
}

// MARK: - Event Photo Row
/// Individual row component for displaying event photo in list
struct EventPhotoRow: View {
    // MARK: - Properties
    let photo: EventPhoto
    let imageStore: ImageFileStore
    let onImageTap: () -> Void
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            // MARK: Thumbnail Image - TAPPABLE TO EXPAND (matching event style)
            if let img = imageStore.loadIMG(fileName: photo.photoFileName) {
                Button(action: onImageTap) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .yellow.opacity(0.3), radius: 5)
                        .overlay(
                            // Tap indicator (like events)
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(4)
                                        .padding(4)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray)
                    }
            }
            
            // MARK: Event Information
            VStack(alignment: .leading, spacing: 4) {
                // Event name
                Text(photo.eventName)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                // Event date
                Text(photo.eventDate, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
                
                // Event location
                if !photo.location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text(photo.location)
                            .font(.caption)
                    }
                    .foregroundStyle(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    EventPhotosFeedView()
        .modelContainer(for: EventPhoto.self, inMemory: true)
}
