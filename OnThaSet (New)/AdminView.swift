//
//  AdminView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 3/29/26.
//

import SwiftUI

// MARK: - Stripe Payment Links
struct StripeLinks {
    static let basicRecurring    = "https://buy.stripe.com/7sYaEW97Z2ur5YQ6oHdUY01"
    static let basicOneTime      = "https://buy.stripe.com/6oUeVcckb2uraf6cN5dUY02"
    static let featuredRecurring = "https://buy.stripe.com/aFa8wO4RJglhcne8wPdUY04"
    static let featuredOneTime   = "https://buy.stripe.com/dRm00i3NF3yvfzq8wPdUY03"
    static let premiumRecurring  = "https://buy.stripe.com/6oU6oGckbfhd9b2cN5dUY06"
    static let premiumOneTime    = "https://buy.stripe.com/cNieVcfwnc51af68wPdUY05"
}

// MARK: - Admin Lock Screen

struct AdminLockView: View {
    @Environment(\.dismiss) var dismiss
    @State private var enteredPIN = ""
    @State private var showingAdmin = false
    @State private var shake = false
    @State private var showError = false

    private let correctPIN = "012230"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    ZStack {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.yellow)
                        VStack(spacing: -2) {
                            Text("ON").font(.system(size: 13, weight: .black))
                            Text("THA").font(.system(size: 10, weight: .black))
                            Text("SET").font(.system(size: 16, weight: .black))
                        }
                        .foregroundColor(.black).offset(y: -3)
                    }

                    Text("ADMIN ACCESS")
                        .font(.title2.bold()).foregroundColor(.yellow)

                    Text("Enter your admin PIN")
                        .font(.subheadline).foregroundColor(.gray)

                    // PIN DOTS
                    HStack(spacing: 20) {
                        ForEach(0..<6, id: \.self) { i in
                            Circle()
                                .fill(i < enteredPIN.count ? Color.yellow : Color.white.opacity(0.2))
                                .frame(width: 16, height: 16)
                        }
                    }
                    .offset(x: shake ? -10 : 0)
                    .animation(shake ? .easeInOut(duration: 0.1).repeatCount(5) : .default, value: shake)

                    if showError {
                        Text("Incorrect PIN")
                            .font(.caption.bold()).foregroundColor(.red)
                    }

                    // NUMBER PAD
                    VStack(spacing: 15) {
                        ForEach([[1,2,3],[4,5,6],[7,8,9]], id: \.self) { row in
                            HStack(spacing: 25) {
                                ForEach(row, id: \.self) { num in
                                    pinButton(label: "\(num)") { addDigit("\(num)") }
                                }
                            }
                        }
                        HStack(spacing: 25) {
                            pinButton(label: "⌫", color: .red.opacity(0.7)) {
                                if !enteredPIN.isEmpty {
                                    enteredPIN.removeLast()
                                    showError = false
                                }
                            }
                            pinButton(label: "0") { addDigit("0") }
                            pinButton(label: "✓", color: .green.opacity(0.7)) { checkPIN() }
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.yellow)
                }
            }
            .navigationDestination(isPresented: $showingAdmin) {
                AdminDashboardView()
            }
        }
    }

    private func addDigit(_ digit: String) {
        guard enteredPIN.count < 6 else { return }
        enteredPIN += digit
        showError = false
        if enteredPIN.count == 6 { checkPIN() }
    }

    private func checkPIN() {
        if enteredPIN == correctPIN {
            showingAdmin = true
            enteredPIN = ""
        } else {
            shake = true
            showError = true
            enteredPIN = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { shake = false }
        }
    }

    private func pinButton(label: String, color: Color = Color.white.opacity(0.15), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.title2.bold()).foregroundColor(.white)
                .frame(width: 75, height: 75)
                .background(color).clipShape(Circle())
        }
    }
}

// MARK: - Admin Dashboard

