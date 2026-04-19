//
//  NearbyEvents.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/7/25.
//

import SwiftUI

struct NearbyEventsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var locationService = LocationManager.shared

    @State private var nearbyEvents: [NearbyEvent] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchRadius: Double = 100
    @State private var timeFilter: TimeFilter = .nextMonth
    @State private var hasFetched = false

    enum TimeFilter: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case nextMonth = "Month"
        case all = "All Upcoming"
        var displayName: String { rawValue }
    }

    var filteredEvents: [NearbyEvent] {
        let now = Date()
        let calendar = Calendar.current
        return nearbyEvents.filter { event in
            guard event.date >= now else { return false }
            switch timeFilter {
            case .today: return calendar.isDateInToday(event.date)
            case .thisWeek:
                guard let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now) else { return false }
                return event.date <= weekFromNow
            case .nextMonth:
                guard let monthFromNow = calendar.date(byAdding: .month, value: 1, to: now) else { return false }
                return event.date <= monthFromNow
            case .all: return true
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // BRANDED HEADER
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.yellow).font(.title2.bold())
                    }
                    Spacer()
                    ZStack {
                        Image(systemName: "shield.fill").font(.system(size: 70)).foregroundColor(.yellow)
                        VStack(spacing: -2) {
                            Text("ON").font(.system(size: 11, weight: .black))
                            Text("THA").font(.system(size: 9, weight: .black))
                            Text("SET").font(.system(size: 15, weight: .black))
                        }.foregroundColor(.black).offset(y: -3)
                    }
                    Spacer()
                    Button(action: {
                        hasFetched = false
                        locationService.requestLocation()
                        Task { await fetchNearby() }
                    }) {
                        Image(systemName: "arrow.clockwise").font(.title3).foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal, 25).padding(.top, 10).padding(.bottom, 10)

                // TIME FILTER
                VStack(spacing: 8) {
                    Text("Time Range").font(.caption.bold()).foregroundColor(.yellow)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TimeFilter.allCases, id: \.self) { filter in
                                Button(action: {
                                    timeFilter = filter
                                    Task { await fetchNearby() }
                                }) {
                                    Text(filter.displayName).font(.caption.bold())
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(timeFilter == filter ? Color.yellow : Color.white.opacity(0.1))
                                        .foregroundColor(timeFilter == filter ? .black : .white)
                                        .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 10)

                // RADIUS SELECTOR
                VStack(spacing: 8) {
                    Text(searchRadius >= 9999 ? "Search Radius: MAX" : "Search Radius: \(Int(searchRadius)) miles")
                        .font(.caption.bold()).foregroundColor(.yellow)

                    HStack(spacing: 8) {
                        ForEach([100.0, 200.0, 300.0], id: \.self) { radius in
                            Button(action: {
                                searchRadius = radius
                                Task { await fetchNearby() }
                            }) {
                                Text("\(Int(radius))mi").font(.caption.bold())
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(searchRadius == radius ? Color.yellow : Color.white.opacity(0.1))
                                    .foregroundColor(searchRadius == radius ? .black : .white)
                                    .cornerRadius(15)
                            }
                        }
                    }
                    HStack(spacing: 8) {
                        ForEach([400.0, 500.0], id: \.self) { radius in
                            Button(action: {
                                searchRadius = radius
                                Task { await fetchNearby() }
                            }) {
                                Text("\(Int(radius))mi").font(.caption.bold())
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(searchRadius == radius ? Color.yellow : Color.white.opacity(0.1))
                                    .foregroundColor(searchRadius == radius ? .black : .white)
                                    .cornerRadius(15)
                            }
                        }
                        Button(action: {
                            searchRadius = 99999
                            Task { await fetchNearby() }
                        }) {
                            Text("MAX").font(.caption.bold())
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(searchRadius >= 9999 ? Color.yellow : Color.white.opacity(0.1))
                                .foregroundColor(searchRadius >= 9999 ? .black : .white)
                                .cornerRadius(15)
                        }
                    }
                }
                .padding(.horizontal).padding(.bottom, 15)

                // CONTENT AREA
                if isLoading {
                    Spacer()
                    ProgressView().tint(.yellow)
                    Text("Finding events near you...")
                        .font(.caption).foregroundColor(.gray).padding(.top, 8)
                    Spacer()
                } else if locationService.userLocation == nil && !hasFetched {
                    noLocationView
                } else if filteredEvents.isEmpty {
                    emptyStateView
                } else {
                    eventsListView
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            locationService.requestLocation()
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await fetchNearby()
            }
        }
        .onChange(of: locationService.userLocation) { _, newLocation in
            if newLocation != nil && !hasFetched {
                Task { await fetchNearby() }
            }
        }
        .onChange(of: timeFilter) { _, _ in
            Task { await fetchNearby() }
        }
    }

    func fetchNearby() async {
        let lat: Double
        let lng: Double
        if let location = locationService.userLocation {
            lat = location.coordinate.latitude
            lng = location.coordinate.longitude
        } else {
            lat = 36.1699
            lng = -115.1398
        }
        isLoading = true
        errorMessage = nil
        do {
            let radius = searchRadius >= 9999 ? 9999.0 : searchRadius
            let results = try await SupabaseManager.shared.fetchNearbyEvents(
                lat: lat, lng: lng, radiusMiles: radius
            )
            nearbyEvents = results
            hasFetched = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    var noLocationView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView().tint(.yellow)
            Text("Finding your location...").font(.headline).foregroundColor(.gray)
            Button(action: {
                locationService.requestLocation()
                Task { await fetchNearby() }
            }) {
                Text("SEARCH ANYWAY").font(.caption.bold()).foregroundColor(.black)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Color.yellow).cornerRadius(5)
            }
            Spacer()
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 50)).foregroundColor(.yellow.opacity(0.3))
            Text("No events found").font(.headline).foregroundColor(.white)
            Text(searchRadius >= 9999
                 ? "No events in the \(timeFilter.displayName.lowercased()) timeframe"
                 : "No events within \(Int(searchRadius)) miles")
                .font(.subheadline).foregroundColor(.gray)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            HStack(spacing: 12) {
                if searchRadius < 99999 {
                    Button(action: {
                        searchRadius = min(searchRadius + 100, 99999)
                        Task { await fetchNearby() }
                    }) {
                        Text("EXPAND RADIUS").font(.caption.bold()).foregroundColor(.black)
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Color.yellow).cornerRadius(5)
                    }
                }
                if timeFilter != .all {
                    Button(action: {
                        timeFilter = .all
                        Task { await fetchNearby() }
                    }) {
                        Text("SHOW ALL").font(.caption.bold()).foregroundColor(.black)
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Color.yellow.opacity(0.7)).cornerRadius(5)
                    }
                }
            }
            Spacer()
        }
    }

    var eventsListView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(filteredEvents.count) event\(filteredEvents.count == 1 ? "" : "s") found")
                    .font(.caption.bold()).foregroundColor(.yellow)
                Spacer()
                Text(timeFilter.displayName).font(.caption2).foregroundColor(.gray)
            }
            .padding(.horizontal).padding(.vertical, 8)
            .background(Color.white.opacity(0.05))

            // PREMIUM AD BANNER
            PremiumAdStripView()
                .padding(.top, 4)

            List {
                ForEach(filteredEvents) { event in
                    NavigationLink(destination: NearbyEventDetailView(event: event)) {
                        NearbyEventRow(event: event)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(.gray.opacity(0.2))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable { await fetchNearby() }
        }
    }
}

