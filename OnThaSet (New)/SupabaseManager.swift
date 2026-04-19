//
//  SupabaseManager.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 3/26/26.
//

import Foundation
import Supabase
import SwiftUI
import CoreLocation

// MARK: - Event Model for Supabase
struct SupabaseEvent: Codable, Identifiable, Equatable {
    var id: UUID?
    var title: String
    var date: Date
    var category: String
    var locationName: String
    var details: String
    var price: String
    var latitude: Double
    var longitude: Double
    var postedByUserID: String
    var postedByName: String
    var createdAt: Date?
    var imageURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case date
        case category
        case locationName = "location_name"
        case details
        case price
        case latitude
        case longitude
        case postedByUserID = "posted_by_user_id"
        case postedByName = "posted_by_name"
        case createdAt = "created_at"
        case imageURL = "image_url"
    }
}

// MARK: - Nearby Event Model
struct NearbyEvent: Codable, Identifiable {
    let id: UUID
    var title: String
    var date: Date
    var category: String
    var locationName: String
    var details: String
    var price: String
    var latitude: Double
    var longitude: Double
    var postedByName: String
    var postedByUserID: String
    var distanceMiles: Double
    var imageURL: String?

    enum CodingKeys: String, CodingKey {
        case id, title, date, category, details, price, latitude, longitude
        case locationName = "location_name"
        case postedByName = "posted_by_name"
        case postedByUserID = "posted_by_user_id"
        case distanceMiles = "distance_miles"
        case imageURL = "image_url"
    }
}

// MARK: - Ad Model for Supabase
struct SupabaseAd: Codable, Identifiable {
    var id: UUID?
    var businessName: String
    var tagline: String
    var category: String
    var phone: String?
    var websiteURL: String?
    var imageURL: String?
    var address: String?
    var status: String
    var plan: String
    var advertiserEmail: String?
    var paymentStatus: String?
    var paidUntil: Date?
    var notes: String?
    var billingPreference: String?
    var latitude: Double?
    var longitude: Double?
    var advertiserPin: String?

    enum CodingKeys: String, CodingKey {
        case id
        case businessName = "business_name"
        case tagline
        case category
        case phone
        case websiteURL = "website_url"
        case imageURL = "image_url"
        case address
        case status
        case plan
        case advertiserEmail = "advertiser_email"
        case paymentStatus = "payment_status"
        case paidUntil = "paid_until"
        case notes
        case billingPreference = "billing_preference"
        case latitude
        case longitude
        case advertiserPin = "advertiser_pin"
    }
}