struct AdminDashboardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var pendingAds: [SupabaseAd] = []
    @State private var activeAds: [SupabaseAd] = []
    @State private var deactivatedAds: [SupabaseAd] = []
    @State private var expiredAds: [SupabaseAd] = []
    @State private var allEvents: [SupabaseEvent] = []
    @State private var pendingReports: [AdminEventReport] = []
    @State private var isLoading = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // HEADER
                HStack {
                    ZStack {
                        Image(systemName: "shield.fill").font(.system(size: 45)).foregroundColor(.yellow)
                        VStack(spacing: -1) {
                            Text("ON").font(.system(size: 7, weight: .black))
                            Text("THA").font(.system(size: 6, weight: .black))
                            Text("SET").font(.system(size: 9, weight: .black))
                        }.foregroundColor(.black).offset(y: -2)
                    }
                    Text("ADMIN").font(.title2.bold()).foregroundColor(.yellow)
                    Spacer()
                    Button(action: { Task { await loadAll() } }) {
                        Image(systemName: "arrow.clockwise").foregroundColor(.yellow)
                    }
                }
                .padding()

                // STATS BAR
                HStack(spacing: 0) {
                    statCell(count: pendingAds.count, label: "PENDING", color: .orange)
                    statCell(count: activeAds.count, label: "ACTIVE ADS", color: .green)
                    statCell(count: allEvents.count, label: "EVENTS", color: .yellow)
                    statCell(count: pendingReports.count, label: "REPORTS", color: .red)
                    statCell(count: expiredAds.count, label: "EXPIRED", color: .gray)
                }
                .background(Color.white.opacity(0.05))

                // TAB SELECTOR
                Picker("", selection: $selectedTab) {
                    Text("Pending (\(pendingAds.count))").tag(0)
                    Text("Active Ads").tag(1)
                    Text("Events").tag(2)
                    Text("Reports (\(pendingReports.count))").tag(3)
                    Text("Paused (\(deactivatedAds.count))").tag(4)
                    Text("Expired (\(expiredAds.count))").tag(5)
                }
                .pickerStyle(.segmented)
                .padding()

                // CONTENT
                if isLoading {
                    Spacer()
                    ProgressView().tint(.yellow)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if selectedTab == 0 {
                                if pendingAds.isEmpty {
                                    emptyState(message: "No pending ads", icon: "checkmark.circle")
                                } else {
                                    ForEach(pendingAds) { ad in
                                        AdminAdCard(
                                            ad: ad,
                                            onApprove: { Task { await approveAd(ad) } },
                                            onReject: { Task { await rejectAd(ad) } },
                                            onDelete: { Task { await deleteAd(ad) } },
                                            onRefresh: { Task { await loadAll() } }
                                        )
                                    }
                                }
                            } else if selectedTab == 1 {
                                if activeAds.isEmpty {
                                    emptyState(message: "No active ads", icon: "megaphone")
                                } else {
                                    ForEach(activeAds) { ad in
                                        AdminAdCard(
                                            ad: ad,
                                            onApprove: nil,
                                            onReject: { Task { await rejectAd(ad) } },
                                            onDelete: { Task { await deleteAd(ad) } },
                                            onRefresh: { Task { await loadAll() } }
                                        )
                                    }
                                }
                            } else if selectedTab == 2 {
                                if allEvents.isEmpty {
                                    emptyState(message: "No events", icon: "calendar")
                                } else {
                                    ForEach(allEvents) { event in
                                        AdminEventCard(event: event, onDelete: {
                                            Task { await deleteEvent(event) }
                                        })
                                    }
                                }
                            } else if selectedTab == 3 {
                                if pendingReports.isEmpty {
                                    emptyState(message: "No reports", icon: "flag.slash")
                                } else {
                                    ForEach(pendingReports) { report in
                                        AdminReportCard(report: report, onDismiss: {
                                            Task { await dismissReport(report) }
                                        }, onDeleteEvent: {
                                            Task { await deleteReportedEvent(report) }
                                        })
                                    }
                                }
                            } else if selectedTab == 4 {
                                if deactivatedAds.isEmpty {
                                    emptyState(message: "No paused ads", icon: "pause.circle")
                                } else {
                                    ForEach(deactivatedAds) { ad in
                                        AdminAdCard(
                                            ad: ad,
                                            onApprove: { Task { await approveAd(ad) } },
                                            onReject: nil,
                                            onDelete: { Task { await deleteAd(ad) } },
                                            onRefresh: { Task { await loadAll() } }
                                        )
                                    }
                                }
                            } else if selectedTab == 5 {
                                if expiredAds.isEmpty {
                                    emptyState(message: "No expired ads", icon: "clock.badge.xmark")
                                } else {
                                    ForEach(expiredAds) { ad in
                                        AdminAdCard(
                                            ad: ad,
                                            onApprove: { Task { await approveAd(ad) } },
                                            onReject: { Task { await rejectAd(ad) } },
                                            onDelete: { Task { await deleteAd(ad) } },
                                            onRefresh: { Task { await loadAll() } }
                                        )
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
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
                Text("ADMIN DASHBOARD").font(.caption.bold()).foregroundColor(.yellow)
            }
        }
        .task { await loadAll() }
    }

    private func statCell(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)").font(.title2.bold()).foregroundColor(color)
            Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
    }

    private func emptyState(message: String, icon: String) -> some View {
        VStack(spacing: 15) {
            Image(systemName: icon).font(.system(size: 40)).foregroundColor(.yellow.opacity(0.3))
            Text(message).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
    }

    private func loadAll() async {
        isLoading = true
        await loadAds()
        await loadEvents()
        await loadReports()
        isLoading = false
    }

    private func loadAds() async {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

        guard let url = URL(string: "\(projectURL)/rest/v1/ads?order=created_at.desc") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return }

        // Use a date-aware decoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: str) { return date }
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: str) { return date }
            // Try yyyy-MM-dd format for paidUntil dates stored as date-only
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            if let date = df.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(str)")
        }

        guard var ads = try? decoder.decode([SupabaseAd].self, from: data) else { return }

        let now = Date()

        // Auto-expire any active ads whose paidUntil date has passed
        for i in ads.indices {
            if ads[i].status == "active",
               let paidUntil = ads[i].paidUntil,
               paidUntil < now {
                ads[i].status = "expired"
                // Update status in Supabase so it stays expired
                await expireAd(id: ads[i].id, anonKey: anonKey, projectURL: projectURL)
            }
        }

        pendingAds      = ads.filter { $0.status == "pending" }
        activeAds       = ads.filter { $0.status == "active" }
        deactivatedAds  = ads.filter { $0.status == "rejected" || $0.status == "inactive" }
        expiredAds      = ads.filter { $0.status == "expired" }
    }

    private func expireAd(id: UUID?, anonKey: String, projectURL: String) async {
        guard let id = id,
              let url = URL(string: "\(projectURL)/rest/v1/ads?id=eq.\(id.uuidString)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["status": "expired"])
        _ = try? await URLSession.shared.data(for: request)
        print("✅ Ad \(id) auto-expired")
    }

    private func loadEvents() async {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

        // First — fetch expired events to get their image URLs before deleting
        let deleteFormatter = ISO8601DateFormatter()
        deleteFormatter.formatOptions = [.withInternetDateTime]
        let cutoff = deleteFormatter.string(from: Date().addingTimeInterval(-24 * 60 * 60))

        if let fetchURL = URL(string: "\(projectURL)/rest/v1/events?date=lt.\(cutoff)&select=id,image_url") {
            var fetchRequest = URLRequest(url: fetchURL)
            fetchRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            fetchRequest.setValue(anonKey, forHTTPHeaderField: "apikey")
            fetchRequest.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

            if let (data, _) = try? await URLSession.shared.data(for: fetchRequest) {
                struct ExpiredEvent: Codable {
                    let imageURL: String?
                    enum CodingKeys: String, CodingKey { case imageURL = "image_url" }
                }
                if let expired = try? JSONDecoder().decode([ExpiredEvent].self, from: data) {
                    // Delete each flyer from storage
                    for event in expired {
                        if let url = event.imageURL, !url.isEmpty {
                            await SupabaseManager.shared.deleteStorageFile(imageURL: url, bucket: "event-flyers")
                        }
                    }
                    print("✅ Cleaned up \(expired.count) event flyers from storage")
                }
            }
        }

        // Now delete the expired event rows
        if let deleteURL = URL(string: "\(projectURL)/rest/v1/events?date=lt.\(cutoff)") {
            var deleteRequest = URLRequest(url: deleteURL)
            deleteRequest.httpMethod = "DELETE"
            deleteRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            deleteRequest.setValue(anonKey, forHTTPHeaderField: "apikey")
            deleteRequest.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: deleteRequest)
            print("✅ Deleted expired events from Supabase")
        }

        // Then fetch only upcoming events
        let fetchFormatter = ISO8601DateFormatter()
        fetchFormatter.formatOptions = [.withInternetDateTime]
        let now = fetchFormatter.string(from: Date())

        guard let url = URL(string: "\(projectURL)/rest/v1/events?date=gte.\(now)&order=date.asc") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: str) { return date }
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(str)")
        }

        if let (data, _) = try? await URLSession.shared.data(for: request),
           let events = try? decoder.decode([SupabaseEvent].self, from: data) {
            allEvents = events
        }
    }

    private func updateAdStatus(_ ad: SupabaseAd, status: String) async {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

        guard let id = ad.id,
              let url = URL(string: "\(projectURL)/rest/v1/ads?id=eq.\(id.uuidString)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["status": status])
        _ = try? await URLSession.shared.data(for: request)
        await loadAds()
        await SupabaseManager.shared.fetchActiveAds()
    }

    private func approveAd(_ ad: SupabaseAd) async {
        await updateAdStatus(ad, status: "active")
    }

    private func rejectAd(_ ad: SupabaseAd) async {
        await updateAdStatus(ad, status: "rejected")
    }

    private func deleteAd(_ ad: SupabaseAd) async {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

        guard let id = ad.id else { return }

        // Delete banner image from storage
        if let imageURL = ad.imageURL, !imageURL.isEmpty {
            await SupabaseManager.shared.deleteStorageFile(imageURL: imageURL, bucket: "ad-banners")
        }

        // Delete the ad row from Supabase
        guard let url = URL(string: "\(projectURL)/rest/v1/ads?id=eq.\(id.uuidString)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        if let (_, response) = try? await URLSession.shared.data(for: request),
           let http = response as? HTTPURLResponse {
            print(http.statusCode == 200 || http.statusCode == 204 ? "✅ Ad deleted from Supabase" : "⚠️ Ad delete status: \(http.statusCode)")
        }
        await loadAds()
        await SupabaseManager.shared.fetchActiveAds()
    }

    private func deleteEvent(_ event: SupabaseEvent) async {
        guard let id = event.id else { return }
        try? await SupabaseManager.shared.deleteEvent(id: id)
        await loadEvents()
    }

    // MARK: - Reports

    private func loadReports() async {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

        guard let url = URL(string: "\(projectURL)/rest/v1/event_reports?status=eq.pending&order=created_at.desc") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        if let (data, _) = try? await URLSession.shared.data(for: request),
           let reports = try? JSONDecoder().decode([AdminEventReport].self, from: data) {
            pendingReports = reports
        }
    }

    private func dismissReport(_ report: AdminEventReport) async {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

        guard let url = URL(string: "\(projectURL)/rest/v1/event_reports?id=eq.\(report.id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["status": "dismissed"])

        _ = try? await URLSession.shared.data(for: request)
        await loadReports()
    }

    private func deleteReportedEvent(_ report: AdminEventReport) async {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

        // Delete the event from Supabase
        if let url = URL(string: "\(projectURL)/rest/v1/events?id=eq.\(report.eventID)") {
            var req = URLRequest(url: url)
            req.httpMethod = "DELETE"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(anonKey, forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: req)
        }

        // Mark the report as resolved
        if let url = URL(string: "\(projectURL)/rest/v1/event_reports?id=eq.\(report.id)") {
            var req = URLRequest(url: url)
            req.httpMethod = "PATCH"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(anonKey, forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
            req.httpBody = try? JSONSerialization.data(withJSONObject: ["status": "resolved"])
            _ = try? await URLSession.shared.data(for: req)
        }

        await loadReports()
        await loadEvents()
    }
}

// MARK: - AdminEventReport Model

struct AdminEventReport: Codable, Identifiable {
    var id: String
    var eventID: String
    var eventTitle: String
    var reportedByUserID: String
    var reason: String
    var additionalNotes: String
    var status: String
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case eventID           = "event_id"
        case eventTitle        = "event_title"
        case reportedByUserID  = "reported_by_user_id"
        case reason
        case additionalNotes   = "additional_notes"
        case status
        case createdAt         = "created_at"
    }
}

// MARK: - Admin Report Card

struct AdminReportCard: View {
    let report: AdminEventReport
    let onDismiss: () -> Void
    let onDeleteEvent: () -> Void

    @State private var showingDeleteConfirm = false
    @State private var reportedEvent: SupabaseEvent? = nil
    @State private var posterEmail: String = ""

    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
    private let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow
            reporterRow
            notesSection
            if let event = reportedEvent { eventPreviewCard(event) }
            Divider().background(Color.white.opacity(0.1))
            actionButtons
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.3), lineWidth: 1))
        .alert("Delete This Event?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDeleteEvent() }
        } message: {
            Text("This will permanently remove \"" + report.eventTitle + "\" and mark the report as resolved.")
        }
        .task { await fetchReportedEvent() }
    }

    private func eventPreviewCard(_ event: SupabaseEvent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("REPORTED EVENT").font(.system(size: 9, weight: .bold)).foregroundColor(.yellow)
                Spacer()
                Text(event.category.replacingOccurrences(of: "_", with: " ").uppercased())
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.gray)
            }
            if let imageURL = event.imageURL, !imageURL.isEmpty, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                            .frame(maxWidth: .infinity).frame(height: 120)
                            .clipped().cornerRadius(8)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title).font(.subheadline.bold()).foregroundColor(.white)
                Text(event.locationName).font(.caption).foregroundColor(.gray)
                if !event.details.isEmpty {
                    Text(event.details).font(.caption).foregroundColor(.white.opacity(0.7)).lineLimit(3)
                }
                Text("Posted by: \(event.postedByName)").font(.caption.bold()).foregroundColor(.orange)
            }

            // View full event button
            NavigationLink(destination: SupabaseEventDetailView(event: event)) {
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill").font(.caption)
                    Text("VIEW FULL EVENT").font(.caption.bold())
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption2)
                }
                .padding(10)
                .background(Color.yellow.opacity(0.15))
                .foregroundColor(.yellow)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow.opacity(0.4), lineWidth: 1))
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yellow.opacity(0.2), lineWidth: 1))
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(Color.red.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: "flag.fill").font(.title3).foregroundColor(.red)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(report.eventTitle).font(.subheadline.bold()).foregroundColor(.white).lineLimit(2)
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill").font(.caption2).foregroundColor(.orange)
                    Text(report.reason).font(.caption.bold()).foregroundColor(.orange)
                }
            }
            Spacer()
            if let created = report.createdAt {
                Text(shortDate(created)).font(.caption2).foregroundColor(.gray)
            }
        }
    }

    private var reporterRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.circle").font(.caption).foregroundColor(.gray)
            Text("Reporter: " + report.reportedByUserID.prefix(12) + "...").font(.caption).foregroundColor(.gray)
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        if !report.additionalNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("NOTES").font(.system(size: 9, weight: .bold)).foregroundColor(.gray)
                Text(report.additionalNotes).font(.caption).foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10).background(Color.white.opacity(0.05)).cornerRadius(8)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            if !posterEmail.isEmpty && posterEmail != "no-email@placeholder.com" {
                Button(action: contactPoster) {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill").font(.subheadline)
                        Text("CONTACT POSTER").font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(Color.blue.opacity(0.7)).foregroundColor(.white).cornerRadius(8)
                }
            }
            HStack(spacing: 10) {
                Button(action: onDismiss) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle").font(.subheadline)
                        Text("DISMISS").font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(Color.white.opacity(0.1)).foregroundColor(.white).cornerRadius(8)
                }
                Button(action: { showingDeleteConfirm = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill").font(.subheadline)
                        Text("DELETE EVENT").font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(Color.red.opacity(0.8)).foregroundColor(.white).cornerRadius(8)
                }
            }
        }
    }

    private func fetchReportedEvent() async {
        guard !report.eventID.isEmpty,
              let url = URL(string: "\(projectURL)/rest/v1/events?id=eq.\(report.eventID)&limit=1") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            let rawString = String(data: data, encoding: .utf8) ?? "nil"
            print("📦 Admin report event response: \(rawString)")
            // Use plain decoder — SupabaseEvent has explicit CodingKeys
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let str = try container.decode(String.self)
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = iso.date(from: str) { return date }
                iso.formatOptions = [.withInternetDateTime]
                if let date = iso.date(from: str) { return date }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(str)")
            }
            if let events = try? decoder.decode([SupabaseEvent].self, from: data),
               let event = events.first {
                await MainActor.run { reportedEvent = event }
                await fetchPosterEmail(appleUserID: event.postedByUserID)
                print("✅ Loaded reported event: \(event.title)")
            } else {
                print("❌ Could not decode reported event")
            }
        }
    }

    private func fetchPosterEmail(appleUserID: String) async {
        guard !appleUserID.isEmpty,
              let url = URL(string: "\(projectURL)/rest/v1/users?apple_user_id=eq.\(appleUserID)&select=email&limit=1") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        struct UserEmail: Codable { var email: String }
        if let (data, _) = try? await URLSession.shared.data(for: request),
           let users = try? JSONDecoder().decode([UserEmail].self, from: data),
           let user = users.first {
            await MainActor.run { posterEmail = user.email }
        }
    }

    private func contactPoster() {
        let subject = "Regarding your event: \(report.eventTitle)"
        let body = "Hi,\n\nYour event \"\(report.eventTitle)\" has been reported for: \(report.reason).\n\nNotes: \(report.additionalNotes)\n\nPlease respond to verify or clarify this report.\n\nOn Tha Set Admin"
        let encoded = "mailto:\(posterEmail)?subject=\(subject)&body=\(body)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: encoded) { UIApplication.shared.open(url) }
    }

    private func shortDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: iso) {
            let display = DateFormatter()
            display.dateStyle = .short
            return display.string(from: date)
        }
        return ""
    }
}

