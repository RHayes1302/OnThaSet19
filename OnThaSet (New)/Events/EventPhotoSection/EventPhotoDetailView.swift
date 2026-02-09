//
//  EventPhotoDetailView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import SwiftUI

// MARK: - Event Photo Detail View
struct EventPhotoDetailView: View {
    let photo: EventPhoto
    private let imageStore = ImageFileStore()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Event Photo
                if let img = imageStore.loadIMG(fileName: photo.photoFileName) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.yellow, lineWidth: 3)
                        )
                }
                
                // Event Info
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text(photo.eventName)
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.white)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                            Text(photo.eventDate, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                    }
                    
                    if !photo.location.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                Text(photo.location)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.white)
                        }
                    }
                    
                    if !photo.caption.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Caption")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                            Text(photo.caption)
                                .font(.body)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.yellow, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .background(Color.black)
        .navigationTitle("Event Photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let img = imageStore.loadIMG(fileName: photo.photoFileName) {
                    ShareLink(item: Image(uiImage: img), preview: SharePreview(photo.eventName, image: Image(uiImage: img))) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
    }
}

// MARK: - Bike Progress Detail View
struct BikeProgressDetailView: View {
    let entry: BikeProgress
    private let imageStore = ImageFileStore()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Bike Info Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.modificationTitle)
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.yellow)
                    
                    if !entry.bikeMake.isEmpty && !entry.bikeModel.isEmpty {
                        Text("\(entry.bikeMake) \(entry.bikeModel) \(entry.bikeYear)")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    
                    Text(entry.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.yellow, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Before Photo
                VStack(alignment: .leading, spacing: 12) {
                    Text("Before")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                    
                    if let img = imageStore.loadIMG(fileName: entry.beforeImage) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.yellow, lineWidth: 3)
                            )
                    }
                }
                
                // After Photo
                VStack(alignment: .leading, spacing: 12) {
                    Text("After")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                    
                    if let img = imageStore.loadIMG(fileName: entry.afterImage) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.yellow, lineWidth: 3)
                            )
                    }
                }
                
                // Notes
                if !entry.note.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundStyle(.yellow)
                        
                        Text(entry.note)
                            .font(.body)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.yellow, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .background(Color.black)
        .navigationTitle("Bike Mod Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Share before photo
                    if let beforeImg = imageStore.loadIMG(fileName: entry.beforeImage) {
                        ShareLink(item: Image(uiImage: beforeImg), preview: SharePreview("Before - \(entry.modificationTitle)", image: Image(uiImage: beforeImg))) {
                            Label("Share Before Photo", systemImage: "photo")
                        }
                    }
                    
                    // Share after photo
                    if let afterImg = imageStore.loadIMG(fileName: entry.afterImage) {
                        ShareLink(item: Image(uiImage: afterImg), preview: SharePreview("After - \(entry.modificationTitle)", image: Image(uiImage: afterImg))) {
                            Label("Share After Photo", systemImage: "photo.fill")
                        }
                    }
                    
                    // Share both photos (comparison)
                    Button {
                        shareComparison()
                    } label: {
                        Label("Share Before & After", systemImage: "rectangle.2.swap")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.yellow)
                }
            }
        }
    }
    
    private func shareComparison() {
        guard let beforeImg = imageStore.loadIMG(fileName: entry.beforeImage),
              let afterImg = imageStore.loadIMG(fileName: entry.afterImage) else {
            return
        }
        
        // Create a side-by-side comparison image
        let renderer = ImageRenderer(content: ComparisonView(beforeImage: beforeImg, afterImage: afterImg, title: entry.modificationTitle))
        renderer.scale = 3.0
        
        if let image = renderer.uiImage {
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
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
                .font(.title2)
                .bold()
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.yellow)
                .foregroundStyle(.black)
            
            HStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("BEFORE")
                        .font(.headline)
                        .foregroundStyle(.white)
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
                        .foregroundStyle(.white)
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
