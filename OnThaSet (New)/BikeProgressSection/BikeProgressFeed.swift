//
//  BikeProgressFeed.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//  Updated: 2/16/26 - With FullScreenImageView, delete, and all photos
//

import SwiftUI
import SwiftData

// MARK: - Bike Progress Feed View
/// Main list view displaying all bike modifications with before/after photos
struct BikeProgressFeedView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BikeProgress.createdAt, order: .reverse)
    private var entries: [BikeProgress]
    @Query private var profiles: [UserProfile]  // ✅ ADDED: Get current user profile
    
    private let imageStore = ImageFileStore()
    
    @State private var showingFullImage = false
    @State private var selectedImage: UIImage?
    @State private var selectedEntry: BikeProgress?
    @State private var showingDeleteAlert = false
    
    private var currentProfile: UserProfile? {
        profiles.first
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Group {
                // MARK: Empty State
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Bike Mods Yet",
                        systemImage: "wrench.and.screwdriver.fill",
                        description: Text("Show off your bike customizations!")
                    )
                    .background(Color.black)
                } else {
                    // MARK: List of Bike Modifications
                    List {
                        ForEach(entries) { entry in
                            BikeProgressRow(entry: entry, imageStore: imageStore) {
                                // When thumbnail tapped, show full screen
                                if let img = imageStore.loadIMG(fileName: entry.beforeImage) {
                                    selectedImage = img
                                    selectedEntry = entry
                                    showingFullImage = true
                                }
                            }
                            .listRowBackground(Color.black)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                }
            }
            // MARK: Navigation Styling
            .navigationTitle("Pimped My Bike")
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                // MARK: Add Button
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AddBikeProgressView()
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
                .alert("Delete Bike Modification?", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        if let entryToDelete = selectedEntry {
                            // Delete both images
                            imageStore.deleteIMG(fileName: entryToDelete.beforeImage)
                            imageStore.deleteIMG(fileName: entryToDelete.afterImage)
                            // Delete the entry
                            modelContext.delete(entryToDelete)
                            try? modelContext.save()
                            
                            // Close the full screen view
                            showingFullImage = false
                            selectedEntry = nil
                            selectedImage = nil
                        }
                    }
                } message: {
                    Text("This will delete both the before and after photos. This cannot be undone.")
                }
            }
        }
    }
    
    // MARK: - Delete Function
    /// Deletes bike modification entry and associated images from storage (swipe to delete)
    func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            let entry = entries[index]
            // Delete both before and after images
            imageStore.deleteIMG(fileName: entry.beforeImage)
            imageStore.deleteIMG(fileName: entry.afterImage)
            // Delete the entry from database
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
}

// MARK: - Bike Progress Row
/// Individual row component for displaying bike modification in list
struct BikeProgressRow: View {
    // MARK: - Properties
    let entry: BikeProgress
    let imageStore: ImageFileStore
    let onImageTap: () -> Void
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            // MARK: Thumbnail Image - TAPPABLE TO EXPAND (matching event style)
            if let img = imageStore.loadIMG(fileName: entry.beforeImage) {
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
            }
            
            // MARK: Entry Information
            VStack(alignment: .leading, spacing: 4) {
                // Modification title
                Text(entry.modificationTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                // Bike make and model
                if !entry.bikeMake.isEmpty && !entry.bikeModel.isEmpty {
                    Text("\(entry.bikeMake) \(entry.bikeModel)")
                        .font(.subheadline)
                        .foregroundStyle(.yellow)
                }
                
                // Creation date
                Text(entry.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    BikeProgressFeedView()
        .modelContainer(for: BikeProgress.self, inMemory: true)
}
