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
    @State private var showingReportSheet = false
    @State private var region: MKCoordinateRegion

    init(event: Event) {
        self.event = event
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: event.latitude != 0 ? event.latitude : 36.1699,
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
                    flyerSection
                    infoCard
                    weatherAndDirections
                    mapSection
                    actionButtons
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { toolbarLogo }
            ToolbarItem(placement: .navigationBarTrailing) { toolbarButtons }
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            if let imageData = event.imageData, let uiImage = UIImage(data: imageData) {
                FullScreenImageView(image: uiImage)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditEventView(event: event, onSave: { updatedEvent in
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
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: EventShareHelper.createShareItems(for: event))
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportEventView(eventID: event.persistentModelID.hashValue.description, eventTitle: event.title)
        }
        .sheet(isPresented: $showingEnhancedShare) {
            EventShareView(event: event)
        }
        .sheet(isPresented: $showingWeather) {
            let locationParts = event.locationName.split(separator: "|").map { String($0) }
            let venueName = locationParts.first ?? event.title
            if event.latitude != 0 && event.longitude != 0 {
                WeatherViewForCoordinates(
                    latitude: event.latitude,
                    longitude: event.longitude,
                    locationName: venueName
                )
            } else if locationParts.count >= 3 {
                WeatherViewForEvent(cityName: String(locationParts[2]))
            }
        }
        .alert("Delete Event", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                let title = event.title
                let userID = event.postedByUserID
                Task {
                    await SupabaseManager.shared.deleteEventByTitleAndUser(title: title, userID: userID)
                    await SupabaseManager.shared.fetchAllEvents()
                }
                modelContext.delete(event)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this event? This cannot be undone.")
        }
        .confirmationDialog(
            "Choose Navigation App",
            isPresented: $showingNavigationOptions,
            titleVisibility: .visible
        ) {
            Button("Apple Maps") { openAppleMaps() }
            Button("Google Maps") { openGoogleMaps() }
            Button("Waze") { openWaze() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Get directions to this event")
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var flyerSection: some View {
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
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(event.title.uppercased())
                .font(.title.bold())
                .foregroundColor(.yellow)

            postedByRow

            Divider().background(Color.yellow.opacity(0.3))

            HStack {
                Image(systemName: "calendar").foregroundColor(.yellow)
                Text(event.date.formatted(date: .long, time: .shortened))
                    .foregroundColor(.white)
            }

            locationRow

            HStack {
                Image(systemName: "tag.fill").foregroundColor(.yellow)
                Text(event.category.displayName).foregroundColor(.white)
            }

            if !event.details.isEmpty {
                Divider().background(Color.yellow.opacity(0.3))
                Text("Details").font(.headline).foregroundColor(.yellow)
                Text(event.details)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }

    @ViewBuilder
    private var postedByRow: some View {
        if !event.postedByUserID.isEmpty {
            NavigationLink(destination: PostedByProfileView(
                userID: event.postedByUserID,
                posterName: event.postedByName
            )) {
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
    }

    private var locationRow: some View {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        return VStack(alignment: .leading, spacing: 5) {
            if parts.count >= 5 {
                HStack(alignment: .top) {
                    Image(systemName: "mappin.circle.fill").foregroundColor(.yellow)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(parts[0]).font(.headline).foregroundColor(.white)
                        Text(parts[1]).font(.subheadline).foregroundColor(.gray)
                        Text(parts[2] + ", " + parts[3] + " " + parts[4])
                            .font(.subheadline).foregroundColor(.gray)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "mappin.circle.fill").foregroundColor(.yellow)
                    Text(event.locationName).foregroundColor(.white)
                }
            }
        }
    }

    private var weatherAndDirections: some View {
        HStack(spacing: 12) {
            Button(action: { showingWeather = true }) {
                HStack {
                    Image(systemName: "cloud.sun.fill").symbolRenderingMode(.multicolor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weather").font(.caption.bold())
                        Text("Forecast").font(.caption2).foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            Button(action: { showingNavigationOptions = true }) {
                HStack {
                    Image(systemName: "location.fill").foregroundColor(.yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Navigate").font(.caption.bold())
                        Text("Get Directions").font(.caption2).foregroundColor(.gray)
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
    }

    @ViewBuilder
    private var mapSection: some View {
        if event.latitude != 0 && event.longitude != 0 {
            VStack(alignment: .leading, spacing: 10) {
                Text("LOCATION").font(.headline).foregroundColor(.yellow)
                Map(position: .constant(.region(region))) {
                    Marker(event.title, coordinate: CLLocationCoordinate2D(
                        latitude: event.latitude,
                        longitude: event.longitude
                    ))
                    .tint(.yellow)
                }
                .frame(height: 200)
                .cornerRadius(15)
                .disabled(true)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(15)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: { showingEnhancedShare = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("SHARE EVENT").fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow)
                .foregroundColor(.black)
                .cornerRadius(10)
            }
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

    private var toolbarLogo: some View {
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

    private var toolbarButtons: some View {
        HStack(spacing: 4) {
            Button(action: { showingReportSheet = true }) {
                Image(systemName: "flag")
                    .font(.title3)
                    .foregroundColor(.red.opacity(0.8))
            }
            Button(action: { showingEnhancedShare = true }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundColor(.yellow)
            }
        }
    }

    // MARK: - Navigation Methods

    private func openAppleMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        let locationParts = event.locationName.split(separator: "|").map { String($0) }
        mapItem.name = locationParts.first ?? event.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func openGoogleMaps() {
        let googleURL = "comgooglemaps://?daddr=\(event.latitude),\(event.longitude)&directionsmode=driving"
        let webURL = "https://www.google.com/maps/dir/?api=1&destination=\(event.latitude),\(event.longitude)"
        if let url = URL(string: googleURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: webURL) {
            UIApplication.shared.open(url)
        }
    }

    private func openWaze() {
        if let url = URL(string: "https://waze.com/ul?ll=\(event.latitude),\(event.longitude)&navigate=yes") {
            UIApplication.shared.open(url)
        }
    }
}

// Make Event conform to Identifiable for Map
extension Event: Identifiable { }
