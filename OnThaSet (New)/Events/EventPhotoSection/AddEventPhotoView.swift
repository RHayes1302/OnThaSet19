//
//  AddEventPhotoView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct AddEventPhotoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var eventName: String = ""
    @State private var eventDate: Date = Date()
    @State private var location: String = ""
    @State private var caption: String = ""
    @State private var selectedImage: UIImage? = nil
    
    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var showCamera: Bool = false
    
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    private let imageStore = ImageFileStore()
    
    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Add Event Photo")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.yellow)
                
                // PHOTO SECTION
                VStack(alignment: .leading, spacing: 12) {
                    Text("Event Photo")
                        .font(.headline)
                        .foregroundStyle(.black)
                    
                    PhotoBoxView(image: selectedImage)
                    
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label("Choose Photo", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            showCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!cameraAvailable)
                    }
                    
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
                
                // EVENT INFO SECTION
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event Name")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        TextField("e.g., Bike Week Rally", text: $eventName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event Date")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        DatePicker("", selection: $eventDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        TextField("e.g., Daytona Beach, FL", text: $location)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption (Optional)")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        TextField("Add a caption...", text: $caption, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                    }
                }
                
                // SAVE BUTTON
                Button {
                    savePhoto()
                } label: {
                    Text("Save Photo")
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
        .navigationTitle("Add Event Photo")
        .navigationBarTitleDisplayMode(.inline)
        
        // MARK: - onChange handlers
        .onChange(of: pickerItem) { _, newItem in
            loadUIImage(from: newItem) { image in
                selectedImage = image
            }
        }
        
        // MARK: - Camera sheet
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                selectedImage = image
            }
        }
        
        // MARK: - Error alert
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    func canSave() -> Bool {
        return selectedImage != nil && !eventName.isEmpty
    }
    
    func savePhoto() {
        guard let selectedImage else {
            errorMessage = "Please select a photo"
            showError = true
            return
        }
        
        guard !eventName.isEmpty else {
            errorMessage = "Please enter an event name"
            showError = true
            return
        }
        
        let id = UUID()
        let fileName = imageStore.makeFileName(id: id, kind: .before) // Reusing the naming convention
        
        do {
            try imageStore.saveIMG(selectedImage, fileName: fileName)
        } catch {
            errorMessage = "Could not save image"
            showError = true
            return
        }
        
        let photo = EventPhoto(
            id: id,
            eventName: eventName,
            eventDate: eventDate,
            location: location,
            caption: caption,
            photoFileName: fileName
        )
        
        modelContext.insert(photo)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            imageStore.deleteIMG(fileName: fileName)
            errorMessage = "Could not save event photo"
            showError = true
        }
    }
    
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

#Preview {
    NavigationStack {
        AddEventPhotoView()
    }
    .modelContainer(for: EventPhoto.self, inMemory: true)
}