// MARK: - Nearby Event Row
struct NearbyEventRow: View {
    let event: NearbyEvent

    var displayLocation: String {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        return parts.count >= 3 ? "\(parts[0]) — \(parts[2])" : event.locationName
    }

    var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.1)).frame(width: 60, height: 60)
            .overlay(Image(systemName: "photo").foregroundColor(.gray).font(.caption))
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
                            .frame(width: 60, height: 60).cornerRadius(8).clipped()
                    case .empty:
                        ProgressView().frame(width: 60, height: 60)
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
                    Image(systemName: "mappin.circle.fill").font(.caption).foregroundColor(.yellow)
                    Text(displayLocation).font(.caption).foregroundColor(.gray).lineLimit(1)
                    Spacer()
                    Text(String(format: "%.1f mi away", event.distanceMiles))
                        .font(.caption.bold()).foregroundColor(.yellow)
                }
                HStack(spacing: 8) {
                    Image(systemName: "calendar").font(.caption).foregroundColor(.yellow)
                    Text(event.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Nearby Event Detail View
struct NearbyEventDetailView: View {
    let event: NearbyEvent
    @Environment(\.dismiss) var dismiss
    @State private var showingWeather = false
    @State private var showingNavigationOptions = false
    @State private var showingShare = false
    @State private var showingReport = false

    var venueName: String {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        return parts.first ?? event.title
    }

    var cityName: String {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        return parts.count >= 3 ? parts[2] : event.locationName
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // FLYER IMAGE
                    if let urlString = event.imageURL,
                       !urlString.isEmpty,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFit()
                                    .frame(maxWidth: .infinity).frame(height: 250)
                                    .cornerRadius(15)
                                    .shadow(color: .yellow.opacity(0.3), radius: 10)
                            case .empty:
                                ProgressView().tint(.yellow).frame(height: 200)
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal)
                    }

                    Text(event.title).font(.title.bold()).foregroundColor(.white).padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar").foregroundColor(.yellow)
                            Text(event.date.formatted(date: .long, time: .shortened)).foregroundColor(.white)
                        }

                        let parts = event.locationName.split(separator: "|").map { String($0) }
                        if parts.count >= 5 {
                            HStack(alignment: .top) {
                                Image(systemName: "mappin.circle.fill").foregroundColor(.yellow)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(parts[0]).font(.headline).foregroundColor(.white)
                                    Text(parts[1]).font(.subheadline).foregroundColor(.gray)
                                    Text("\(parts[2]), \(parts[3]) \(parts[4])")
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
                            Image(systemName: "location.fill").foregroundColor(.yellow)
                            Text(String(format: "%.1f miles away", event.distanceMiles))
                                .foregroundColor(.yellow).bold()
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
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12).padding(.horizontal)

                    if !event.details.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DETAILS").font(.caption.bold()).foregroundColor(.yellow)
                            Text(event.details).foregroundColor(.white)
                        }
                        .padding(.horizontal)
                    }

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

                    // POSTED BY — tappable profile link
                    NavigationLink(destination: PostedByProfileView(
                        userID: event.postedByUserID,
                        posterName: event.postedByName
                    )) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.circle.fill")
                                .font(.title3).foregroundColor(.yellow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Posted by")
                                    .font(.caption).foregroundColor(.gray)
                                Text(event.postedByName.isEmpty ? "Member" : event.postedByName)
                                    .font(.subheadline.bold()).foregroundColor(.yellow)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption).foregroundColor(.yellow.opacity(0.6))
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20).padding(.bottom, 40)
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
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    Button(action: { showingReport = true }) {
                        Image(systemName: "flag")
                            .font(.title3).foregroundColor(.red.opacity(0.8))
                    }
                    Button(action: { showingShare = true }) {
                        Image(systemName: "square.and.arrow.up").font(.title3).foregroundColor(.yellow)
                    }
                }
            }
        }
        .sheet(isPresented: $showingReport) {
            ReportEventView(
                eventID: event.id.uuidString,
                eventTitle: event.title
            )
        }
        .sheet(isPresented: $showingShare) {
            SupabaseEventShareView(
                title: event.title, date: event.date,
                locationName: event.locationName, details: event.details,
                category: event.category, imageURL: event.imageURL
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
        let url = URL(string: "maps://?daddr=\(event.latitude),\(event.longitude)&dirflg=d")
        if let url = url, UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
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
