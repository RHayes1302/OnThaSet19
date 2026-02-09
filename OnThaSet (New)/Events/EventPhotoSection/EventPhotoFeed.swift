//
//  EventPhotoFeed.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
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
    
    private let imageStore = ImageFileStore()
    
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
                            NavigationLink {
                                EventPhotoDetailView(photo: photo)
                            } label: {
                                EventPhotoRow(photo: photo, imageStore: imageStore)
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
    }
    
    // MARK: - Delete Function
    /// Deletes event photo and associated image from storage
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
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            // MARK: Thumbnail Image
            if let img = imageStore.loadIMG(fileName: photo.photoFileName) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
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
