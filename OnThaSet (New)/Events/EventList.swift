//
//  EventList.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/4/25.
//

import SwiftUI
import MapKit

struct EventHomeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = SupabaseManager.shared

    @State private var viewMode: ViewMode = .list
    @State private var selectedDate = Date()

    enum ViewMode {
        case list, calendar
    }

    init(initialMode: ViewMode = .list) {
        _viewMode = State(initialValue: initialMode)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: -5) {
                    ZStack {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 65))
                            .foregroundColor(.yellow)
                        VStack(spacing: -2) {
                            Text("ON").font(.system(size: 11, weight: .black)).foregroundColor(.black)
                            Text("THA").font(.system(size: 9, weight: .black)).foregroundColor(.black)
                            Text("SET").font(.system(size: 15, weight: .black)).foregroundColor(.black)
                        }
                        .offset(y: -2)
                    }
                }
                .padding(.top, 10)

                Picker("View", selection: $viewMode) {
                    Text("List").tag(ViewMode.list)
                    Text("Calendar").tag(ViewMode.calendar)
                }
                .pickerStyle(.segmented)
                .background(Color.yellow.opacity(0.8).cornerRadius(8))
                .padding()

                if viewMode == .list {
                    eventList
                } else {
                    calendarView
                }
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
        }
        .task {
            await manager.fetchAllEvents()
        }
    }
}

// MARK: - Sub-Views
extension EventHomeView {

