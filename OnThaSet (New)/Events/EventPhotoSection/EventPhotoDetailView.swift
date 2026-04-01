//
//  EventPhotoDetailView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import SwiftUI

struct EventPhotoDetailView: View {
    let photo: EventPhoto
    private let imageStore = ImageFileStore()

    @State private var showingExpandedImage = false
    @State private var loadedImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // PHOTO
                if let img = loadedImage {
                    Button(action: { showingExpandedImage = true }) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.yellow, lineWidth: 3)
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 300)
                        .overlay(
                            VStack(spacing: 10) {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("Photo not available")
                                    .foregroundColor(.gray)
                            }
                        )
                }

                // EVENT INFO
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(photo.eventName)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }

                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.yellow)
                        Text(photo.eventDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }

                    if !photo.location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(photo.location)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }

                    if !photo.caption.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Caption")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(photo.caption)
                                .font(.body)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Event Photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let img = loadedImage {
                    ShareLink(
                        item: Image(uiImage: img),
                        preview: SharePreview(photo.eventName, image: Image(uiImage: img))
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingExpandedImage) {
            if let img = loadedImage {
                FullScreenImageView(image: img)
            }
        }
        .onAppear {
            loadedImage = imageStore.loadIMG(fileName: photo.photoFileName)
        }
    }
}

// MARK: - Bike Progress Detail View
struct BikeProgressDetailView: View {
    let entry: BikeProgress
    private let imageStore = ImageFileStore()
    @State private var showingExpandedImage = false
    @State private var afterImage: UIImage?
    @State private var beforeImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // AFTER IMAGE
                if let img = afterImage {
                    Button(action: { showingExpandedImage = true }) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.yellow, lineWidth: 3)
                            )
                    }
                    .buttonStyle(.plain)
                }

                // BEFORE / AFTER COMPARISON
                if let before = beforeImage, let after = afterImage {
                    HStack(spacing: 8) {
                        VStack(spacing: 4) {
                            Text("BEFORE")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                            Image(uiImage: before)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                                .cornerRadius(10)
                        }
                        VStack(spacing: 4) {
                            Text("AFTER")
                                .font(.caption.bold())
                                .foregroundColor(.yellow)
                            Image(uiImage: after)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                                .cornerRadius(10)
                        }
                    }
                }

                // BIKE INFO
                VStack(alignment: .leading, spacing: 12) {
                    Text(entry.modificationTitle)
                        .font(.title2.bold())
                        .foregroundColor(.yellow)

                    if !entry.bikeMake.isEmpty {
                        HStack {
                            Image(systemName: "bicycle")
                                .foregroundColor(.yellow)
                            Text("\(entry.bikeYear) \(entry.bikeMake) \(entry.bikeModel)")
                                .foregroundColor(.white)
                        }
                    }

                    if !entry.note.isEmpty {
                        Text(entry.note)
                            .foregroundColor(.gray)
                    }

                    Text(entry.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Bike Mod")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(isPresented: $showingExpandedImage) {
            if let img = afterImage {
                FullScreenImageView(image: img)
            }
        }
        .onAppear {
            afterImage = imageStore.loadIMG(fileName: entry.afterImage)
            if !entry.beforeImage.isEmpty {
                beforeImage = imageStore.loadIMG(fileName: entry.beforeImage)
            }
        }
    }
}

// MARK: - Comparison View for Sharing
struct ComparisonView: View {
    let beforeImage: UIImage
    let afterImage: UIImage
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.title2.bold())
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.yellow)
                .foregroundColor(.black)

            HStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("BEFORE")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                    Image(uiImage: beforeImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 350, height: 350)
                        .clipped()
                }
                VStack(spacing: 8) {
                    Text("AFTER")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow)
                    Image(uiImage: afterImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 350, height: 350)
                        .clipped()
                }
            }
        }
        .frame(width: 700, height: 450)
        .background(Color.white)
    }
}
