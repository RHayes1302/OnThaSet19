//
//  AddBikeProgressView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

// MARK: - Add Bike Progress View
/// Form for adding new bike modification with before/after photos
struct AddBikeProgressView: View {
    // MARK: - Environment Properties
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Properties
    // Bike information
    @State private var modificationTitle: String = ""
    @State private var note: String = ""
    @State private var bikeMake: String = ""
    @State private var bikeModel: String = ""
    @State private var bikeYear: String = ""
    
    // Images
    @State private var beforeImage: UIImage? = nil
    @State private var afterImage: UIImage? = nil
    
    // Photo picker items
    @State private var beforePickerItem: PhotosPickerItem? = nil
    @State private var afterPickerItem: PhotosPickerItem? = nil
    
    // Camera sheet states
    @State private var showBeforeCamera: Bool = false
    @State private var showAfterCamera: Bool = false
    
    // Error handling
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    // MARK: - Private Properties
    private let imageStore = ImageFileStore()
    
    /// Checks if device camera is available
    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: Page Title
                Text("Pimped My Bike")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.yellow)
                
                // MARK: Bike Details Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Bike Details")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    VStack(spacing: 12) {
                        TextField("Make (e.g., Harley-Davidson)", text: $bikeMake)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Model (e.g., Street Glide)", text: $bikeModel)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Year (e.g., 2020)", text: $bikeYear)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }
                }
                
                // MARK: Modification Title Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Modification Title")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    TextField("e.g., Custom Paint Job, New Exhaust", text: $modificationTitle)
                        .textFieldStyle(.roundedBorder)
                }
                
                // MARK: Before Photo Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Before Photo")
                        .font(.headline)
                        .foregroundStyle(.black)
                    
                    PhotoBoxView(image: beforeImage)
                    
                    HStack(spacing: 12) {
                        // Photo library picker
                        PhotosPicker(selection: $beforePickerItem, matching: .images) {
                            Label("Choose Photo", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        // Camera button
                        Button {
                            showBeforeCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!cameraAvailable)
                    }
                    
                    // Camera availability warning
                    if !cameraAvailable {
                        Text("Camera not available on simulator")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                .padding()
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.yellow, lineWidth: 3)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // MARK: After Photo Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("After Photo")
                        .font(.headline)
                        .foregroundStyle(.black)
                    
                    PhotoBoxView(image: afterImage)
                    
                    HStack(spacing: 12) {
                        // Photo library picker
                        PhotosPicker(selection: $afterPickerItem, matching: .images) {
                            Label("Choose Photo", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        // Camera button
                        Button {
                            showAfterCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!cameraAvailable)
                    }
                    
                    // Camera availability warning
                    if !cameraAvailable {
                        Text("Camera not available on simulator")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                .padding()
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.yellow, lineWidth: 3)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // MARK: Notes Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (Optional)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    TextField("Details about the modification...", text: $note, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                // MARK: Save Button
                Button {
                    saveProgress()
                } label: {
                    Text("Save Progress")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSave())
            }
            .padding()
        }
        .background(.black)
        .navigationTitle("Add Bike Mod")
        .navigationBarTitleDisplayMode(.inline)
        
        // MARK: - Photo Picker Change Handlers
        .onChange(of: beforePickerItem) { _, newItem in
            loadUIImage(from: newItem) { image in
                beforeImage = image
            }
        }
        
        .onChange(of: afterPickerItem) { _, newItem in
            loadUIImage(from: newItem) { image in
                afterImage = image
            }
        }
        
        // MARK: - Camera Sheets
        .sheet(isPresented: $showBeforeCamera) {
            CameraPicker { image in
                beforeImage = image
            }
        }
        
        .sheet(isPresented: $showAfterCamera) {
            CameraPicker { image in
                afterImage = image
            }
        }
        
        // MARK: - Error Alert
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Validation Function
    /// Checks if form is ready to be saved
    func canSave() -> Bool {
        return beforeImage != nil && afterImage != nil && !modificationTitle.isEmpty
    }
    
    // MARK: - Save Function
    /// Saves bike modification to database with images
    func saveProgress() {
        // Validate images exist
        guard let beforeImage, let afterImage else {
            errorMessage = "Please select both before and after photos"
            showError = true
            return
        }
        
        // Validate modification title
        guard !modificationTitle.isEmpty else {
            errorMessage = "Please enter a modification title"
            showError = true
            return
        }
        
        let id = UUID()
        let beforeName = imageStore.makeFileName(id: id, kind: .before)
        let afterName = imageStore.makeFileName(id: id, kind: .after)
        
        // Save images to file system
        do {
            try imageStore.saveIMG(beforeImage, fileName: beforeName)
            try imageStore.saveIMG(afterImage, fileName: afterName)
        } catch {
            errorMessage = "Could not save images"
            showError = true
            return
        }
        
        // Create BikeProgress entry
        let entry = BikeProgress(
            id: id,
            modificationTitle: modificationTitle,
            note: note,
            beforeImage: beforeName,
            afterImage: afterName,
            bikeMake: bikeMake,
            bikeModel: bikeModel,
            bikeYear: bikeYear
        )
        
        modelContext.insert(entry)
        
        // Save to database
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Clean up images if database save fails
            imageStore.deleteIMG(fileName: beforeName)
            imageStore.deleteIMG(fileName: afterName)
            errorMessage = "Could not save bike progress"
            showError = true
        }
    }
    
    // MARK: - Image Loading Function
    /// Loads UIImage from PhotosPickerItem
    func loadUIImage(from item: PhotosPickerItem?, completion: @escaping (UIImage?) -> Void) {
        guard let item else {
            completion(nil)
            return
        }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let image = UIImage(data: data)
                completion(image)
            } else {
                completion(nil)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AddBikeProgressView()
    }
    .modelContainer(for: BikeProgress.self, inMemory: true)
}