    var eventList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {

                // PREMIUM AD BANNER
                PremiumAdStripView()
                    .padding(.top, 4)

                if manager.isLoading {
                    ProgressView()
                        .tint(.yellow)
                        .padding(.top, 50)
                } else if manager.events.isEmpty {
                    ContentUnavailableView(
                        "No Events Posted",
                        systemImage: "signpost.right.and.left.fill",
                        description: Text("The road is empty. Be the first to post an event!")
                    )
                    .foregroundColor(.gray)
                    .padding(.top, 50)
                } else {
                    ForEach(manager.events) { event in
                        NavigationLink(destination: SupabaseEventDetailView(event: event)) {
                            SupabaseEventRow(event: event)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .refreshable {
            await manager.fetchAllEvents()
        }
    }

    var calendarView: some View {
        VStack {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .accentColor(.yellow)
                .colorScheme(.dark)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(15)
                .padding()

            let filteredEvents = manager.events.filter {
                Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
            }

            ScrollView {
                ForEach(filteredEvents) { event in
                    NavigationLink(destination: SupabaseEventDetailView(event: event)) {
                        SupabaseEventRow(event: event)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Supabase Event Row
struct SupabaseEventRow: View {
    let event: SupabaseEvent

    var displayLocation: String {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        if parts.count >= 3 { return "\(parts[0]) — \(parts[2])" }
        return event.locationName
    }

    var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.1))
            .frame(width: 70, height: 70)
            .overlay(Image(systemName: "photo").foregroundColor(.gray))
    }

    var body: some View {
        HStack(spacing: 12) {
            if let urlString = event.imageURL,
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                            .frame(width: 70, height: 70).cornerRadius(8).clipped()
                    case .empty:
                        ProgressView().frame(width: 70, height: 70)
                    default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(event.title).font(.headline.bold()).foregroundColor(.white)
                HStack(spacing: 8) {
                    Image(systemName: "calendar").font(.caption).foregroundColor(.yellow)
                    Text(event.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundColor(.gray)
                }
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill").font(.caption).foregroundColor(.yellow)
                    Text(displayLocation).font(.caption).foregroundColor(.gray).lineLimit(1)
                }
                HStack(spacing: 8) {
                    Image(systemName: "tag.fill").font(.caption).foregroundColor(.yellow)
                    Text(event.category.capitalized).font(.caption).foregroundColor(.gray)
                    Spacer()
                    Text("Posted by \(event.postedByName)")
                        .font(.caption2).foregroundColor(.gray.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - Supabase Event Detail View
struct SupabaseEventDetailView: View {
    let event: SupabaseEvent
    @Environment(\.dismiss) var dismiss

    @State private var showingWeather = false
    @State private var showingNavigationOptions = false
    @State private var showingFullImage = false
    @State private var showingShare = false

    var cityName: String {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        return parts.count >= 3 ? parts[2] : event.locationName
    }

    var venueName: String {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        return parts.first ?? event.title
    }

    var flyerPlaceholder: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color.white.opacity(0.1)).frame(height: 200)
            .overlay(VStack(spacing: 10) {
                Image(systemName: "photo").font(.system(size: 40)).foregroundColor(.gray)
                Text("No Flyer").foregroundColor(.gray)
            })
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // FLYER IMAGE
                    if let urlString = event.imageURL,
                       !urlString.isEmpty,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFit()
                                    .frame(maxWidth: .infinity).frame(height: 300)
                                    .cornerRadius(15)
                                    .shadow(color: .yellow.opacity(0.3), radius: 10)
                                    .onTapGesture { showingFullImage = true }
                            case .empty:
                                ProgressView().tint(.yellow).frame(height: 200)
                            default:
                                flyerPlaceholder
                            }
                        }
                    } else {
                        flyerPlaceholder
                    }

                    // EVENT INFO CARD
                    VStack(alignment: .leading, spacing: 15) {
                        Text(event.title.uppercased())
                            .font(.title.bold()).foregroundColor(.yellow)

                        Divider().background(Color.yellow.opacity(0.3))

                        HStack {
                            Image(systemName: "calendar").foregroundColor(.yellow)
                            Text(event.date.formatted(date: .long, time: .shortened)).foregroundColor(.white)
                        }

                        let locationParts = event.locationName.split(separator: "|").map { String($0) }
                        if locationParts.count >= 5 {
                            HStack(alignment: .top) {
                                Image(systemName: "mappin.circle.fill").foregroundColor(.yellow)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(locationParts[0]).font(.headline).foregroundColor(.white)
                                    Text(locationParts[1]).font(.subheadline).foregroundColor(.gray)
                                    Text("\(locationParts[2]), \(locationParts[3]) \(locationParts[4])")
                                        .font(.subheadline).foregroundColor(.gray)
                                }
                            }
                        } else {
                            HStack {
                                Image(systemName: "mappin.circle.fill").foregroundColor(.yellow)
                                Text(event.locationName).foregroundColor(.white)
                            }
                        }

                        HStack {
                            Image(systemName: "tag.fill").foregroundColor(.yellow)
                            Text(event.category.capitalized).foregroundColor(.white)
                        }

                        if event.price != "0.00" {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill").foregroundColor(.yellow)
                                Text(event.price).foregroundColor(.white)
                            }
                        }

                        if !event.details.isEmpty {
                            Divider().background(Color.yellow.opacity(0.3))
                            Text("Details").font(.headline).foregroundColor(.yellow)
                            Text(event.details).foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Text("Posted by \(event.postedByName)")
                            .font(.caption).foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(15)

                    // SHARE BUTTON
                    Button(action: { showingShare = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("SHARE EVENT").fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.yellow).foregroundColor(.black).cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // WEATHER & DIRECTIONS
                    HStack(spacing: 12) {
                        Button(action: { showingWeather = true }) {
                            HStack {
                                Image(systemName: "cloud.sun.fill").symbolRenderingMode(.multicolor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Weather").font(.caption.bold())
                                    Text("Forecast").font(.caption2).foregroundColor(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.blue.opacity(0.2)).foregroundColor(.white).cornerRadius(12)
                        }

                        Button(action: { showingNavigationOptions = true }) {
                            HStack {
                                Image(systemName: "location.fill").foregroundColor(.yellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Navigate").font(.caption.bold())
                                    Text("Get Directions").font(.caption2).foregroundColor(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.green.opacity(0.2)).foregroundColor(.white).cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    // MAP
                    if event.latitude != 0 && event.longitude != 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("LOCATION").font(.headline).foregroundColor(.yellow)
                            Map(position: .constant(
                                MapCameraPosition.region(MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(
                                        latitude: event.latitude,
                                        longitude: event.longitude
                                    ),
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                ))
                            )) {
                                Marker(venueName, coordinate: CLLocationCoordinate2D(
                                    latitude: event.latitude,
                                    longitude: event.longitude
                                ))
                                .tint(.yellow)
                            }
                            .frame(height: 200).cornerRadius(15).disabled(true)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.yellow)
                }
            }
            ToolbarItem(placement: .principal) {
                ZStack {
                    Image(systemName: "shield.fill").font(.system(size: 35)).foregroundColor(.yellow)
                    VStack(spacing: -1) {
                        Text("ON").font(.system(size: 6, weight: .black))
                        Text("THA").font(.system(size: 5, weight: .black))
                        Text("SET").font(.system(size: 8, weight: .black))
                    }
                    .foregroundColor(.black).offset(y: -1)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingShare = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3).foregroundColor(.yellow)
                }
            }
        }
        .sheet(isPresented: $showingShare) {
            SupabaseEventShareView(
                title: event.title,
                date: event.date,
                locationName: event.locationName,
                details: event.details,
                category: event.category,
                imageURL: event.imageURL
            )
        }
        .sheet(isPresented: $showingWeather) {
            if event.latitude != 0 && event.longitude != 0 {
                WeatherViewForCoordinates(
                    latitude: event.latitude,
                    longitude: event.longitude,
                    locationName: venueName
                )
            } else {
                WeatherViewForEvent(cityName: cityName)
            }
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

    func openAppleMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = venueName
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    func openGoogleMaps() {
        let googleURL = "comgooglemaps://?daddr=\(event.latitude),\(event.longitude)&directionsmode=driving"
        let webURL = "https://www.google.com/maps/dir/?api=1&destination=\(event.latitude),\(event.longitude)"
        if let url = URL(string: googleURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: webURL) {
            UIApplication.shared.open(url)
        }
    }

    func openWaze() {
        if let url = URL(string: "https://waze.com/ul?ll=\(event.latitude),\(event.longitude)&navigate=yes") {
            UIApplication.shared.open(url)
        }
    }
}
