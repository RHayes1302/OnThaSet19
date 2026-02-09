//
//  EditProfileView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile
    
    @State private var profilePickerItem: PhotosPickerItem?
    @State private var backgroundPickerItem: PhotosPickerItem?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    Text("EDIT PROFILE")
                        .font(.title.bold())
                        .foregroundColor(.yellow)
                        .padding(.top, 20)
                    
                    // PROFILE & BACKGROUND IMAGES
                    imageSection
                    
                    // BASIC INFO
                    basicInfoSection
                    
                    // RIDING INFO
                    ridingInfoSection
                    
                    // SOCIAL LINKS
                    socialLinksSection
                    
                    // SAVE BUTTON
                    Button(action: {
                        dismiss()
                    }) {
                        Text("SAVE PROFILE")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(12)
                    }
                    .padding(.bottom, 40)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: profilePickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    profile.profileImageData = data
                }
            }
        }
        .onChange(of: backgroundPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    profile.backgroundImageData = data
                }
            }
        }
    }
    
    // MARK: - Image Section
    
    private var imageSection: some View {
        VStack(spacing: 20) {
            // Profile Picture
            VStack(spacing: 10) {
                Text("Profile Picture")
                    .font(.headline)
                    .foregroundColor(.white)
                
                PhotosPicker(selection: $profilePickerItem, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        if let data = profile.profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.yellow)
                        }
                        
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "camera.fill")
                                    .font(.caption)
                                    .foregroundColor(.black)
                                    .padding(8)
                                    .background(Color.yellow)
                                    .clipShape(Circle())
                                    .offset(x: -10, y: -10)
                            }
                        }
                        .frame(width: 120, height: 120)
                    }
                }
            }
            
            // Background Image
            VStack(spacing: 10) {
                Text("Background Image")
                    .font(.headline)
                    .foregroundColor(.white)
                
                PhotosPicker(selection: $backgroundPickerItem, matching: .images) {
                    ZStack {
                        if let data = profile.backgroundImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 150)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.title)
                                            .foregroundColor(.yellow)
                                        Text("Tap to add background")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(title: "BASIC INFO")
            
            fieldContainer(label: "Display Name") {
                TextField("Your name", text: $profile.displayName)
                    .textFieldStyle(ProfileTextFieldStyle())
            }
            
            fieldContainer(label: "Bio") {
                TextField("Tell us about yourself", text: $profile.bio, axis: .vertical)
                    .textFieldStyle(ProfileTextFieldStyle())
                    .lineLimit(3...5)
            }
            
            fieldContainer(label: "Hometown") {
                TextField("Where you're from", text: $profile.hometown)
                    .textFieldStyle(ProfileTextFieldStyle())
            }
            
            fieldContainer(label: "Club") {
                TextField("Motorcycle club (optional)", text: $profile.club)
                    .textFieldStyle(ProfileTextFieldStyle())
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
    
    // MARK: - Riding Info Section
    
    private var ridingInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(title: "RIDING INFO")
            
            fieldContainer(label: "Favorite Ride") {
                TextField("Your motorcycle", text: $profile.favoriteRide)
                    .textFieldStyle(ProfileTextFieldStyle())
            }
            
            fieldContainer(label: "Riding Since") {
                TextField("Year", text: $profile.ridingSince)
                    .textFieldStyle(ProfileTextFieldStyle())
                    .keyboardType(.numberPad)
            }
            
            fieldContainer(label: "Preferred Ride Type") {
                TextField("Solo, Group, Long Distance, etc.", text: $profile.preferredRideType)
                    .textFieldStyle(ProfileTextFieldStyle())
            }
            
            fieldContainer(label: "Favorite Route") {
                TextField("Your favorite place to ride", text: $profile.favoriteRoute)
                    .textFieldStyle(ProfileTextFieldStyle())
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
    
    // MARK: - Social Links Section
    
    private var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(title: "SOCIAL MEDIA")
            
            fieldContainer(label: "Instagram", icon: "camera.fill") {
                TextField("@username", text: $profile.instagramHandle)
                    .textFieldStyle(ProfileTextFieldStyle())
                    .textInputAutocapitalization(.never)
            }
            
            fieldContainer(label: "TikTok", icon: "music.note") {
                TextField("@username", text: $profile.tiktokHandle)
                    .textFieldStyle(ProfileTextFieldStyle())
                    .textInputAutocapitalization(.never)
            }
            
            fieldContainer(label: "YouTube", icon: "play.rectangle.fill") {
                TextField("@channel", text: $profile.youtubeChannel)
                    .textFieldStyle(ProfileTextFieldStyle())
                    .textInputAutocapitalization(.never)
            }
            
            fieldContainer(label: "Facebook", icon: "person.2.fill") {
                TextField("@username", text: $profile.facebookHandle)
                    .textFieldStyle(ProfileTextFieldStyle())
                    .textInputAutocapitalization(.never)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.headline.bold())
            .foregroundColor(.yellow)
    }
    
    private func fieldContainer<Content: View>(label: String, icon: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(.gray)
            }
            content()
        }
    }
}

// MARK: - Text Field Style

struct ProfileTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}