// MARK: - Admin Ad Card

struct AdminAdCard: View {
    let ad: SupabaseAd
    let onApprove: (() -> Void)?
    let onReject: (() -> Void)?
    let onDelete: (() -> Void)?
    let onRefresh: (() -> Void)?

    @State private var paymentStatus: String = "unpaid"
    @State private var paidUntil: Date = Date()
    @State private var showingDatePicker = false
    @State private var notes: String = ""
    @State private var showingNotes = false
    @State private var isSavingPayment = false

    var statusColor: Color {
        switch ad.status {
        case "active": return .green
        case "rejected": return .red
        default: return .orange
        }
    }

    var planColor: Color {
        switch ad.plan {
        case "premium": return .yellow
        case "featured": return .orange
        default: return .gray
        }
    }

    var planBadge: String {
        switch ad.plan {
        case "premium": return "👑 PREMIUM"
        case "featured": return "⭐ FEATURED"
        default: return "BASIC"
        }
    }

    var planPrice: String {
        switch ad.plan {
        case "premium": return "$49.99"
        case "featured": return "$29.99"
        default: return "$19.99"
        }
    }

    var recurringLink: String {
        switch ad.plan {
        case "premium": return StripeLinks.premiumRecurring
        case "featured": return StripeLinks.featuredRecurring
        default: return StripeLinks.basicRecurring
        }
    }

