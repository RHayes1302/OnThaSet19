//
//  EditAdView.swift
//  OnThaSet (New)
//
//  Advertiser self-service portal — update phone, address, photo, tagline

import SwiftUI
import PhotosUI

struct EditAdView: View {
    let ad: SupabaseAd
    @Environment(\.dismiss) private var dismiss

    // Form fields
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var tagline: String = ""
    @State private var websiteURL: String = ""
    @State private var isAppointmentOnly: Bool = false
    @State private var hideAddress: Bool = false

    // Photo
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var currentImageURL: String = ""

    // State
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var showError = false

    private let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {

                        // Header
                        VStack(spacing: 6) {
                            Text(ad.businessName)
                                .font(.title2.bold()).foregroundColor(.white)
                            Text("Update Your Ad")
                                .font(.subheadline).foregroundColor(.gray)
                        }
                        .padding(.top, 10)

                        // Photo section
                        photoSection

                        // Fields
                        fieldsSection

                        // Save button
                        Button(action: { Task { await saveChanges() } }) {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.black).scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                Text(isSaving ? "Saving..." : "Save Changes")
                                    .font(.headline.bold())
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(Color.yellow)
                            .cornerRadius(12)
                        }
                        .disabled(isSaving)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Edit Ad").font(.headline.bold()).foregroundColor(.white)
                }
            }
            .alert("Updated!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your ad has been updated successfully.")
            }
            .alert("Update Failed", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let item,
                       let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        await MainActor.run { selectedImage = img }
                    }
                }
            }
            .onAppear { loadCurrentValues() }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(spacing: 12) {
            Text("AD PHOTO / LOGO")
                .font(.caption.bold()).foregroundColor(.yellow)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 140)

                if let img = selectedImage {
                    Image(uiImage: img)
                        .resizable().scaledToFit()
                        .frame(height: 120).cornerRadius(8)
                } else if !currentImageURL.isEmpty, let url = URL(string: currentImageURL) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFit()
                                .frame(height: 120).cornerRadius(8)
                        } else {
                            photoPlaceholder
                        }
                    }
                } else {
                    photoPlaceholder
                }
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Change Photo", systemImage: "photo.badge.plus")
                    .font(.subheadline.bold())
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }

    private var photoPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 40)).foregroundColor(.gray)
            Text("Tap to add photo").font(.caption).foregroundColor(.gray)
        }
    }

    // MARK: - Fields Section

    private var fieldsSection: some View {
        VStack(spacing: 16) {

            fieldRow(icon: "phone.fill", label: "Phone Number", placeholder: "e.g. (702) 555-1234", text: $phone, keyboardType: .phonePad)

            fieldRow(icon: "location.fill", label: "Address", placeholder: "Street address", text: $address, keyboardType: .default)

            fieldRow(icon: "globe", label: "Website", placeholder: "https://yoursite.com", text: $websiteURL, keyboardType: .URL)

            VStack(alignment: .leading, spacing: 6) {
                Label("Tagline", systemImage: "text.quote")
                    .font(.caption.bold()).foregroundColor(.yellow)
                TextField("Short description of your business", text: $tagline)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            // Toggles
            VStack(spacing: 12) {
                Toggle(isOn: $isAppointmentOnly) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Appointment Only")
                                .font(.subheadline.bold()).foregroundColor(.white)
                            Text("Shows 'Call to Schedule' instead of address")
                                .font(.caption2).foregroundColor(.gray)
                        }
                    }
                }
                .tint(.yellow)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)

                Toggle(isOn: $hideAddress) {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.slash")
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hide Address")
                                .font(.subheadline.bold()).foregroundColor(.white)
                            Text("Keep your location private on the ad")
                                .font(.caption2).foregroundColor(.gray)
                        }
                    }
                }
                .tint(.yellow)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }

    private func fieldRow(icon: String, label: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.caption.bold()).foregroundColor(.yellow)
            TextField(placeholder, text: text)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .padding(12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }

    // MARK: - Load & Save

    private func loadCurrentValues() {
        phone = ad.phone ?? ""
        address = ad.address ?? ""
        tagline = ad.tagline
        websiteURL = ad.websiteURL ?? ""
        currentImageURL = ad.imageURL ?? ""
        // Load toggles from notes field or defaults
        isAppointmentOnly = ad.notes?.contains("appointment_only:true") ?? false
        hideAddress = ad.notes?.contains("hide_address:true") ?? false
    }

    private func saveChanges() async {
        guard let adID = ad.id else {
            errorMessage = "Could not identify ad record."
            showError = true
            return
        }

        await MainActor.run { isSaving = true }

        var newImageURL = currentImageURL

        // Upload new photo if selected
        if let image = selectedImage,
           let data = image.jpegData(compressionQuality: 0.8) {
            let fileName = "ad_banner_\(adID.uuidString)_\(Int(Date().timeIntervalSince1970)).jpg"
            if let uploadedURL = try? await SupabaseManager.shared.uploadImage(data: data, bucket: "ad-banners", fileName: fileName) {
                newImageURL = uploadedURL
            }
        }

        // Build notes field with toggle flags
        var notesFlags: [String] = []
        if isAppointmentOnly { notesFlags.append("appointment_only:true") }
        if hideAddress { notesFlags.append("hide_address:true") }
        let notesValue = notesFlags.isEmpty ? "" : notesFlags.joined(separator: ",")

        // Build PATCH body
        var body: [String: Any] = [
            "phone": phone,
            "tagline": tagline,
            "website_url": websiteURL,
            "image_url": newImageURL,
            "notes": notesValue
        ]
        if !hideAddress { body["address"] = address }

        guard let url = URL(string: "\(projectURL)/rest/v1/ads?id=eq.\(adID.uuidString)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        if let (_, response) = try? await URLSession.shared.data(for: request),
           let http = response as? HTTPURLResponse {
            await MainActor.run {
                isSaving = false
                if http.statusCode == 200 || http.statusCode == 204 {
                    showSuccess = true
                    // Refresh ads
                    Task { await SupabaseManager.shared.fetchActiveAds() }
                } else {
                    errorMessage = "Server returned status \(http.statusCode)"
                    showError = true
                }
            }
        } else {
            await MainActor.run {
                isSaving = false
                errorMessage = "Network error. Please try again."
                showError = true
            }
        }
    }
}

