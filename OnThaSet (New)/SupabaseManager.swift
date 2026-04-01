//
//  SupabaseManager.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 3/26/26.
//

import Foundation
import Supabase
import SwiftUI

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
    var distanceMiles: Double
    var imageURL: String?

    enum CodingKeys: String, CodingKey {
        case id, title, date, category, details, price, latitude, longitude
        case locationName = "location_name"
        case postedByName = "posted_by_name"
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
            let url = URL(string: "\(projectURL)/rest/v1/events?order=date.asc")!
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)
            let result = try dateDecoder.decode([SupabaseEvent].self, from: data)
            self.events = result
            print("✅ Fetched \(result.count) events from Supabase")
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
        let url = URL(string: "\(projectURL)/rest/v1/events?id=eq.\(id.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        let (_, _) = try await URLSession.shared.data(for: request)
        print("✅ Event deleted from Supabase")
        await fetchAllEvents()
    }

    // MARK: - Nearby Events

    func fetchNearbyEvents(
        lat: Double,
        lng: Double,
        radiusMiles: Double = 25
    ) async throws -> [NearbyEvent] {
        let url = URL(string: "\(projectURL)/rest/v1/events?order=date.asc")!
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
            let result = try dateDecoder.decode([SupabaseAd].self, from: data)
            self.activeAds = result
            print("✅ Fetched \(result.count) active ads")
        } catch {
            print("❌ Error fetching ads: \(error)")
        }
    }

    func submitAd(_ ad: SupabaseAd) async throws {
        let url = URL(string: "\(projectURL)/rest/v1/ads")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

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
        if let address = ad.address, !address.isEmpty {
            body["address"] = address
        }
        if let imageURL = ad.imageURL, !imageURL.isEmpty {
            body["image_url"] = imageURL
        }
        if let email = ad.advertiserEmail, !email.isEmpty {
            body["advertiser_email"] = email
        }
        if let billing = ad.billingPreference {
            body["billing_preference"] = billing
        }

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