    var oneTimeLink: String {
        switch ad.plan {
        case "premium": return StripeLinks.premiumOneTime
        case "featured": return StripeLinks.featuredOneTime
        default: return StripeLinks.basicOneTime
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // HEADER ROW
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ad.businessName)
                        .font(.headline.bold()).foregroundColor(.white)
                    Text(ad.tagline)
                        .font(.caption).foregroundColor(.gray)
                }
                Spacer()
                VStack(spacing: 4) {
                    Text(ad.status.uppercased())
                        .font(.caption2.bold()).foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(statusColor).cornerRadius(6)
                    Text(planBadge)
                        .font(.caption2.bold()).foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(planColor).cornerRadius(6)
                }
            }

            // CONTACT INFO
            VStack(alignment: .leading, spacing: 4) {
                if let phone = ad.phone, !phone.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill").foregroundColor(.yellow).font(.caption)
                        Text(phone).font(.caption).foregroundColor(.gray)
                    }
                }
                if let email = ad.advertiserEmail, !email.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill").foregroundColor(.yellow).font(.caption)
                        Text(email).font(.caption).foregroundColor(.gray)
                    }
                }
                if let address = ad.address, !address.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill").foregroundColor(.yellow).font(.caption)
                        Text(address).font(.caption).foregroundColor(.gray).lineLimit(1)
                    }
                }
                if let website = ad.websiteURL, !website.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "globe").foregroundColor(.yellow).font(.caption)
                        Text(website).font(.caption).foregroundColor(.gray).lineLimit(1)
                    }
                }
            }

            Divider().background(Color.gray.opacity(0.3))

            // PAYMENT STATUS
            VStack(alignment: .leading, spacing: 8) {
                Text("PAYMENT").font(.caption2.bold()).foregroundColor(.yellow)

                HStack(spacing: 8) {
                    // Payment status selector
                    ForEach(["unpaid", "paid", "expired"], id: \.self) { status in
                        Button(action: { paymentStatus = status }) {
                            Text(status.uppercased())
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(paymentStatus == status ? .black : .gray)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(paymentStatus == status ? paymentStatusColor(status) : Color.white.opacity(0.08))
                                .cornerRadius(6)
                        }
                    }
                    Spacer()
                    Text(planPrice + "/mo")
                        .font(.caption.bold()).foregroundColor(planColor)
                }

                // Paid until date
                if paymentStatus == "paid" {
                    Button(action: { showingDatePicker.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar").foregroundColor(.yellow).font(.caption)
                            Text("Paid Until: \(paidUntil.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption).foregroundColor(.white)
                            Image(systemName: "chevron.down").font(.caption2).foregroundColor(.gray)
                        }
                    }
                    if showingDatePicker {
                        DatePicker("", selection: $paidUntil, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                            .labelsHidden()
                    }
                }

                // Notes
                Button(action: { showingNotes.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "note.text").foregroundColor(.yellow).font(.caption)
                        Text(notes.isEmpty ? "Add notes..." : notes)
                            .font(.caption)
                            .foregroundColor(notes.isEmpty ? .gray.opacity(0.5) : .gray)
                            .lineLimit(2)
                    }
                }
                if showingNotes {
                    TextField("Notes (payment method, date, etc.)", text: $notes)
                        .font(.caption)
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }

                // Save payment status button
                Button(action: { Task { await savePaymentStatus() } }) {
                    HStack {
                        if isSavingPayment { ProgressView().tint(.black).scaleEffect(0.7) }
                        Text(isSavingPayment ? "SAVING..." : "SAVE PAYMENT STATUS")
                            .font(.system(size: 10, weight: .black))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(Color.yellow).foregroundColor(.black).cornerRadius(8)
                }
            }

            Divider().background(Color.gray.opacity(0.3))

            // SEND PAYMENT LINKS
            VStack(alignment: .leading, spacing: 8) {
                Text("SEND PAYMENT LINK").font(.caption2.bold()).foregroundColor(.yellow)

                // Billing type buttons
                HStack(spacing: 8) {
                    // TEXT MESSAGE BUTTONS
                    VStack(spacing: 6) {
                        Text("💬 TEXT").font(.system(size: 9, weight: .black)).foregroundColor(.gray)
                        Button(action: { sendText(recurring: true) }) {
                            Text("MONTHLY")
                                .font(.system(size: 9, weight: .black)).foregroundColor(.black)
                                .frame(maxWidth: .infinity).padding(.vertical, 6)
                                .background(Color.green).cornerRadius(6)
                        }
                        Button(action: { sendText(recurring: false) }) {
                            Text("ONE-TIME")
                                .font(.system(size: 9, weight: .black)).foregroundColor(.black)
                                .frame(maxWidth: .infinity).padding(.vertical, 6)
                                .background(Color.green.opacity(0.6)).cornerRadius(6)
                        }
                    }

                    // EMAIL BUTTONS
                    VStack(spacing: 6) {
                        Text("📧 EMAIL").font(.system(size: 9, weight: .black)).foregroundColor(.gray)
                        Button(action: { sendEmail(recurring: true) }) {
                            Text("MONTHLY")
                                .font(.system(size: 9, weight: .black)).foregroundColor(.black)
                                .frame(maxWidth: .infinity).padding(.vertical, 6)
                                .background(Color.blue).cornerRadius(6)
                        }
                        Button(action: { sendEmail(recurring: false) }) {
                            Text("ONE-TIME")
                                .font(.system(size: 9, weight: .black)).foregroundColor(.black)
                                .frame(maxWidth: .infinity).padding(.vertical, 6)
                                .background(Color.blue.opacity(0.6)).cornerRadius(6)
                        }
                    }
                }
            }

            // APPROVE / REJECT / DELETE BUTTONS
            if onApprove != nil || onReject != nil {
                HStack(spacing: 12) {
                    if let onReject = onReject {
                        Button(action: onReject) {
                            Text(ad.status == "active" ? "DEACTIVATE" : "REJECT")
                                .font(.caption.bold()).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(Color.red.opacity(0.7)).cornerRadius(8)
                        }
                    }
                    if let onApprove = onApprove {
                        Button(action: onApprove) {
                            Text("APPROVE")
                                .font(.caption.bold()).foregroundColor(.black)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(Color.green).cornerRadius(8)
                        }
                    }
                }
                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Text("DELETE PERMANENTLY")
                            .font(.caption.bold()).foregroundColor(.red)
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.4), lineWidth: 1))
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            paymentStatus = ad.paymentStatus ?? "unpaid"
            notes = ad.notes ?? ""
            if let paid = ad.paidUntil { paidUntil = paid }
        }
    }

    private func paymentStatusColor(_ status: String) -> Color {
        switch status {
        case "paid": return .green
        case "expired": return .red
        default: return .orange
        }
    }

    // MARK: - Send Text
    private func sendText(recurring: Bool) {
        guard let phone = ad.phone, !phone.isEmpty else {
            print("⚠️ No phone number for this advertiser")
            return
        }
        let link = recurring ? recurringLink : oneTimeLink
        let billingType = recurring ? "monthly recurring" : "one-time"
        let message = "Hi \(ad.businessName)! This is On Tha Set 🏍️ Your \(planBadge) ad has been approved! Complete your \(planPrice) \(billingType) payment to go live: \(link) — Reply here with any questions!"
        let cleaned = phone.filter { $0.isNumber }
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "sms:\(cleaned)&body=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Send Email
    private func sendEmail(recurring: Bool) {
        guard let email = ad.advertiserEmail, !email.isEmpty else {
            print("⚠️ No email for this advertiser")
            return
        }
        let link = recurring ? recurringLink : oneTimeLink
        let billingType = recurring ? "monthly recurring" : "one-time"
        let subject = "On Tha Set — Your Ad Has Been Approved!"
        let body = """
Hi \(ad.businessName),

Great news! Your On Tha Set advertisement has been approved and is ready to go live.

Plan: \(planBadge)
Price: \(planPrice)/mo (\(billingType))

Complete your payment here:
\(link)

Once payment is confirmed your ad will appear in the app within 24 hours.

Questions? Reply to this email or text us directly.

Ride safe,
On Tha Set Team 🏍️
"""
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(email)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Save Payment Status
    private func savePaymentStatus() async {
        isSavingPayment = true
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

        guard let id = ad.id,
              let url = URL(string: "\(projectURL)/rest/v1/ads?id=eq.\(id.uuidString)") else {
            isSavingPayment = false
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var body: [String: Any] = [
            "payment_status": paymentStatus,
            "notes": notes
        ]
        if paymentStatus == "paid" {
            body["paid_until"] = formatter.string(from: paidUntil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        _ = try? await URLSession.shared.data(for: request)
        isSavingPayment = false
        onRefresh?()
        print("✅ Payment status saved: \(paymentStatus)")
    }
}

// MARK: - Admin Event Card

struct AdminEventCard: View {
    let event: SupabaseEvent
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title).font(.headline.bold()).foregroundColor(.white)
                    Text("Posted by \(event.postedByName)").font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash").foregroundColor(.red)
                        .padding(8).background(Color.red.opacity(0.1)).cornerRadius(8)
                }
            }

            HStack(spacing: 12) {
                Label(event.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(.caption).foregroundColor(.yellow)
                Label(event.category.capitalized, systemImage: "tag.fill")
                    .font(.caption).foregroundColor(.gray)
            }

            let parts = event.locationName.split(separator: "|").map { String($0) }
            if parts.count >= 3 {
                Label("\(parts[0]) — \(parts[2])", systemImage: "mappin.circle.fill")
                    .font(.caption).foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.2), lineWidth: 1))
        .alert("Delete Event", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Delete \"\(event.title)\"? This cannot be undone.")
        }
    }
}
