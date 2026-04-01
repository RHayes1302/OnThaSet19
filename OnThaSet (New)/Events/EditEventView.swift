//
//  EditEventView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/19/26.
//

//
//  EditEventView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/19/26.
//

import SwiftUI
import SwiftData
import PhotosUI
import CoreLocation

struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss

    var event: Event
    var onSave: ((Event) -> Void)?

    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var venueName: String = ""
    @State private var streetAddress: String = ""
    @State private var cityName: String = ""
    @State private var stateName: String = ""
    @State private var zipCode: String = ""
    @State private var category: EventCategory = .community
    @State private var details: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isSaving = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                ScrollView {
                    VStack(spacing: 25) {
                        flyerSection
                        formFields
                    }
                    .padding()
                }

                Button(action: {
                    Task { await saveToSupabase() }
                }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.black)
                                .padding(.trailing, 4)
                        }
                        Text(isSaving ? "SAVING..." : "SAVE CHANGES")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(!title.isEmpty && !isSaving ? Color.yellow : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(title.isEmpty || isSaving)
                .padding()
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadInitialData() }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImageData = ImageCompressor.compress(uiImage, maxSizeKB: 500)
                }
            }
        }
        .alert("Changes Saved!", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your event has been updated for all riders on On Tha Set.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Something went wrong. Please try again.")
        }
    }

    // MARK: - Sub-Views

    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.yellow)
                    .font(.title2.bold())
            }
            Spacer()
            ZStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 45))
                    .foregroundColor(.yellow)
                VStack(spacing: -1) {
                    Text("ON").font(.system(size: 7, weight: .black))
                    Text("THA").font(.system(size: 6, weight: .black))
                    Text("SET").font(.system(size: 9, weight: .black))
                }
                .foregroundColor(.black)
                .offset(y: -2)
            }
            Spacer()
            Image(systemName: "xmark").opacity(0)
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 10)
    }

    private var flyerSection: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .cornerRadius(12)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 150)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus").font(.title)
                                Text("CHANGE EVENT FLYER").font(.caption.bold())
                            }
                            .foregroundColor(.yellow)
                        )
                }
            }
        }
    }

    private var formFields: some View {
        VStack(spacing: 18) {
            fieldContainer(label: "EVENT TITLE") {
                TextField("Set Name", text: $title)
                    .modifier(FormTextFieldStyle())
            }

            fieldContainer(label: "EVENT DATE & TIME") {
                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }

            fieldContainer(label: "VENUE NAME") {
                TextField("e.g., The Hideout", text: $venueName)
                    .modifier(FormTextFieldStyle())
            }

            fieldContainer(label: "STREET ADDRESS") {
                TextField("e.g., 4211 Fossatello Ave", text: $streetAddress)
                    .modifier(FormTextFieldStyle())
            }

            HStack(spacing: 12) {
                fieldContainer(label: "CITY") {
                    TextField("Las Vegas", text: $cityName)
                        .modifier(FormTextFieldStyle())
                }
                fieldContainer(label: "STATE") {
                    TextField("NV", text: $stateName)
                        .modifier(FormTextFieldStyle())
                }
                .frame(width: 80)
            }

            fieldContainer(label: "ZIP CODE") {
                TextField("89084", text: $zipCode)
                    .modifier(FormTextFieldStyle())
                    .keyboardType(.numberPad)
            }

            fieldContainer(label: "CATEGORY") {
                Picker("Category", selection: $category) {
                    ForEach(EventCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.yellow)
            }

            fieldContainer(label: "DETAILS") {
                TextField("Description", text: $details, axis: .vertical)
                    .lineLimit(3...5)
                    .modifier(FormTextFieldStyle())
            }
        }
    }

    private func fieldContainer<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption2.bold())
                .foregroundColor(.yellow)
                .padding(.leading, 5)
            content()
        }
    }

    // MARK: - Load Initial Data

    func loadInitialData() {
        title = event.title
        date = event.date

        let parts = event.locationName.split(separator: "|").map { String($0) }
        if parts.count >= 5 {
            venueName = parts[0]
            streetAddress = parts[1]
            cityName = parts[2]
            stateName = parts[3]
            zipCode = parts[4]
        } else if parts.count == 3 {
            venueName = parts[0]
            cityName = parts[1]
            let addressParts = parts[2].components(separatedBy: ",")
            if addressParts.count >= 2 {
                streetAddress = addressParts[0].trimmingCharacters(in: .whitespaces)
            }
        }

        category = event.category
        details = event.details
        selectedImageData = event.imageData
    }

    // MARK: - Save to Supabase

    func saveToSupabase() async {
        isSaving = true

        let fullAddress = "\(streetAddress), \(cityName), \(stateName) \(zipCode)"
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.geocodeAddressString(fullAddress)
            let coordinate = placemarks.first?.location?.coordinate
            let combinedLocation = "\(venueName)|\(streetAddress)|\(cityName)|\(stateName)|\(zipCode)"

            // Upload new flyer if one was selected
            var imageURL: String? = nil
            if let imageData = selectedImageData {
                let fileName = "flyer-\(event.id)-updated.jpg"
                imageURL = try await SupabaseManager.shared.uploadImage(
                    data: imageData,
                    bucket: "event-flyers",
                    fileName: fileName
                )
                print("✅ Updated flyer uploaded: \(imageURL ?? "")")
            }

            // Update the event in Supabase
            try await supabase
                .from("events")
                .update([
                    "title": title,
                    "date": ISO8601DateFormatter().string(from: date),
                    "category": category.rawValue,
                    "location_name": combinedLocation,
                    "details": details,
                    "latitude": String(coordinate?.latitude ?? event.latitude),
                    "longitude": String(coordinate?.longitude ?? event.longitude)
                ])
                .eq("title", value: event.title)
                .eq("posted_by_user_id", value: event.postedByUserID)
                .execute()

            print("✅ Event updated in Supabase")

            // Also call local onSave if provided
            if let onSave = onSave {
                let updatedEvent = Event(
                    title: title,
                    date: date,
                    category: category,
                    locationName: combinedLocation,
                    details: details,
                    securityCode: event.securityCode,
                    price: event.price,
                    latitude: coordinate?.latitude ?? event.latitude,
                    longitude: coordinate?.longitude ?? event.longitude
                )
                updatedEvent.imageData = selectedImageData
                onSave(updatedEvent)
            }

            isSaving = false
            showSuccessAlert = true

        } catch {
            print("❌ Error updating event: \(error)")
            errorMessage = error.localizedDescription
            isSaving = false
            showErrorAlert = true
        }
    }
}
