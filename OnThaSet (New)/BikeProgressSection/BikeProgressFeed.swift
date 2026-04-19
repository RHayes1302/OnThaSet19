//
//  BikeProgressFeed.swift
//  OnThaSet (New)
//
//  Updated to show proper before/after photo layout
//

import SwiftUI
import SwiftData

// MARK: - Bike Progress Feed View

struct BikeProgressFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BikeProgress.createdAt, order: .reverse)
    private var entries: [BikeProgress]
    @Query private var profiles: [UserProfile]

    private let imageStore = ImageFileStore()

    @State private var showingFullImage = false
    @State private var selectedImage: UIImage?
    @State private var selectedEntry: BikeProgress?
    @State private var showingDeleteAlert = false

    private var currentProfile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Bike Builds Yet",
                        systemImage: "wrench.and.screwdriver.fill",
                        description: Text("Show off your bike modifications!")
                    )
                    .background(Color.black)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(entries) { entry in
                                BikeProgressCard(
                                    entry: entry,
                                    imageStore: imageStore,
                                    onImageTap: { image in
                                        selectedImage = image
                                        selectedEntry = entry
                                        showingFullImage = true
                                    },
                                    onDelete: {
                                        selectedEntry = entry
                                        showingDeleteAlert = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .background(Color.black)
                }
            }
            .navigationTitle("My Bike Builds")
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AddBikeProgressView()
                    } label: {
                        Image(systemName: "plus").foregroundStyle(.yellow)
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
                    } : nil
                )
                .alert("Delete Bike Build?", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        if let entry = selectedEntry {
                            let before = entry.beforeImage
                            let after = entry.afterImage
                            Task {
                                await SupabaseManager.shared.deleteStorageFile(imageURL: before, bucket: "bike-progress")
                                await SupabaseManager.shared.deleteStorageFile(imageURL: after, bucket: "bike-progress")
                                await SupabaseManager.shared.deleteBikeBuildRecord(afterImageURL: after, userID: entry.userID)
                            }
                            modelContext.delete(entry)
                            try? modelContext.save()
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
        .alert("Delete Bike Build?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let entry = selectedEntry {
                    let before = entry.beforeImage
                    let after = entry.afterImage
                    Task {
                        await SupabaseManager.shared.deleteStorageFile(imageURL: before, bucket: "bike-progress")
                        await SupabaseManager.shared.deleteStorageFile(imageURL: after, bucket: "bike-progress")
                        await SupabaseManager.shared.deleteBikeBuildRecord(afterImageURL: after, userID: entry.userID)
                    }
                    modelContext.delete(entry)
                    try? modelContext.save()
                    selectedEntry = nil
                }
            }
        } message: {
            Text("This will delete this bike build. This cannot be undone.")
        }
    }
}

// MARK: - Bike Progress Card (Before/After Layout)

struct BikeProgressCard: View {
    let entry: BikeProgress
    let imageStore: ImageFileStore
    let onImageTap: (UIImage) -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header with delete button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.modificationTitle)
                        .font(.headline.bold())
                        .foregroundColor(.white)

                    if !entry.bikeMake.isEmpty || !entry.bikeModel.isEmpty || !entry.bikeYear.isEmpty {
                        Text("\(entry.bikeYear) \(entry.bikeMake) \(entry.bikeModel)"
                            .trimmingCharacters(in: .whitespaces))
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                    }

                    Text(entry.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.7))
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }

            // Before / After photos
            let hasPhotos = !entry.beforeImage.isEmpty || !entry.afterImage.isEmpty
            if hasPhotos {
                HStack(spacing: 10) {
                    if !entry.beforeImage.isEmpty {
                        urlPhotoPanel(urlString: entry.beforeImage, label: "BEFORE", labelColor: .gray)
                    }
                    if !entry.afterImage.isEmpty {
                        urlPhotoPanel(urlString: entry.afterImage, label: "AFTER", labelColor: .yellow)
                    } else if !entry.beforeImage.isEmpty {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.05))
                            VStack(spacing: 6) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title2).foregroundColor(.yellow.opacity(0.5))
                                Text("AFTER\nCOMING SOON")
                                    .font(.caption2.bold())
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                    }
                }
            }

            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
        )
    }

    private func urlPhotoPanel(urlString: String, label: String, labelColor: Color) -> some View {
        Group {
            if urlString.hasPrefix("http"), let url = URL(string: urlString) {
                // Supabase URL — use AsyncImage
                Button(action: {
                    // Load image for full screen
                    Task {
                        if let (data, _) = try? await URLSession.shared.data(from: url),
                           let img = UIImage(data: data) {
                            await MainActor.run { onImageTap(img) }
                        }
                    }
                }) {
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                                    .frame(maxWidth: .infinity).frame(height: 160)
                                    .clipped().cornerRadius(10)
                            case .failure:
                                brokenImagePlaceholder
                            default:
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.05))
                                        .frame(maxWidth: .infinity).frame(height: 160)
                                    ProgressView().tint(.yellow)
                                }
                            }
                        }
                        Text(label)
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(labelColor).cornerRadius(6)
                            .padding(8)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            } else if !urlString.isEmpty {
                // Legacy local filename — use ImageFileStore
                let localImage = imageStore.loadIMG(fileName: urlString)
                Button(action: {
                    if let img = localImage { onImageTap(img) }
                }) {
                    ZStack(alignment: .bottomLeading) {
                        if let img = localImage {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(maxWidth: .infinity).frame(height: 160)
                                .clipped().cornerRadius(10)
                        } else {
                            brokenImagePlaceholder
                        }
                        Text(label)
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(labelColor).cornerRadius(6)
                            .padding(8)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var brokenImagePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .frame(maxWidth: .infinity).frame(height: 160)
            VStack(spacing: 6) {
                Image(systemName: "photo").font(.title2).foregroundColor(.gray)
                Text("Photo unavailable").font(.caption2).foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Legacy Row (kept for backwards compatibility)

struct BikeProgressRow: View {
    let entry: BikeProgress
    let imageStore: ImageFileStore
    let onImageTap: () -> Void

    var body: some View {
        BikeProgressCard(
            entry: entry,
            imageStore: imageStore,
            onImageTap: { _ in onImageTap() }
        )
    }
}
