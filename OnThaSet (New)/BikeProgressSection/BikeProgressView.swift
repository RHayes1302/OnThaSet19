//
//  BikeProgressView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/8/26.
//

import SwiftUI
import PhotosUI
import SwiftData

struct UploadBikeProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    
    @State private var modificationTitle = ""
    @State private var note = ""
    @State private var bikeMake = ""
    @State private var bikeModel = ""
    @State private var bikeYear = ""
    
    // Bike options
    private let years = Array(1950...2026).reversed().map { String($0) }
    private let makes = [
        "Harley-Davidson", "Indian", "Honda", "Yamaha", "Kawasaki",
        "Suzuki", "BMW", "Ducati", "Triumph", "KTM", "Aprilia",
        "Moto Guzzi", "Royal Enfield", "Can-Am", "Victory", "Other"
    ].sorted()
    
    // Models by make
    private var models: [String] {
        switch bikeMake {
        case "Harley-Davidson":
            return ["Street Glide", "Road Glide", "Softail", "Sportster", "Fat Boy",
                    "Road King", "Ultra Limited", "Breakout", "Low Rider", "Heritage Classic", "Other"]
        case "Indian":
            return ["Chief", "Scout", "Challenger", "Chieftain", "Roadmaster",
                    "Springfield", "FTR", "Pursuit", "Other"]
        case "Honda":
            return ["Gold Wing", "Rebel", "Shadow", "CBR", "CB", "CRF",
                    "Africa Twin", "NC750X", "Other"]
        case "Yamaha":
            return ["YZF-R1", "YZF-R6", "MT-09", "MT-07", "V-Star", "Bolt",
                    "FJR1300", "Tracer", "Other"]
        case "Kawasaki":
            return ["Ninja", "Z900", "Vulcan", "Versys", "KLR", "ZX-10R",
                    "Z650", "Concours", "Other"]
        case "Suzuki":
            return ["Hayabusa", "GSX-R", "V-Strom", "Boulevard", "SV650",
                    "Katana", "GSX-S", "Other"]
        case "BMW":
            return ["R1250GS", "R1250RT", "S1000RR", "F850GS", "K1600",
                    "R18", "F900R", "Other"]
        case "Ducati":
            return ["Panigale", "Monster", "Multistrada", "Diavel", "Scrambler",
                    "Supersport", "Streetfighter", "Other"]
        case "Triumph":
            return ["Bonneville", "Speed Triple", "Tiger", "Street Triple", "Rocket",
                    "Scrambler", "Thruxton", "Other"]
        default:
            return ["Other"]
        }
    }
    
    // Multiple before/after photos
    @State private var beforePhotos: [PhotosPickerItem] = []
    @State private var afterPhotos: [PhotosPickerItem] = []
    @State private var beforeImages: [UIImage] = []
    @State private var afterImages: [UIImage] = []
    
    @State private var showingSuccessAlert = false
    
    private var currentProfile: UserProfile? {
        profiles.first
    }
    
    private var canSave: Bool {
        !modificationTitle.isEmpty &&
        !afterImages.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    titleSection
                    bikeInfoSection
                    beforePhotosSection
                    afterPhotosSection
                    notesSection
                    saveButton
                }
                .padding()
            }
        }
        .navigationTitle("Bike Update")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(.yellow)
            }
        }
        .onChange(of: beforePhotos) { _, newValue in
            loadPhotos(from: newValue, into: $beforeImages)
        }
        .onChange(of: afterPhotos) { _, newValue in
            loadPhotos(from: newValue, into: $afterImages)
        }
        .alert("Success!", isPresented: $showingSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your bike update has been posted!")
        }
    }
    
    // MARK: - View Components
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Modification Title")
                .font(.caption.bold())
                .foregroundColor(.yellow)
            
            TextField("e.g., New Exhaust System", text: $modificationTitle)
                .textFieldStyle(CustomTextFieldStyle())
        }
    }
    
    private var bikeInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("BIKE INFO")
                .font(.caption.bold())
                .foregroundColor(.yellow)
            
            // Year Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Year")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Picker("Year", selection: $bikeYear) {
                    Text("Select Year").tag("")
                    ForEach(years, id: \.self) { year in
                        Text(year).tag(year)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .tint(.yellow)
            }
            
            // Make Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Make")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Picker("Make", selection: $bikeMake) {
                    Text("Select Make").tag("")
                    ForEach(makes, id: \.self) { make in
                        Text(make).tag(make)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .tint(.yellow)
                .onChange(of: bikeMake) { _, _ in
                    // Reset model when make changes
                    bikeModel = ""
                }
            }
            
            // Model Picker
            if !bikeMake.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Picker("Model", selection: $bikeModel) {
                        Text("Select Model").tag("")
                        ForEach(models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .tint(.yellow)
                }
            }
        }
    }
    
    private var beforePhotosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            beforePhotosHeader
            
            if beforeImages.isEmpty {
                emptyBeforePhotosView
            } else {
                beforePhotosGrid
            }
        }
    }
    
    private var beforePhotosHeader: some View {
        HStack {
            Text("BEFORE PHOTOS")
                .font(.caption.bold())
                .foregroundColor(.yellow)
            
            Text("(Optional)")
                .font(.caption2)
                .foregroundColor(.gray)
            
            Spacer()
            
            PhotosPicker(
                selection: $beforePhotos,
                maxSelectionCount: 5,
                matching: .images
            ) {
                Label("Add", systemImage: "plus.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(.yellow)
            }
        }
    }
    
    private var emptyBeforePhotosView: some View {
        Text("No before photos added")
            .font(.caption)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
    }
    
    private var beforePhotosGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(beforeImages.enumerated()), id: \.offset) { index, image in
                    photoThumbnail(image: image) {
                        beforeImages.remove(at: index)
                    }
                }
            }
        }
    }
    
    private var afterPhotosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            afterPhotosHeader
            
            if afterImages.isEmpty {
                emptyAfterPhotosView
            } else {
                afterPhotosGrid
            }
        }
    }
    
    private var afterPhotosHeader: some View {
        HStack {
            Text("AFTER PHOTOS")
                .font(.caption.bold())
                .foregroundColor(.yellow)
            
            Text("(Required)")
                .font(.caption2)
                .foregroundColor(.orange)
            
            Spacer()
            
            PhotosPicker(
                selection: $afterPhotos,
                maxSelectionCount: 5,
                matching: .images
            ) {
                Label("Add", systemImage: "plus.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(.yellow)
            }
        }
    }
    
    private var emptyAfterPhotosView: some View {
        Text("No after photos added")
            .font(.caption)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
    }
    
    private var afterPhotosGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(afterImages.enumerated()), id: \.offset) { index, image in
                    photoThumbnail(image: image) {
                        afterImages.remove(at: index)
                    }
                }
            }
        }
    }
    
    private func photoThumbnail(image: UIImage, onRemove: @escaping () -> Void) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white.clipShape(Circle()))
            }
            .offset(x: 5, y: -5)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.caption.bold())
                .foregroundColor(.yellow)
            
            TextEditor(text: $note)
                .frame(height: 100)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.white)
        }
    }
    
    private var saveButton: some View {
        Button(action: saveProgress) {
            Text("POST BIKE UPDATE")
                .font(.headline.bold())
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSave ? Color.yellow : Color.gray)
                .cornerRadius(10)
        }
        .disabled(!canSave)
    }
    
    private func loadPhotos(from items: [PhotosPickerItem], into binding: Binding<[UIImage]>) {
        Task {
            var images: [UIImage] = []
            
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            
            await MainActor.run {
                binding.wrappedValue = images
            }
        }
    }
    
    private func saveProgress() {
        guard let profile = currentProfile else { return }
        
        // Save all photos and create BikeProgress entries
        // For now, we'll create one entry with multiple images saved
        // You could create separate entries for each before/after pair
        
        // Save first after image (primary)
        guard let firstAfter = afterImages.first else { return }
        let afterFilename = "bike_after_\(UUID().uuidString).jpg"
        saveImage(firstAfter, filename: afterFilename)
        
        // Save first before image if available
        var beforeFilename = ""
        if let firstBefore = beforeImages.first {
            beforeFilename = "bike_before_\(UUID().uuidString).jpg"
            saveImage(firstBefore, filename: beforeFilename)
        }
        
        // Create BikeProgress entry
        let progress = BikeProgress(
            modificationTitle: modificationTitle,
            note: note,
            beforeImage: beforeFilename,
            afterImage: afterFilename,
            bikeMake: bikeMake,
            bikeModel: bikeModel,
            bikeYear: bikeYear,
            userID: profile.appleUserID
        )
        
        modelContext.insert(progress)
        
        // Update profile stats
        profile.totalBikeProgressPosts += 1
        
        try? modelContext.save()
        
        showingSuccessAlert = true
    }
    
    private func saveImage(_ image: UIImage, filename: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(filename)
        try? data.write(to: filePath)
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}
