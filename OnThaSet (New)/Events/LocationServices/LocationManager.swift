//
//  LocationManager.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/7/25.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // SINGLETON PATTERN - Share location across entire app
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Set initial status
        authorizationStatus = manager.authorizationStatus
        print("📍 LocationManager initialized with status: \(manager.authorizationStatus.rawValue)")
    }
    
    func requestLocation() {
        let currentStatus = manager.authorizationStatus
        
        print("📍 requestLocation() called - Current status: \(currentStatus.rawValue)")
        
        switch currentStatus {
        case .notDetermined:
            // Request permission first
            print("📍 Requesting authorization...")
            manager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Already authorized, get location
            print("📍 Already authorized, requesting location...")
            manager.requestLocation()
            
        case .denied:
            print("❌ Location access denied - User needs to enable in Settings")
            
        case .restricted:
            print("❌ Location access restricted")
            
        @unknown default:
            print("⚠️ Unknown authorization status")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
        if let location = locations.last {
            print("✅ Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        authorizationStatus = newStatus
        
        print("📍 Authorization changed to: \(newStatus.rawValue)")
        
        switch newStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Authorization granted! Requesting location...")
            manager.requestLocation()
            
        case .denied:
            print("❌ Location permission denied by user")
            
        case .notDetermined:
            print("⏳ Waiting for user decision...")
            
        case .restricted:
            print("❌ Location services restricted")
            
        @unknown default:
            print("⚠️ Unknown authorization status")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
        
        // More detailed error info
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("❌ User denied location permission")
            case .locationUnknown:
                print("⚠️ Location currently unknown, will keep trying")
            default:
                print("❌ CLError: \(clError.code.rawValue)")
            }
        }
    }
    
    // Check if an event is within a certain radius
    func isNearby(event: Event, radiusInMiles: Double = 50) -> Bool {
        // If we don't have user location, don't show the event
        guard let userLoc = userLocation else {
            print("⚠️ No user location available for isNearby check")
            return false
        }
        
        // If event doesn't have coordinates, don't show it
        guard event.latitude != 0.0 && event.longitude != 0.0 else {
            print("⚠️ Event '\(event.title)' has no coordinates")
            return false
        }
        
        let eventLoc = CLLocation(latitude: event.latitude, longitude: event.longitude)
        let distanceInMeters = userLoc.distance(from: eventLoc)
        
        // Convert meters to miles
        let distanceInMiles = distanceInMeters / 1609.34
        
        print("📏 Event '\(event.title)' is \(String(format: "%.1f", distanceInMiles)) miles away")
        
        return distanceInMiles <= radiusInMiles
    }
    
    // Format distance for display
    func distanceString(to event: Event) -> String? {
        guard let userLoc = userLocation,
              event.latitude != 0.0 && event.longitude != 0.0 else {
            return nil
        }
        
        let eventLoc = CLLocation(latitude: event.latitude, longitude: event.longitude)
        let distanceInMeters = userLoc.distance(from: eventLoc)
        let distanceInMiles = distanceInMeters / 1609.34
        
        if distanceInMiles < 1 {
            return String(format: "%.1f mi", distanceInMiles)
        } else {
            return String(format: "%.0f mi", distanceInMiles)
        }
    }
}
