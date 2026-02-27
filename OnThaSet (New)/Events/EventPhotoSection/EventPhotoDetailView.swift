//
//  EventPhotoDetailView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//  Updated: 2/16/26 - IMAGE LOADING DIAGNOSTIC
//

import SwiftUI

// MARK: - Event Photo Detail View
struct EventPhotoDetailView: View {
    let photo: EventPhoto
    private let imageStore = ImageFileStore()
    @State private var showingExpandedImage = false
    @State private var selectedImage: UIImage?
    @State private var loadedImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // DIAGNOSTIC HEADER
                VStack(alignment: .leading, spacing: 8) {
                    Text("🐛 IMAGE LOADING DIAGNOSTIC")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text("Photo filename: \(photo.photoFileName)")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text("Image loaded: \(loadedImage != nil ? "✅ YES" : "❌ NO")")
                        .font(.caption)
                        .foregroundColor(loadedImage != nil ? .green : .red)
                    Text("imageStore exists: ✅ YES")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.red.opacity(0.2))
                .cornerRadius(8)
                
                // Event Photo
                VStack(spacing: 10) {
                    if let img = loadedImage {
                        Button(action: {
                            print("🟢 Event photo button tapped!")
                            selectedImage = img
                            showingExpandedImage = true
                        }) {
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
                        .buttonStyle(.plain)
                    } else {
                        // Show placeholder when image doesn't load
                        VStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.3))
                                .frame(height: 300)
                                .overlay(
                                    VStack(spacing: 10) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.red)
                                        Text("IMAGE NOT LOADING")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("File: \(photo.photoFileName)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                    }
                    
                    // ALWAYS SHOW TEST BUTTON (regardless of image loading)
                    Button(action: {
                        print("🔴 TEST BUTTON TAPPED!")
                        print("🔴 loadedImage is nil: \(loadedImage == nil)")
                        
                        // Try to load image again
                        if let img = imageStore.loadIMG(fileName: photo.photoFileName) {
                            print("🟢 Image loaded successfully in test button!")
                            selectedImage = img
                            showingExpandedImage = true
                        } else {
                            print("❌ Image FAILED to load in test button!")
                            print("❌ Trying alternate load method...")
                            
                            // Try loading from documents directory
                            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                            let filePath = documentsPath.appendingPathComponent(photo.photoFileName)
                            print("📂 File path: \(filePath.path)")
                            print("📂 File exists: \(FileManager.default.fileExists(atPath: filePath.path))")
                            
                            if let data = try? Data(contentsOf: filePath),
                               let img = UIImage(data: data) {
                                print("🟢 Loaded via alternate method!")
                                selectedImage = img
                                showingExpandedImage = true
                            } else {
                                print("❌ Alternate method also failed!")
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                            Text("TEST EXPAND (TAP ME)")
                                .font(.headline.bold())
                        }
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow)
                        .cornerRadius(8)
                    }
                    
                    // Manual state setter for testing
                    Button(action: {
                        print("🟣 MANUAL STATE TEST")
                        showingExpandedImage = true
                    }) {
                        Text("FORCE SHOW MODAL (ignore image)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .cornerRadius(8)
                    }
                }
                
                // DIAGNOSTIC STATE INFO
                VStack(alignment: .leading, spacing: 8) {
                    Text("🐛 STATE INFO")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                    Text("showingExpandedImage: \(showingExpandedImage ? "TRUE ✅" : "FALSE ❌")")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text("selectedImage: \(selectedImage != nil ? "SET ✅" : "NIL ❌")")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
                
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
        .sheet(isPresented: $showingExpandedImage) {
            if let image = selectedImage {
                NavigationStack {
                    FullScreenImageView(image: image)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    showingExpandedImage = false
                                }
                            }
                        }
                }
            } else {
                VStack(spacing: 20) {
                    Text("🔴 ERROR")
                        .font(.largeTitle.bold())
                        .foregroundColor(.red)
                    Text("No image was selected")
                        .font(.title3)
                    Text("This means the image loading failed")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button("Close") {
                        showingExpandedImage = false
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .onChange(of: showingExpandedImage) { oldValue, newValue in
            print("🔵 showingExpandedImage changed: \(oldValue) → \(newValue)")
        }
        .onAppear {
            print("📱 EventPhotoDetailView appeared")
            print("📱 Photo filename: \(photo.photoFileName)")
            
            // Try to load image
            if let img = imageStore.loadIMG(fileName: photo.photoFileName) {
                print("✅ Image loaded successfully on appear!")
                loadedImage = img
            } else {
                print("❌ Image FAILED to load on appear!")
                print("❌ Checking documents directory...")
                
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let filePath = documentsPath.appendingPathComponent(photo.photoFileName)
                print("📂 File path: \(filePath.path)")
                print("📂 File exists: \(FileManager.default.fileExists(atPath: filePath.path))")
                
                // List all files in documents directory
                if let files = try? FileManager.default.contentsOfDirectory(atPath: documentsPath.path) {
                    print("📂 Files in documents directory:")
                    for file in files {
                        print("   - \(file)")
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
    @State private var showingExpandedImage = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Use EventPhotoDetailView diagnostic first")
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .background(Color.black)
    }
    
    private func shareComparison() {}
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
