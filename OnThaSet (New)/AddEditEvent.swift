//
//  AddEditEvent.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/4/25.
//

import SwiftUI
import SwiftData
import PhotosUI
import CoreLocation

struct AddEditEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    var eventToEdit: Event?
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
    @State private var securityCode: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isPosting = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !securityCode.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var showsNationalBadge: Bool {
        category.isNationalEvent
    }

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

                submitButtonSection
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
        .alert("Event Posted!", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text(category.isNationalEvent
                ? "Your event is now live and will appear on the National Run Calendar map!"
                : "Your event is now live and visible to all riders on On Tha Set!")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Something went wrong. Please try again.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.yellow).font(.title2.bold())
            }
            Spacer()
            ZStack {
                Image(systemName: "shield.fill").font(.system(size: 45)).foregroundColor(.yellow)
                VStack(spacing: -1) {
                    Text("ON").font(.system(size: 7, weight: .black))
                    Text("THA").font(.system(size: 6, weight: .black))
                    Text("SET").font(.system(size: 9, weight: .black))
                }
                .foregroundColor(.black).offset(y: -2)
            }
            Spacer()
            Image(systemName: "xmark").opacity(0)
        }
        .padding(.horizontal, 25).padding(.vertical, 10)
    }

    // MARK: - Flyer

    private var flyerSection: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFit()
                        .frame(maxWidth: .infinity).frame(height: 220)
                        .cornerRadius(12).clipped()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1)).frame(height: 150)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus").font(.title)
                                Text("ADD EVENT FLYER").font(.caption.bold())
                            }
                            .foregroundColor(.yellow)
                        )
                }
            }
        }
    }

    // MARK: - Form Fields

    private var formFields: some View {
        VStack(spacing: 18) {

            fieldContainer(label: "EVENT TITLE") {
                TextField("Event name", text: $title)
                    .modifier(FormTextFieldStyle())
            }

            fieldContainer(label: "EVENT DATE & TIME") {
                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact).labelsHidden()
                    .colorScheme(.dark).padding()
                    .background(Color.white.opacity(0.1)).cornerRadius(8)
            }

            fieldContainer(label: "VENUE NAME") {
                TextField("Venue or location name", text: $venueName)
                    .modifier(FormTextFieldStyle())
            }

            fieldContainer(label: "STREET ADDRESS") {
                TextField("123 Main Street", text: $streetAddress)
                    .modifier(FormTextFieldStyle())
            }

            HStack(spacing: 12) {
                fieldContainer(label: "CITY") {
                    TextField("City", text: $cityName).modifier(FormTextFieldStyle())
                }
                fieldContainer(label: "STATE") {
                    TextField("ST", text: $stateName).modifier(FormTextFieldStyle())
                }
                .frame(width: 80)
            }

            fieldContainer(label: "ZIP CODE") {
                TextField("00000", text: $zipCode)
                    .modifier(FormTextFieldStyle()).keyboardType(.numberPad)
            }

            // CATEGORY BUTTONS
            fieldContainer(label: "CATEGORY") {
                VStack(spacing: 8) {

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(EventCategory.allCases, id: \.self) { cat in
                            Button(action: { category = cat }) {
                                HStack(spacing: 6) {
                                    Text(cat.icon).font(.caption)
                                    Text(cat.displayName)
                                        .font(.caption.bold())
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 10)
                                .background(category == cat ? Color.yellow : Color.white.opacity(0.08))
                                .foregroundColor(category == cat ? .black : .white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            category == cat ? Color.yellow : Color.gray.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                            }
                        }
                    }

                    // National calendar badge
                    if showsNationalBadge {
                        HStack(spacing: 8) {
                            Image(systemName: "map.fill")
                                .foregroundColor(.yellow).font(.caption)
                            Text("🗺️ This event will appear on the National Run Calendar")
                                .font(.caption).foregroundColor(.yellow)
                        }
                        .padding(10)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                        )
                    }
                }
            }

            fieldContainer(label: "DETAILS") {
                TextField("Describe your event", text: $details, axis: .vertical)
                    .lineLimit(3...5).modifier(FormTextFieldStyle())
            }

            fieldContainer(label: "SECURITY PIN (REQUIRED)") {
                TextField("4-digit pin", text: $securityCode)
                    .modifier(FormTextFieldStyle()).keyboardType(.numberPad)
            }
        }
    }

    // MARK: - Submit Button

    private var submitButtonSection: some View {
        Button(action: { Task { await saveToSupabase() } }) {
            HStack {
                if isPosting {
                    ProgressView().tint(.black).padding(.trailing, 4)
                }
                Text(isPosting ? "POSTING..." : "POST EVENT")
                    .font(.headline.bold()).foregroundColor(.black)
            }
            .frame(maxWidth: .infinity).padding()
            .background(isFormValid && !isPosting ? Color.yellow : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isPosting)
        .padding()
    }

    private func fieldContainer<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption2.bold()).foregroundColor(.yellow).padding(.leading, 5)
            content()
        }
    }

    // MARK: - Load Initial Data

    func loadInitialData() {
        guard let event = eventToEdit, !event.title.isEmpty else { return }
        title = event.title
        date = event.date
        let parts = event.locationName.split(separator: "|").map { String($0) }
        if parts.count >= 5 {
            venueName = parts[0]
            streetAddress = parts[1]
            cityName = parts[2]
            stateName = parts[3]
            zipCode = parts[4]
        }
        category = event.category
        details = event.details
        securityCode = event.securityCode
        selectedImageData = event.imageData
    }

    // MARK: - Save to Supabase

    func saveToSupabase() async {
        isPosting = true

        let fullAddress = "\(streetAddress), \(cityName), \(stateName) \(zipCode)"
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.geocodeAddressString(fullAddress)
            let coordinate = placemarks.first?.location?.coordinate
            let combinedLocation = "\(venueName)|\(streetAddress)|\(cityName)|\(stateName)|\(zipCode)"

            var imageURL: String? = nil
            if let imageData = selectedImageData {
                let fileName = "flyer-\(UUID().uuidString).jpg"
                do {
                    imageURL = try await SupabaseManager.shared.uploadImage(
                        data: imageData, bucket: "event-flyers", fileName: fileName
                    )
                    print("✅ Flyer uploaded: \(imageURL ?? "")")
                } catch {
                    print("⚠️ Image upload failed, continuing without image: \(error)")
                }
            }

            let supabaseEvent = SupabaseEvent(
                id: nil,
                title: title,
                date: date,
                category: category.rawValue,
                locationName: combinedLocation,
                details: details,
                price: "0.00",
                latitude: coordinate?.latitude ?? 0.0,
                longitude: coordinate?.longitude ?? 0.0,
                postedByUserID: profiles.first?.appleUserID ?? "",
                postedByName: profiles.first?.displayName.isEmpty == false
                    ? profiles.first!.displayName
                    : profiles.first?.email ?? "Anonymous",
                imageURL: imageURL
            )

            print("🔵 Posting event: \(supabaseEvent.title)")
            try await SupabaseManager.shared.postEvent(supabaseEvent)

            if let onSave = onSave {
                let localEvent = Event(
                    title: title,
                    date: date,
                    category: category,
                    locationName: combinedLocation,
                    details: details,
                    securityCode: securityCode,
                    price: "0.00",
                    latitude: coordinate?.latitude ?? 0.0,
                    longitude: coordinate?.longitude ?? 0.0,
                    postedByUserID: profiles.first?.appleUserID ?? "",
                    postedByName: profiles.first?.displayName ?? ""
                )
                localEvent.imageData = selectedImageData
                onSave(localEvent)
            }

            print("✅ Event posted to Supabase successfully")
            isPosting = false
            showSuccessAlert = true

        } catch {
            print("❌ Error posting event: \(error)")
            errorMessage = error.localizedDescription
            isPosting = false
            showErrorAlert = true
        }
    }
}

// MARK: - Global View Modifier
struct FormTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}
