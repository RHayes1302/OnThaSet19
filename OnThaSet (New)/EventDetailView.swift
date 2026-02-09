//
//  EventDetailView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/4/25.
//

import SwiftUI
import SwiftData
import MapKit

struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var event: Event
    
    @State private var showingFullImage = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var showingEnhancedShare = false
    @State private var showingWeather = false
    @State private var showingNavigationOptions = false
    @State private var region: MKCoordinateRegion
    
    init(event: Event) {
        self.event = event
        
        // Initialize map region centered on event location
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: event.latitude != 0 ? event.latitude : 36.1699, // Default to Las Vegas
                longitude: event.longitude != 0 ? event.longitude : -115.1398
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // FLYER IMAGE - TAPPABLE TO EXPAND
                    if let imageData = event.imageData, let uiImage = UIImage(data: imageData) {
                        Button(action: { showingFullImage = true }) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .cornerRadius(15)
                                .shadow(color: .yellow.opacity(0.3), radius: 10)
                                .overlay(
                                    // Tap indicator
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(.ultraThinMaterial)
                                                .cornerRadius(8)
                                                .padding()
                                        }
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 250)
                            .overlay(
                                VStack(spacing: 10) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("No Flyer")
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                    
                    // EVENT INFO CARD
                    VStack(alignment: .leading, spacing: 15) {
                        // Title
                        Text(event.title.uppercased())
                            .font(.title.bold())
                            .foregroundColor(.yellow)
                        
                        // 🆕 POSTED BY SECTION
                        if !event.postedByUserID.isEmpty {
                            NavigationLink(destination: PostedByProfileView(userID: event.postedByUserID)) {
                                HStack(spacing: 10) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.yellow)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Posted by")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(event.postedByName.isEmpty ? "Member" : event.postedByName)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.yellow)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.yellow.opacity(0.6))
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        
                        Divider().background(Color.yellow.opacity(0.3))
                        
                        // Date & Time
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.yellow)
                            Text(event.date.formatted(date: .long, time: .shortened))
                                .foregroundColor(.white)
                        }
                        
                        // Location - Parse the new format
                        VStack(alignment: .leading, spacing: 5) {
                            let locationParts = event.locationName.split(separator: "|").map { String($0) }
                            
                            if locationParts.count >= 5 {
                                // New format: VenueName|Street|City|State|ZIP
                                HStack(alignment: .top) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.yellow)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(locationParts[0]) // Venue name
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(locationParts[1]) // Street
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("\(locationParts[2]), \(locationParts[3]) \(locationParts[4])") // City, State ZIP
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            } else {
                                // Fallback for old format
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.yellow)
                                    Text(event.locationName)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        // Category
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.yellow)
                            Text(event.category.displayName)
                                .foregroundColor(.white)
                        }
                        
                        // Details
                        if !event.details.isEmpty {
                            Divider().background(Color.yellow.opacity(0.3))
                            
                            Text("Details")
                                .font(.headline)
                                .foregroundColor(.yellow)
                            
                            Text(event.details)
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(15)
                    
                    // WEATHER & GPS QUICK ACTIONS
                    HStack(spacing: 12) {
                        // WEATHER BUTTON
                        Button(action: { showingWeather = true }) {
                            HStack {
                                Image(systemName: "cloud.sun.fill")
                                    .symbolRenderingMode(.multicolor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Weather")
                                        .font(.caption.bold())
                                    Text("Forecast")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // GPS NAVIGATION BUTTON
                        Button(action: { showingNavigationOptions = true }) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.yellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Navigate")
                                        .font(.caption.bold())
                                    Text("Get Directions")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // MAP (if coordinates exist)
                    if event.latitude != 0 && event.longitude != 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("LOCATION")
                                .font(.headline)
                                .foregroundColor(.yellow)
                            
                            Map(coordinateRegion: $region, annotationItems: [event]) { location in
                                MapMarker(coordinate: CLLocationCoordinate2D(
                                    latitude: location.latitude,
                                    longitude: location.longitude
                                ), tint: .yellow)
                            }
                            .frame(height: 200)
                            .cornerRadius(15)
                            .disabled(true)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                    }
                    
                    // ACTION BUTTONS
                    VStack(spacing: 12) {
                        // SHARE BUTTON (Primary - most important for viral growth)
                        Button(action: { showingEnhancedShare = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("SHARE EVENT")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                        }
                        
                        // Edit and Delete buttons
                        HStack(spacing: 15) {
                            Button(action: { showingEditSheet = true }) {
                                Label("Edit", systemImage: "pencil")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .foregroundColor(.yellow)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: { showingDeleteAlert = true }) {
                                Label("Delete", systemImage: "trash")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.2))
                                    .foregroundColor(.red)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ZStack {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.yellow)
                    VStack(spacing: -1) {
                        Text("ON").font(.system(size: 6, weight: .black))
                        Text("THA").font(.system(size: 5, weight: .black))
                        Text("SET").font(.system(size: 8, weight: .black))
                    }
                    .foregroundColor(.black)
                    .offset(y: -1)
                }
            }
            
            // SHARE BUTTON
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEnhancedShare = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.yellow)
                }
            }
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            if let imageData = event.imageData, let uiImage = UIImage(data: imageData) {
                FullScreenImageView(image: uiImage)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditEventView(event: event, onSave: { updatedEvent in
                // Update the event
                event.title = updatedEvent.title
                event.date = updatedEvent.date
                event.locationName = updatedEvent.locationName
                event.category = updatedEvent.category
                event.details = updatedEvent.details
                event.imageData = updatedEvent.imageData
                event.latitude = updatedEvent.latitude
                event.longitude = updatedEvent.longitude
                
                try? modelContext.save()
                showingEditSheet = false
            })
        }
        .alert("Delete Event", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(event)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: EventShareHelper.createShareItems(for: event))
        }
        .sheet(isPresented: $showingEnhancedShare) {
            EventShareView(event: event)
        }
        .sheet(isPresented: $showingWeather) {
            // Use GPS coordinates for most accurate weather
            let locationParts = event.locationName.split(separator: "|").map { String($0) }
            let venueName = locationParts.first ?? event.title
            
            if event.latitude != 0 && event.longitude != 0 {
                WeatherViewForCoordinates(
                    latitude: event.latitude,
                    longitude: event.longitude,
                    locationName: venueName
                )
            } else if locationParts.count >= 3 {
                // Fallback to city name if no coordinates
                WeatherViewForEvent(cityName: String(locationParts[2]))
            }
        }
        .confirmationDialog("Choose Navigation App", isPresented: $showingNavigationOptions, titleVisibility: .visible) {
            Button("Apple Maps") {
                openAppleMaps()
            }
            Button("Google Maps") {
                openGoogleMaps()
            }
            Button("Waze") {
                openWaze()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Get directions to this event")
        }
    }
    
    // MARK: - Navigation Methods
    
    private func openAppleMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        
        let locationParts = event.locationName.split(separator: "|").map { String($0) }
        mapItem.name = locationParts.first ?? event.title
        
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    private func openGoogleMaps() {
        let googleMapsURL = "comgooglemaps://?daddr=\(event.latitude),\(event.longitude)&directionsmode=driving"
        let googleMapsWebURL = "https://www.google.com/maps/dir/?api=1&destination=\(event.latitude),\(event.longitude)"
        
        if let url = URL(string: googleMapsURL),
           UIApplication.shared.canOpenURL(url) {
            // Google Maps app is installed
            UIApplication.shared.open(url)
        } else if let url = URL(string: googleMapsWebURL) {
            // Fall back to web version
            UIApplication.shared.open(url)
        }
    }
    
    private func openWaze() {
        let wazeURL = "https://waze.com/ul?ll=\(event.latitude),\(event.longitude)&navigate=yes"
        
        if let url = URL(string: wazeURL) {
            UIApplication.shared.open(url)
        }
    }
}

// Make Event conform to Identifiable for Map
extension Event: Identifiable { }