// MARK: - Ad Edit PIN Gate

struct AdEditPinView: View {
    let ad: SupabaseAd
    @Environment(\.dismiss) private var dismiss

    // Step tracking
    @State private var step: Step = .pin

    @State private var enteredPIN = ""
    @State private var confirmPIN = ""
    @State private var isConfirming = false
    @State private var pinError = ""
    @State private var shake = false
    @State private var isSaving = false
    @State private var showEdit = false

    private let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
    private var hasPin: Bool { !(ad.advertiserPin ?? "").isEmpty }

    enum Step { case pin, setPin }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 30) {
                    Spacer()

                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 70)).foregroundColor(.yellow)

                    switch step {
                    case .pin:
                        pinStep
                    case .setPin:
                        setPinStep
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold)).foregroundColor(.yellow)
                    }
                }
            }
            .navigationDestination(isPresented: $showEdit) {
                EditAdView(ad: ad)
            }
            .onAppear {
                step = hasPin ? .pin : .setPin
            }
        }
    }

    // MARK: - PIN Entry Step (existing PIN)

    private var pinStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(hasPin ? "Enter Your PIN" : "No PIN Set").font(.title2.bold()).foregroundColor(.white)
                Text(hasPin ? "Enter your 4-digit advertiser PIN" : "Contact support to reset your PIN")
                    .font(.subheadline).foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            pinDots(code: enteredPIN)

            if !pinError.isEmpty {
                Text(pinError).font(.caption).foregroundColor(.red)
            }

            numPad { digit in
                guard enteredPIN.count < 4 else { return }
                enteredPIN += digit
                pinError = ""
                if enteredPIN.count == 4 { checkPIN() }
            } onDelete: {
                if !enteredPIN.isEmpty { enteredPIN.removeLast() }
                pinError = ""
            } onConfirm: {
                if enteredPIN.count == 4 { checkPIN() }
            }
        }
    }

    // MARK: - Set PIN Step (first time)

    private var setPinStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(isConfirming ? "Confirm Your PIN" : "Create a PIN").font(.title2.bold()).foregroundColor(.white)
                Text(isConfirming ? "Re-enter your 4-digit PIN to confirm" : "Choose a 4-digit PIN to protect your ad")
                    .font(.subheadline).foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            pinDots(code: isConfirming ? confirmPIN : enteredPIN)

            if !pinError.isEmpty {
                Text(pinError).font(.caption).foregroundColor(.red)
            }

            if isSaving {
                ProgressView("Saving PIN...").tint(.yellow)
            } else {
                numPad { digit in
                    pinError = ""
                    if isConfirming {
                        guard confirmPIN.count < 4 else { return }
                        confirmPIN += digit
                        if confirmPIN.count == 4 { confirmNewPIN() }
                    } else {
                        guard enteredPIN.count < 4 else { return }
                        enteredPIN += digit
                        if enteredPIN.count == 4 { isConfirming = true }
                    }
                } onDelete: {
                    if isConfirming {
                        if !confirmPIN.isEmpty { confirmPIN.removeLast() }
                    } else {
                        if !enteredPIN.isEmpty { enteredPIN.removeLast() }
                    }
                    pinError = ""
                } onConfirm: {
                    if isConfirming && confirmPIN.count == 4 { confirmNewPIN() }
                    else if !isConfirming && enteredPIN.count == 4 { isConfirming = true }
                }
            }
        }
    }

    // MARK: - Shared UI

    private func pinDots(code: String) -> some View {
        HStack(spacing: 20) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(i < code.count ? Color.yellow : Color.white.opacity(0.2))
                    .frame(width: 16, height: 16)
            }
        }
        .offset(x: shake ? -10 : 0)
        .animation(shake ? .easeInOut(duration: 0.1).repeatCount(5) : .default, value: shake)
    }

    private func numPad(onDigit: @escaping (String) -> Void, onDelete: @escaping () -> Void, onConfirm: @escaping () -> Void) -> some View {
        VStack(spacing: 15) {
            ForEach([[1,2,3],[4,5,6],[7,8,9]], id: \.self) { row in
                HStack(spacing: 25) {
                    ForEach(row, id: \.self) { num in
                        pinButton(label: "\(num)") { onDigit("\(num)") }
                    }
                }
            }
            HStack(spacing: 25) {
                pinButton(label: "⌫", color: .red.opacity(0.7)) { onDelete() }
                pinButton(label: "0") { onDigit("0") }
                pinButton(label: "✓", color: .green.opacity(0.7)) { onConfirm() }
            }
        }
    }

    private func pinButton(label: String, color: Color = Color.white.opacity(0.15), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.title2.bold()).foregroundColor(.white)
                .frame(width: 72, height: 72)
                .background(color).clipShape(Circle())
        }
    }

    // MARK: - Logic

    private func checkPIN() {
        if enteredPIN == (ad.advertiserPin ?? "") {
            showEdit = true
        } else {
            shake = true
            pinError = "Incorrect PIN. Try again."
            enteredPIN = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { shake = false }
        }
    }

    private func confirmNewPIN() {
        if confirmPIN == enteredPIN {
            Task { await savePIN(confirmPIN) }
        } else {
            shake = true
            pinError = "PINs don\'t match. Try again."
            confirmPIN = ""
            isConfirming = false
            enteredPIN = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { shake = false }
        }
    }

    private func savePIN(_ pin: String) async {
        guard let adID = ad.id else { return }
        await MainActor.run { isSaving = true }
        guard let url = URL(string: "\(projectURL)/rest/v1/ads?id=eq.\(adID.uuidString)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["advertiser_pin": pin])
        if let (_, response) = try? await URLSession.shared.data(for: request),
           let http = response as? HTTPURLResponse, http.statusCode == 204 || http.statusCode == 200 {
            await MainActor.run { isSaving = false; showEdit = true }
        } else {
            await MainActor.run { isSaving = false; pinError = "Failed to save PIN. Try again." }
        }
    }
}