// MARK: - Supabase Manager
@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
    private let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

    @Published var events: [SupabaseEvent] = []
    @Published var activeAds: [SupabaseAd] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Cutoff Date Helper
    // Returns the cutoff date — events before this are considered expired.
    // Weekdays: 24 hours after the event.
    // If today is Monday and the event was on Saturday/Sunday,
    // it stays visible until Monday 8am ET, then is removed.
    private var expiryFormatter: ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }

    private var cutoffDate: Date {
        let now = Date()
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: now) // 1=Sun, 2=Mon ... 7=Sat

        // Build 8am ET today as our reference point
        var etComponents = calendar.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: now)
        etComponents.hour = 8
        etComponents.minute = 0
        etComponents.second = 0
        let todayAt8amET = calendar.date(from: etComponents) ?? now

        // If it's before 8am ET today, use yesterday at 8am as cutoff
        let baseTime = now < todayAt8amET
            ? calendar.date(byAdding: .day, value: -1, to: todayAt8amET)!
            : todayAt8amET

        // On weekends, push cutoff back to Friday 8am so weekend events stay visible
        switch dayOfWeek {
        case 1: // Sunday — push back to Friday 8am (2 days ago)
            return calendar.date(byAdding: .day, value: -2, to: baseTime)!
        case 7: // Saturday — push back to Friday 8am (1 day ago)
            return calendar.date(byAdding: .day, value: -1, to: baseTime)!
        default: // Weekday — use 24 hours ago
            return calendar.date(byAdding: .hour, value: -24, to: now)!
        }
    }

    // MARK: - Shared Date Decoder
    private var dateDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let formatters: [DateFormatter] = [
                { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"; return f }(),
                { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"; return f }(),
                { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm:ssZ"; return f }(),
                { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"; return f }(),
                { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm:ss+00"; return f }(),
                { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f }(),
            ]

            for formatter in formatters {
                if let date = formatter.date(from: dateString) { return date }
            }

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: dateString) { return date }
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: dateString) { return date }

            print("❌ Could not decode date: \(dateString)")
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        return decoder
    }

    // MARK: - Events

    func fetchAllEvents() async {
        isLoading = true
        do {
            // Only fetch upcoming events — filter out anything before our cutoff
            let cutoff = expiryFormatter.string(from: cutoffDate)
            let url = URL(string: "\(projectURL)/rest/v1/events?date=gte.\(cutoff)&order=date.asc")!
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)
            let result = try dateDecoder.decode([SupabaseEvent].self, from: data)
            self.events = result
            print("✅ Fetched \(result.count) upcoming events from Supabase")
        } catch {
            print("❌ Error fetching events: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func postEvent(_ event: SupabaseEvent) async throws {
        let url = URL(string: "\(projectURL)/rest/v1/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        var body: [String: Any] = [
            "title": event.title,
            "date": formatter.string(from: event.date),
            "category": event.category,
            "location_name": event.locationName,
            "details": event.details,
            "price": event.price,
            "latitude": event.latitude,
            "longitude": event.longitude,
            "posted_by_user_id": event.postedByUserID,
            "posted_by_name": event.postedByName
        ]
        if let imageURL = event.imageURL {
            body["image_url"] = imageURL
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        print("🔵 HTTP Status: \(httpResponse.statusCode)")

        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            print("✅ Event posted successfully via REST")
            await fetchAllEvents()
        } else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ REST API error: \(errorMsg)")
            throw NSError(
                domain: "Supabase",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorMsg]
            )
        }
    }

    func deleteEvent(id: UUID) async throws {
        // First fetch the event to get its image URL before deleting
        let fetchURL = URL(string: "\(projectURL)/rest/v1/events?id=eq.\(id.uuidString)&select=image_url")!
        var fetchRequest = URLRequest(url: fetchURL)
        fetchRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        fetchRequest.setValue(anonKey, forHTTPHeaderField: "apikey")
        fetchRequest.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        if let (data, _) = try? await URLSession.shared.data(for: fetchRequest),
           let events = try? JSONDecoder().decode([[String: String?]].self, from: data),
           let imageURL = events.first?["image_url"] as? String,
           !imageURL.isEmpty {
            // Extract filename from URL and delete from storage
            await deleteStorageFile(imageURL: imageURL, bucket: "event-flyers")
        }

        // Now delete the event row
        let url = URL(string: "\(projectURL)/rest/v1/events?id=eq.\(id.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        let (_, _) = try await URLSession.shared.data(for: request)
        print("✅ Event and flyer deleted from Supabase")
        await fetchAllEvents()
    }

    func saveEventPhotoMetadata(
        userID: String,
        eventName: String,
        eventDate: Date,
        location: String,
        caption: String,
        photoURL: String
    ) async {
        guard let url = URL(string: "\(projectURL)/rest/v1/event_photos") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let body: [String: Any] = [
            "uploaded_by": userID,
            "event_name": eventName,
            "event_date": formatter.string(from: eventDate),
            "location": location,
            "caption": caption,
            "image_url": photoURL
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        if let (data, response) = try? await URLSession.shared.data(for: request),
           let http = response as? HTTPURLResponse {
            if http.statusCode == 201 {
                print("✅ Event photo metadata saved")
            } else {
                let errorMsg = String(data: data, encoding: .utf8) ?? "unknown"
                print("❌ Event photo metadata FAILED (\(http.statusCode)): \(errorMsg)")
            }
        }
    }

    func saveBikeBuildMetadata(
        userID: String,
        modificationTitle: String,
        note: String,
        beforeImageURL: String,
        afterImageURL: String,
        bikeMake: String,
        bikeModel: String,
        bikeYear: String
    ) async {
        guard let url = URL(string: "\(projectURL)/rest/v1/bike_builds") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = [
            "user_id": userID,
            "modification_title": modificationTitle,
            "note": note,
            "before_image_url": beforeImageURL,
            "after_image_url": afterImageURL,
            "bike_make": bikeMake,
            "bike_model": bikeModel,
            "bike_year": bikeYear
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        if let (_, response) = try? await URLSession.shared.data(for: request),
           let http = response as? HTTPURLResponse {
            print(http.statusCode == 201 ? "✅ Bike build metadata saved" : "⚠️ Bike build metadata status: \(http.statusCode)")
        }
    }

    func deleteEventByTitleAndUser(title: String, userID: String) async {
        guard let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let fetchURL = URL(string: "\(projectURL)/rest/v1/events?title=eq.\(encodedTitle)&posted_by_user_id=eq.\(userID)&select=image_url") else { return }

        // First fetch the image URL so we can delete from storage
        var fetchRequest = URLRequest(url: fetchURL)
        fetchRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        fetchRequest.setValue(anonKey, forHTTPHeaderField: "apikey")
        fetchRequest.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        if let (data, _) = try? await URLSession.shared.data(for: fetchRequest),
           let events = try? JSONDecoder().decode([[String: String?]].self, from: data),
           let imageURL = events.first?["image_url"] as? String,
           !imageURL.isEmpty {
            await deleteStorageFile(imageURL: imageURL, bucket: "event-flyers")
        }

        // Now delete the event row
        guard let deleteURL = URL(string: "\(projectURL)/rest/v1/events?title=eq.\(encodedTitle)&posted_by_user_id=eq.\(userID)") else { return }
        var request = URLRequest(url: deleteURL)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        if let (_, response) = try? await URLSession.shared.data(for: request),
           let http = response as? HTTPURLResponse {
            print(http.statusCode == 200 || http.statusCode == 204 ? "✅ Event deleted from Supabase" : "⚠️ Event delete status: \(http.statusCode)")
        }
    }

    func deleteEventPhotoRecord(imageURL: String, userID: String) async {
        guard let url = URL(string: "\(projectURL)/rest/v1/event_photos?image_url=eq.\(imageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? imageURL)&uploaded_by=eq.\(userID)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        if let (_, response) = try? await URLSession.shared.data(for: request),
           let http = response as? HTTPURLResponse {
            print(http.statusCode == 200 || http.statusCode == 204 ? "✅ Event photo record deleted" : "⚠️ Event photo record delete status: \(http.statusCode)")
        }
    }

    func deleteBikeBuildRecord(afterImageURL: String, userID: String) async {
        guard let url = URL(string: "\(projectURL)/rest/v1/bike_builds?after_image_url=eq.\(afterImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? afterImageURL)&user_id=eq.\(userID)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        if let (_, response) = try? await URLSession.shared.data(for: request),
           let http = response as? HTTPURLResponse {
            print(http.statusCode == 200 || http.statusCode == 204 ? "✅ Bike build record deleted" : "⚠️ Bike build record delete status: \(http.statusCode)")
        }
    }

    func deleteStorageFile(imageURL: String, bucket: String) async {
        guard !imageURL.isEmpty else { return }
        // Extract just the filename from the full Supabase URL
        guard let fileName = imageURL.components(separatedBy: "/\(bucket)/").last,
              !fileName.isEmpty else { return }

        let deleteURL = URL(string: "\(projectURL)/storage/v1/object/\(bucket)/\(fileName)")!
        var request = URLRequest(url: deleteURL)
        request.httpMethod = "DELETE"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        if let (_, response) = try? await URLSession.shared.data(for: request),
           let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                print("✅ Deleted storage file: \(fileName)")
            } else {
                print("⚠️ Storage delete returned: \(httpResponse.statusCode) for \(fileName)")
            }
        }
    }

    // MARK: - Nearby Events

    func fetchNearbyEvents(
        lat: Double,
        lng: Double,
        radiusMiles: Double = 25
    ) async throws -> [NearbyEvent] {
        // Same cutoff filter applied to nearby events
        let cutoff = expiryFormatter.string(from: cutoffDate)
        let url = URL(string: "\(projectURL)/rest/v1/events?date=gte.\(cutoff)&order=date.asc")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "Supabase", code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
        }

        let allEvents = try dateDecoder.decode([SupabaseEvent].self, from: data)
        print("✅ Decoded \(allEvents.count) total events")

        let userLat = lat * .pi / 180
        let userLng = lng * .pi / 180

        let nearby = allEvents.compactMap { event -> NearbyEvent? in
            guard event.latitude != 0 && event.longitude != 0 else { return nil }

            let eventLat = event.latitude * .pi / 180
            let eventLng = event.longitude * .pi / 180

            let dlat = eventLat - userLat
            let dlng = eventLng - userLng
            let a = sin(dlat/2) * sin(dlat/2) +
                    cos(userLat) * cos(eventLat) *
                    sin(dlng/2) * sin(dlng/2)
            let c = 2 * atan2(sqrt(a), sqrt(1-a))
            let distanceMiles = 3958.8 * c

            guard distanceMiles <= radiusMiles else { return nil }

            return NearbyEvent(
                id: event.id ?? UUID(),
                title: event.title,
                date: event.date,
                category: event.category,
                locationName: event.locationName,
                details: event.details,
                price: event.price,
                latitude: event.latitude,
                longitude: event.longitude,
                postedByName: event.postedByName,
                postedByUserID: event.postedByUserID,
                distanceMiles: distanceMiles,
                imageURL: event.imageURL
            )
        }
        .sorted { $0.distanceMiles < $1.distanceMiles }

        print("✅ Found \(nearby.count) nearby events within \(radiusMiles) miles")
        return nearby
    }

    // MARK: - Ads

    func fetchActiveAds() async {
        do {
            let url = URL(string: "\(projectURL)/rest/v1/ads?status=eq.active")!
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)
            let allAds = try dateDecoder.decode([SupabaseAd].self, from: data)

            // Filter to ads within 100 miles of user — or show all if no location
            let userLocation = LocationManager.shared.userLocation
            if let userLoc = userLocation {
                let filtered = allAds.filter { ad in
                    // If ad has no coordinates, show it anyway (no address entered)
                    guard let adLat = ad.latitude, let adLng = ad.longitude,
                          adLat != 0, adLng != 0 else { return true }
                    let distanceMiles = haversineDistance(
                        lat1: userLoc.coordinate.latitude, lng1: userLoc.coordinate.longitude,
                        lat2: adLat, lng2: adLng
                    )
                    return distanceMiles <= 100.0
                }
                self.activeAds = filtered
                print("✅ Fetched \(filtered.count) active ads within 100 miles (of \(allAds.count) total)")
            } else {
                // No location available — show all ads
                self.activeAds = allAds
                print("✅ Fetched \(allAds.count) active ads (no location filter)")
            }
        } catch {
            print("❌ Error fetching ads: \(error)")
        }
    }

    private func haversineDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double {
        let r = 3958.8 // Earth radius in miles
        let dLat = (lat2 - lat1) * .pi / 180
        let dLng = (lng2 - lng1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLng/2) * sin(dLng/2)
        return r * 2 * atan2(sqrt(a), sqrt(1-a))
    }

    func submitAd(_ ad: SupabaseAd) async throws {
        let url = URL(string: "\(projectURL)/rest/v1/ads")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        // Geocode using full address (even if street is hidden from display)
        // When hide_address is set, the full geocode address is stored in notes as "geocode:..."
        var geocodeString = ad.address ?? ""
        if let notes = ad.notes, let geocodeRange = notes.range(of: "geocode:") {
            var extracted = String(notes[geocodeRange.upperBound...])
            // Strip any trailing flags that follow
            for suffix in [",appointment_only", ",hide_address"] {
                if let r = extracted.range(of: suffix) { extracted = String(extracted[..<r.lowerBound]) }
            }
            if !extracted.isEmpty { geocodeString = extracted }
        }

        var adLatitude: Double? = nil
        var adLongitude: Double? = nil
        if !geocodeString.isEmpty {
            if let coords = await geocodeAddress(geocodeString) {
                adLatitude = coords.0
                adLongitude = coords.1
                print("✅ Geocoded ad address: \(coords.0), \(coords.1)")
            }
        }

        var body: [String: Any] = [
            "business_name": ad.businessName,
            "tagline": ad.tagline,
            "category": ad.category,
            "phone": ad.phone ?? "",
            "website_url": ad.websiteURL ?? "",
            "status": "pending",
            "plan": ad.plan,
            "payment_status": "unpaid"
        ]
        if let address = ad.address, !address.isEmpty { body["address"] = address }
        if let imageURL = ad.imageURL, !imageURL.isEmpty { body["image_url"] = imageURL }
        if let email = ad.advertiserEmail, !email.isEmpty { body["advertiser_email"] = email }
        if let billing = ad.billingPreference { body["billing_preference"] = billing }
        if let pin = ad.advertiserPin, !pin.isEmpty { body["advertiser_pin"] = pin }
        if let lat = adLatitude { body["latitude"] = lat }
        if let lng = adLongitude { body["longitude"] = lng }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            print("✅ Ad submitted successfully")
        } else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "Supabase", code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }

    private func geocodeAddress(_ address: String) async -> (Double, Double)? {
        await withCheckedContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let location = placemarks?.first?.location {
                    continuation.resume(returning: (location.coordinate.latitude, location.coordinate.longitude))
                } else {
                    print("⚠️ Could not geocode address: \(address) — \(error?.localizedDescription ?? "unknown")")
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // MARK: - Image Upload

    func uploadImage(
        data: Data,
        bucket: String,
        fileName: String
    ) async throws -> String {
        let url = URL(string: "\(projectURL)/storage/v1/object/\(bucket)/\(fileName)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "x-upsert") // Allow overwrite
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        print("🔵 Image upload status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMsg = String(data: responseData, encoding: .utf8) ?? "Upload failed"
            throw NSError(domain: "Storage", code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        let publicURL = "\(projectURL)/storage/v1/object/public/\(bucket)/\(fileName)"
        print("✅ Image uploaded: \(publicURL)")
        return publicURL
    }
}
