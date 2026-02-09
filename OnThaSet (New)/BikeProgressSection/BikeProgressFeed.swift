//
//  BikeProgressFeed.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
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
    
    private let imageStore = ImageFileStore()
    
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
                            NavigationLink {
                                BikeProgressDetailView(entry: entry)
                            } label: {
                                BikeProgressRow(entry: entry, imageStore: imageStore)
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
    }
    
    // MARK: - Delete Function
    /// Deletes bike modification entry and associated images from storage
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
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            // MARK: Thumbnail Image
            if let img = imageStore.loadIMG(fileName: entry.beforeImage) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
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
