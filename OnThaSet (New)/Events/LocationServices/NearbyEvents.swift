//
//  NearbyEvents.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/7/25.
//

import SwiftUI
import SwiftData

struct NearbyEventsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    // USE SHARED LOCATION MANAGER (CRITICAL FIX!)
    @ObservedObject var locationService = LocationManager.shared
    
    @Query(sort: \Event.date) var allEvents: [Event]
    
    @State private var searchRadius: Double = 100 // miles - UPDATED FROM 50
    @State private var timeFilter: TimeFilter = .nextMonth

    enum TimeFilter: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case nextMonth = "Next Month"
        case all = "All Upcoming"
        
        var displayName: String { rawValue }
    }

    var nearbyEvents: [Event] {
        // DEBUG logging
        print("🔍 NEARBY EVENTS FILTER:")
        print("   Total events: \(allEvents.count)")
        print("   Has location: \(locationService.userLocation != nil)")
        print("   Auth status: \(locationService.authorizationStatus?.rawValue ?? -1)")
        
        let filtered = allEvents.filter { event in
            let isNearby = locationService.isNearby(event: event, radiusInMiles: searchRadius)
            let isInTimeRange = isEventInTimeRange(event)
            return isNearby && isInTimeRange
        }
        
        print("   ✅ Showing \(filtered.count) events")
        return filtered
    }
    
    private func isEventInTimeRange(_ event: Event) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        // Event must be in the future
        guard event.date >= now else { return false }
        
        switch timeFilter {
        case .today:
            return calendar.isDateInToday(event.date)
            
        case .thisWeek:
            guard let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now) else { return false }
            return event.date <= weekFromNow
            
        case .nextMonth:
            guard let monthFromNow = calendar.date(byAdding: .month, value: 1, to: now) else { return false }
            return event.date <= monthFromNow
            
        case .all:
            return true
        }
    }
    
    private func isEventThisWeek(_ event: Event) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        guard event.date >= now else { return false }
        guard let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now) else { return false }
        
        return event.date <= weekFromNow
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // BRANDED HEADER
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.yellow)
                            .font(.title2.bold())
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.yellow)
                        
                        VStack(spacing: -2) {
                            Text("ON").font(.system(size: 11, weight: .black))
                            Text("THA").font(.system(size: 9, weight: .black))
                            Text("SET").font(.system(size: 15, weight: .black))
                        }
                        .foregroundColor(.black)
                        .offset(y: -3)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        print("🔄 Manual location refresh")
                        locationService.requestLocation()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 10)
                .padding(.bottom, 10)
                
                // DEBUG INFO (Remove after testing)
                VStack(alignment: .leading, spacing: 4) {
                    Text("DEBUG INFO")
                        .font(.caption2.bold())
                        .foregroundColor(.red)
                    Text("Events: \(allEvents.count) | Location: \(locationService.userLocation != nil ? "✅" : "❌") | Auth: \(locationService.authorizationStatus?.rawValue ?? -1)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    if let loc = locationService.userLocation {
                        Text("Coords: \(String(format: "%.4f", loc.coordinate.latitude)), \(String(format: "%.4f", loc.coordinate.longitude))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                // TIME FILTER
                VStack(spacing: 8) {
                    Text("Time Range")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TimeFilter.allCases, id: \.self) { filter in
                                Button(action: { timeFilter = filter }) {
                                    Text(filter.displayName)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
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
                
                // RADIUS SELECTOR - UPDATED WITH NEW OPTIONS
                VStack(spacing: 8) {
                    Text(searchRadius >= 9999 ? "Search Radius: MAX" : "Search Radius: \(Int(searchRadius)) miles")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                    
                    // First row: 100, 200, 300
                    HStack(spacing: 8) {
                        ForEach([100.0, 200.0, 300.0], id: \.self) { radius in
                            Button(action: { searchRadius = radius }) {
                                Text("\(Int(radius))mi")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(searchRadius == radius ? Color.yellow : Color.white.opacity(0.1))
                                    .foregroundColor(searchRadius == radius ? .black : .white)
                                    .cornerRadius(15)
                            }
                        }
                    }
                    
                    // Second row: 400, 500, MAX
                    HStack(spacing: 8) {
                        ForEach([400.0, 500.0], id: \.self) { radius in
                            Button(action: { searchRadius = radius }) {
                                Text("\(Int(radius))mi")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(searchRadius == radius ? Color.yellow : Color.white.opacity(0.1))
                                    .foregroundColor(searchRadius == radius ? .black : .white)
                                    .cornerRadius(15)
                            }
                        }
                        
                        // MAX button (unlimited)
                        Button(action: { searchRadius = 99999 }) {
                            Text("MAX")
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(searchRadius >= 9999 ? Color.yellow : Color.white.opacity(0.1))
                                .foregroundColor(searchRadius >= 9999 ? .black : .white)
                                .cornerRadius(15)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 15)

                // CONTENT AREA
                if locationService.userLocation == nil {
                    // No location yet
                    VStack(spacing: 20) {
                        Spacer()
                        
                        if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
                            // Permission denied
                            Image(systemName: "location.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.red.opacity(0.5))
                            
                            Text("Location Access Denied")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Please enable location services in Settings to find nearby events")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("OPEN SETTINGS")
                                    .font(.caption.bold())
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                            }
                        } else {
                            // Loading location or not determined
                            ProgressView()
                                .tint(.yellow)
                            
                            Text("Finding your location...")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            if locationService.authorizationStatus == .notDetermined {
                                Text("Please allow location access when prompted")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            
                            Button(action: {
                                print("🔄 Requesting location permission")
                                locationService.requestLocation()
                            }) {
                                Text("ENABLE LOCATION")
                                    .font(.caption.bold())
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                            }
                        }
                        
                        Spacer()
                    }
                } else if nearbyEvents.isEmpty {
                    // Have location but no nearby events
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow.opacity(0.3))
                        
                        Text("No events found")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(searchRadius >= 9999 ? "No events in the \(timeFilter.displayName.lowercased()) timeframe" : "No events within \(Int(searchRadius)) miles in the \(timeFilter.displayName.lowercased()) timeframe")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        // Show event details for debugging
                        if !allEvents.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Events in database:")
                                    .font(.caption.bold())
                                    .foregroundColor(.yellow)
                                
                                ForEach(allEvents.prefix(3)) { event in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.title)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        if event.latitude != 0 && event.longitude != 0 {
                                            if let distance = locationService.distanceString(to: event) {
                                                Text("Distance: \(distance)")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                        } else {
                                            Text("No location data")
                                                .font(.caption2)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                        
                        VStack(spacing: 12) {
                            // EXPAND BUTTON - FIXED
                            if searchRadius < 99999 {
                                Button(action: {
                                    if searchRadius == 100 {
                                        searchRadius = 200
                                    } else if searchRadius == 200 {
                                        searchRadius = 300
                                    } else if searchRadius == 300 {
                                        searchRadius = 400
                                    } else if searchRadius == 400 {
                                        searchRadius = 500
                                    } else {
                                        searchRadius = 99999
                                    }
                                }) {
                                    let nextRadius: String = {
                                        if searchRadius == 100 { return "200" }
                                        else if searchRadius == 200 { return "300" }
                                        else if searchRadius == 300 { return "400" }
                                        else if searchRadius == 400 { return "500" }
                                        else { return "MAX" }
                                    }()
                                    
                                    Text("EXPAND TO \(nextRadius) MILES")
                                        .font(.caption.bold())
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.yellow)
                                        .cornerRadius(5)
                                }
                            }
                            
                            if timeFilter != .all {
                                Button(action: {
                                    timeFilter = .all
                                }) {
                                    Text("SHOW ALL UPCOMING")
                                        .font(.caption.bold())
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.yellow.opacity(0.7))
                                        .cornerRadius(5)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                } else {
                    // Show nearby events
                    VStack(spacing: 0) {
                        HStack {
                            Text("\(nearbyEvents.count) event\(nearbyEvents.count == 1 ? "" : "s") found")
                                .font(.caption.bold())
                                .foregroundColor(.yellow)
                            Spacer()
                            Text(timeFilter.displayName)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.05))
                        
                        List {
                            ForEach(nearbyEvents) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    HighlightedEventRow(
                                        event: event,
                                        isHighlighted: isEventThisWeek(event),
                                        locationService: locationService
                                    )
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparatorTint(.gray.opacity(0.2))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("📍 NearbyEventsView appeared")
            locationService.requestLocation()
        }
    }
}

