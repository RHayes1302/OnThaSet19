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
    @State private var allEvents: [SupabaseEvent] = []
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
                }
                .background(Color.white.opacity(0.05))

                // TAB SELECTOR
                Picker("", selection: $selectedTab) {
                    Text("Pending (\(pendingAds.count))").tag(0)
                    Text("Active Ads").tag(1)
                    Text("Events").tag(2)
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
                                            onRefresh: { Task { await loadAll() } }
                                        )
                                    }
                                }
                            } else {
                                if allEvents.isEmpty {
                                    emptyState(message: "No events", icon: "calendar")
                                } else {
                                    ForEach(allEvents) { event in
                                        AdminEventCard(event: event, onDelete: {
                                            Task { await deleteEvent(event) }
                                        })
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

        if let (data, _) = try? await URLSession.shared.data(for: request),
           let ads = try? JSONDecoder().decode([SupabaseAd].self, from: data) {
            pendingAds = ads.filter { $0.status == "pending" }
            activeAds = ads.filter { $0.status == "active" }
        }
    }

    private func loadEvents() async {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

        guard let url = URL(string: "\(projectURL)/rest/v1/events?order=created_at.desc") else { return }
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

    private func deleteEvent(_ event: SupabaseEvent) async {
        guard let id = event.id else { return }
        try? await SupabaseManager.shared.deleteEvent(id: id)
        await loadEvents()
    }
}

// MARK: - Admin Ad Card

struct AdminAdCard: View {
    let ad: SupabaseAd
    let onApprove: (() -> Void)?
    let onReject: (() -> Void)?
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

            // APPROVE / REJECT BUTTONS
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
