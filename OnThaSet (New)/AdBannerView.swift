//
//  AdBannerView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 3/26/26.
//

import SwiftUI
import PhotosUI

// MARK: - Banner Content View

struct AdBannerContentView: View {
    let ad: SupabaseAd

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .shadow(color: glowColor, radius: glowRadius)

            HStack(spacing: 12) {

                ZStack(alignment: .topTrailing) {
                    if let imageURL = ad.imageURL,
                       !imageURL.isEmpty,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFit()
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .empty:
                                ProgressView().frame(width: 64, height: 64)
                            default:
                                defaultBadge
                            }
                        }
                    } else {
                        defaultBadge
                    }

                    if ad.plan == "premium" {
                        Text("👑").font(.system(size: 12)).offset(x: 6, y: -6)
                    } else if ad.plan == "featured" {
                        Text("⭐").font(.system(size: 12)).offset(x: 6, y: -6)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    if ad.plan == "premium" {
                        Text("👑 PREMIUM")
                            .font(.system(size: 8, weight: .black)).foregroundColor(.black)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.yellow).cornerRadius(3)
                    } else if ad.plan == "featured" {
                        Text("⭐ FEATURED")
                            .font(.system(size: 8, weight: .black)).foregroundColor(.black)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.orange).cornerRadius(3)
                    }

                    Text(ad.businessName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white).lineLimit(1)
                    Text(ad.tagline)
                        .font(.system(size: 11))
                        .foregroundColor(.gray).lineLimit(1)
                    if let address = ad.address, !address.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 9)).foregroundColor(accentColor)
                            Text(address)
                                .font(.system(size: 9)).foregroundColor(.gray).lineLimit(1)
                        }
                    }
                }

                Spacer()

                VStack(spacing: 4) {
                    if let phone = ad.phone, !phone.isEmpty {
                        let isAppt = ad.notes?.contains("appointment_only") == true
                        Label(isAppt ? "Schedule" : "Call",
                              systemImage: isAppt ? "calendar.badge.plus" : "phone.fill")
                            .font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background(accentColor).cornerRadius(5)
                    }
                    Text("TAP FOR INFO")
                        .font(.system(size: 7, weight: .bold)).foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
        }
        .frame(height: ad.plan == "basic" ? 100 : 110)
    }

    var defaultBadge: some View {
        VStack(spacing: 3) {
            Text(categoryIcon).font(.system(size: 22))
            Text(categoryLabel)
                .font(.system(size: 9, weight: .black)).foregroundColor(.black)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(accentColor).cornerRadius(3)
        }
        .frame(width: 64)
    }

    var borderColor: Color {
        switch ad.plan {
        case "premium": return .yellow
        case "featured": return .orange
        default: return accentColor.opacity(0.5)
        }
    }

    var borderWidth: CGFloat {
        switch ad.plan {
        case "premium": return 2.0
        case "featured": return 1.5
        default: return 1.0
        }
    }

    var glowColor: Color {
        switch ad.plan {
        case "premium": return .yellow.opacity(0.4)
        case "featured": return .orange.opacity(0.3)
        default: return .clear
        }
    }

    var glowRadius: CGFloat {
        switch ad.plan {
        case "premium": return 8
        case "featured": return 5
        default: return 0
        }
    }

    var accentColor: Color {
        switch ad.category {
        case "lawyer":          return .yellow
        case "biker_bar":       return Color(red: 0.8, green: 0.2, blue: 0.2)
        case "tattoo":          return Color(red: 0.5, green: 0.0, blue: 0.5)
        case "entertainer":     return Color(red: 0.9, green: 0.4, blue: 0.0)
        case "sewing":          return Color(red: 0.2, green: 0.6, blue: 0.5)
        case "custom_paint":    return Color(red: 0.0, green: 0.5, blue: 0.9)
        case "leather_apparel": return Color(red: 0.4, green: 0.2, blue: 0.0)
        case "towing":          return Color(red: 0.9, green: 0.7, blue: 0.0)
        case "photographer":    return Color(red: 0.2, green: 0.2, blue: 0.8)
        case "hotel":           return Color(red: 0.0, green: 0.6, blue: 0.4)
        case "food_truck":      return Color(red: 0.9, green: 0.3, blue: 0.1)
        case "detailing":       return Color(red: 0.0, green: 0.7, blue: 0.7)
        case "dealer":          return Color(red: 0.1, green: 0.5, blue: 0.1)
        case "embroidery":      return Color(red: 0.7, green: 0.3, blue: 0.6)
        case "barber":          return Color(red: 0.2, green: 0.5, blue: 0.8)
        default:                return Color(red: 1.0, green: 0.6, blue: 0.0)
        }
    }

    var categoryIcon: String {
        switch ad.category {
        case "lawyer":          return "⚖️"
        case "biker_bar":       return "🍺"
        case "tattoo":          return "🖋️"
        case "entertainer":     return "🎭"
        case "sewing":          return "🪡"
        case "custom_paint":    return "🎨"
        case "leather_apparel": return "🧥"
        case "towing":          return "🚗"
        case "photographer":    return "📸"
        case "hotel":           return "🏨"
        case "food_truck":      return "🍔"
        case "detailing":       return "✨"
        case "dealer":          return "🏪"
        case "embroidery":      return "🧵"
        case "barber":          return "💈"
        default:                return "🏍️"
        }
    }

    var categoryLabel: String {
        switch ad.category {
        case "lawyer":          return "LEGAL"
        case "biker_bar":       return "BAR"
        case "tattoo":          return "TATTOO"
        case "entertainer":     return "ENTERTAIN"
        case "sewing":          return "SEWING"
        case "custom_paint":    return "PAINT"
        case "leather_apparel": return "APPAREL"
        case "towing":          return "TOWING"
        case "photographer":    return "PHOTO"
        case "hotel":           return "LODGING"
        case "food_truck":      return "FOOD"
        case "detailing":       return "DETAIL"
        case "dealer":          return "DEALER"
        case "embroidery":      return "EMBROIDER"
        case "barber":          return "BARBER"
        default:                return "SHOP"
        }
    }
}

// MARK: - Premium Full Banner

struct PremiumAdBannerView: View {
    let ad: SupabaseAd
    @State private var showingDetail = false

    var accentColor: Color {
        switch ad.category {
        case "lawyer":          return .yellow
        case "biker_bar":       return Color(red: 0.8, green: 0.2, blue: 0.2)
        case "tattoo":          return Color(red: 0.5, green: 0.0, blue: 0.5)
        case "entertainer":     return Color(red: 0.9, green: 0.4, blue: 0.0)
        case "sewing":          return Color(red: 0.2, green: 0.6, blue: 0.5)
        case "custom_paint":    return Color(red: 0.0, green: 0.5, blue: 0.9)
        case "leather_apparel": return Color(red: 0.4, green: 0.2, blue: 0.0)
        case "towing":          return Color(red: 0.9, green: 0.7, blue: 0.0)
        case "photographer":    return Color(red: 0.2, green: 0.2, blue: 0.8)
        case "hotel":           return Color(red: 0.0, green: 0.6, blue: 0.4)
        case "food_truck":      return Color(red: 0.9, green: 0.3, blue: 0.1)
        case "detailing":       return Color(red: 0.0, green: 0.7, blue: 0.7)
        case "dealer":          return Color(red: 0.1, green: 0.5, blue: 0.1)
        case "embroidery":      return Color(red: 0.7, green: 0.3, blue: 0.6)
        case "barber":          return Color(red: 0.2, green: 0.5, blue: 0.8)
        default:                return Color(red: 1.0, green: 0.6, blue: 0.0)
        }
    }

    var categoryIcon: String {
        switch ad.category {
        case "lawyer":          return "⚖️"
        case "biker_bar":       return "🍺"
        case "tattoo":          return "🖋️"
        case "entertainer":     return "🎭"
        case "sewing":          return "🪡"
        case "custom_paint":    return "🎨"
        case "leather_apparel": return "🧥"
        case "towing":          return "🚗"
        case "photographer":    return "📸"
        case "hotel":           return "🏨"
        case "food_truck":      return "🍔"
        case "detailing":       return "✨"
        case "dealer":          return "🏪"
        case "embroidery":      return "🧵"
        case "barber":          return "💈"
        default:                return "🏍️"
        }
    }

    var body: some View {
        Button(action: { showingDetail = true }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow, lineWidth: 1.5))
                    .shadow(color: .yellow.opacity(0.3), radius: 8)

                HStack(spacing: 14) {
                    if let imageURL = ad.imageURL,
                       !imageURL.isEmpty,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFit()
                                    .frame(width: 70, height: 70)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            default:
                                Text(categoryIcon).font(.system(size: 36)).frame(width: 70, height: 70)
                            }
                        }
                    } else {
                        Text(categoryIcon).font(.system(size: 36)).frame(width: 70, height: 70)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("👑 PREMIUM")
                                .font(.system(size: 8, weight: .black)).foregroundColor(.black)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.yellow).cornerRadius(4)
                            Text("SPONSORED")
                                .font(.system(size: 8, weight: .bold)).foregroundColor(.gray.opacity(0.6))
                        }
                        Text(ad.businessName)
                            .font(.system(size: 15, weight: .bold)).foregroundColor(.white).lineLimit(1)
                        Text(ad.tagline)
                            .font(.system(size: 12)).foregroundColor(.gray).lineLimit(1)
                        if let address = ad.address, !address.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 10)).foregroundColor(accentColor)
                                Text(address).font(.system(size: 10)).foregroundColor(.gray).lineLimit(1)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right").font(.caption.bold()).foregroundColor(.yellow)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
            }
            .frame(height: 110)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) { AdDetailView(ad: ad) }
    }
}

// MARK: - Live Premium Ad Strip

struct PremiumAdStripView: View {
    @StateObject private var manager = SupabaseManager.shared
    @State private var currentIndex = 0
    @State private var timer: Timer?

    var premiumAds: [SupabaseAd] {
        manager.activeAds.filter { $0.plan == "premium" }
    }

    var body: some View {
        Group {
            if !premiumAds.isEmpty {
                PremiumAdBannerView(ad: premiumAds[currentIndex % premiumAds.count])
                    .id(currentIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.4), value: currentIndex)
                    .padding(.horizontal).padding(.vertical, 6)
                    .onAppear { startTimer() }
                    .onDisappear { stopTimer() }
            }
        }
        .task { await manager.fetchActiveAds() }
    }

    private func startTimer() {
        guard premiumAds.count > 1 else { return }
        stopTimer()
        let t = Timer(timeInterval: 8.0, repeats: true) { _ in
            withAnimation { currentIndex = (currentIndex + 1) % premiumAds.count }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }
}

// MARK: - Ad Detail View

struct AdDetailView: View {
    let ad: SupabaseAd
    @Environment(\.dismiss) var dismiss
    @State private var showingEditPin = false

    var accentColor: Color {
        switch ad.category {
        case "lawyer":          return .yellow
        case "biker_bar":       return Color(red: 0.8, green: 0.2, blue: 0.2)
        case "tattoo":          return Color(red: 0.5, green: 0.0, blue: 0.5)
        case "entertainer":     return Color(red: 0.9, green: 0.4, blue: 0.0)
        case "sewing":          return Color(red: 0.2, green: 0.6, blue: 0.5)
        case "custom_paint":    return Color(red: 0.0, green: 0.5, blue: 0.9)
        case "leather_apparel": return Color(red: 0.4, green: 0.2, blue: 0.0)
        case "towing":          return Color(red: 0.9, green: 0.7, blue: 0.0)
        case "photographer":    return Color(red: 0.2, green: 0.2, blue: 0.8)
        case "hotel":           return Color(red: 0.0, green: 0.6, blue: 0.4)
        case "food_truck":      return Color(red: 0.9, green: 0.3, blue: 0.1)
        case "detailing":       return Color(red: 0.0, green: 0.7, blue: 0.7)
        case "dealer":          return Color(red: 0.1, green: 0.5, blue: 0.1)
        case "embroidery":      return Color(red: 0.7, green: 0.3, blue: 0.6)
        case "barber":          return Color(red: 0.2, green: 0.5, blue: 0.8)
        default:                return Color(red: 1.0, green: 0.6, blue: 0.0)
        }
    }

    var categoryIcon: String {
        switch ad.category {
        case "lawyer":          return "⚖️"
        case "biker_bar":       return "🍺"
        case "tattoo":          return "🖋️"
        case "entertainer":     return "🎭"
        case "sewing":          return "🪡"
        case "custom_paint":    return "🎨"
        case "leather_apparel": return "🧥"
        case "towing":          return "🚗"
        case "photographer":    return "📸"
        case "hotel":           return "🏨"
        case "food_truck":      return "🍔"
        case "detailing":       return "✨"
        case "dealer":          return "🏪"
        case "embroidery":      return "🧵"
        case "barber":          return "💈"
        default:                return "🏍️"
        }
    }

    var categoryLabel: String {
        switch ad.category {
        case "lawyer":          return "LEGAL SERVICES"
        case "biker_bar":       return "BIKER FRIENDLY BAR"
        case "tattoo":          return "TATTOO ARTIST"
        case "entertainer":     return "ENTERTAINER / DJ / BAND"
        case "sewing":          return "SEWING & CUSTOM PATCHES"
        case "custom_paint":    return "CUSTOM PAINT & BODY"
        case "leather_apparel": return "LEATHER & APPAREL"
        case "towing":          return "TOWING & ROADSIDE"
        case "photographer":    return "PHOTOGRAPHER"
        case "hotel":           return "HOTEL & LODGING"
        case "food_truck":      return "FOOD TRUCK / CATERING"
        case "detailing":       return "BIKE DETAILING"
        case "dealer":          return "MOTORCYCLE DEALER"
        case "embroidery":      return "EMBROIDERY"
        case "barber":          return "BARBER / HAIR / BRAIDS"
        default:                return "MOTORCYCLE SHOP"
        }
    }

    var planBadge: some View {
        Group {
            if ad.plan == "premium" {
                Text("👑 PREMIUM ADVERTISER")
                    .font(.system(size: 10, weight: .black)).foregroundColor(.black)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.yellow).cornerRadius(20)
            } else if ad.plan == "featured" {
                Text("⭐ FEATURED ADVERTISER")
                    .font(.system(size: 10, weight: .black)).foregroundColor(.black)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.orange).cornerRadius(20)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 25) {

                        if let imageURL = ad.imageURL,
                           !imageURL.isEmpty,
                           let url = URL(string: imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFit()
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .shadow(color: accentColor.opacity(0.3), radius: 10)
                                case .empty:
                                    ProgressView().frame(width: 120, height: 120)
                                default:
                                    Text(categoryIcon).font(.system(size: 80))
                                }
                            }
                        } else {
                            Text(categoryIcon).font(.system(size: 80))
                        }

                        VStack(spacing: 8) {
                            planBadge
                            Text(ad.businessName)
                                .font(.title.bold()).foregroundColor(.white).multilineTextAlignment(.center)
                            Text(ad.tagline)
                                .font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center)
                            HStack(spacing: 8) {
                                Text(categoryLabel)
                                    .font(.caption.bold()).foregroundColor(.black)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(accentColor).cornerRadius(20)
                                if ad.notes?.contains("appointment_only") == true {
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar.badge.plus")
                                            .font(.caption2)
                                        Text("By Appointment")
                                            .font(.caption.bold())
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(20)
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.3), lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal)

                        VStack(spacing: 0) {
                            if let address = ad.address, !address.isEmpty {
                                contactRow(icon: "mappin.circle.fill", label: "Address", value: address) { openMaps(address: address) }
                                Divider().background(Color.gray.opacity(0.2))
                            }
                            if let phone = ad.phone, !phone.isEmpty {
                                contactRow(icon: "phone.fill", label: "Phone", value: phone) { callPhone(phone) }
                                Divider().background(Color.gray.opacity(0.2))
                            }
                            if let website = ad.websiteURL, !website.isEmpty {
                                contactRow(icon: "globe", label: "Website", value: website) { openURL(website) }
                            }
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15).padding(.horizontal)

                        VStack(spacing: 12) {
                            let isAppointmentOnly = ad.notes?.contains("appointment_only") == true

                            if let phone = ad.phone, !phone.isEmpty {
                                Button(action: { callPhone(phone) }) {
                                    HStack {
                                        Image(systemName: isAppointmentOnly ? "calendar.badge.plus" : "phone.fill")
                                        Text(isAppointmentOnly ? "CALL TO SCHEDULE APPOINTMENT" : "CALL NOW")
                                            .fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity).padding()
                                    .background(accentColor).foregroundColor(.black).cornerRadius(12)
                                }
                            } else if isAppointmentOnly {
                                // Appointment only but no phone — prompt to use website
                                if let website = ad.websiteURL, !website.isEmpty {
                                    Button(action: { openURL(website) }) {
                                        HStack {
                                            Image(systemName: "calendar.badge.plus")
                                            Text("BOOK APPOINTMENT ONLINE").fontWeight(.bold)
                                        }
                                        .frame(maxWidth: .infinity).padding()
                                        .background(accentColor).foregroundColor(.black).cornerRadius(12)
                                    }
                                }
                            }
                            if let address = ad.address, !address.isEmpty {
                                Button(action: { openMaps(address: address) }) {
                                    HStack {
                                        Image(systemName: "map.fill")
                                        Text("GET DIRECTIONS").fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity).padding()
                                    .background(Color.white.opacity(0.1)).foregroundColor(.white)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentColor, lineWidth: 1))
                                }
                            }
                            if let website = ad.websiteURL, !website.isEmpty {
                                Button(action: { openURL(website) }) {
                                    HStack {
                                        Image(systemName: "safari.fill")
                                        Text("VISIT WEBSITE").fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity).padding()
                                    .background(Color.white.opacity(0.1)).foregroundColor(accentColor)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentColor, lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal)

                        Text("SPONSORED ADVERTISEMENT")
                            .font(.caption2).foregroundColor(.gray.opacity(0.4)).padding(.top, 8)

                        // Advertiser edit button
                        Button(action: { showingEditPin = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil.circle")
                                Text("Are you the advertiser? Edit this ad")
                            }
                            .font(.caption).foregroundColor(.gray.opacity(0.5))
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").foregroundColor(.yellow).font(.title3.bold())
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Advertisement").font(.caption).foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingEditPin = true }) {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.yellow).font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingEditPin) {
                AdEditPinView(ad: ad)
            }
        }
    }

    private func contactRow(icon: String, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon).foregroundColor(accentColor).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.caption.bold()).foregroundColor(.gray)
                    Text(value).font(.subheadline).foregroundColor(.white).lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
            }
            .padding()
        }
    }

    private func callPhone(_ number: String) {
        let cleaned = number.filter { $0.isNumber }
        if let url = URL(string: "tel://\(cleaned)") { UIApplication.shared.open(url) }
    }

    private func openURL(_ urlString: String) {
        var formatted = urlString
        if !formatted.hasPrefix("http") { formatted = "https://\(formatted)" }
        if let url = URL(string: formatted) { UIApplication.shared.open(url) }
    }

    private func openMaps(address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(encoded)") { UIApplication.shared.open(url) }
    }
}

// MARK: - Rotating Ad Strip

struct RotatingAdStripView: View {
    let ads: [SupabaseAd]
    @State private var currentIndex: Int = 0
    @State private var timer: Timer?
    @State private var showingDetail = false

    var body: some View {
        VStack(spacing: 6) {
            // Header
            HStack {
                Text("SPONSORED")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.gray.opacity(0.6)).kerning(1.5)
                Spacer()
                if ads.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<ads.count, id: \.self) { i in
                            Circle()
                                .fill(i == currentIndex ? Color.yellow : Color.gray.opacity(0.3))
                                .frame(width: i == currentIndex ? 8 : 5, height: i == currentIndex ? 8 : 5)
                                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            if !ads.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(ads.indices, id: \.self) { i in
                        AdBannerContentView(ad: ads[i])
                            .padding(.horizontal, 16)
                            .tag(i)
                            .onTapGesture {
                                stopTimer()
                                showingDetail = true
                            }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 110)
                .onChange(of: currentIndex) { _, _ in
                    stopTimer()
                    startTimer()
                }
                .sheet(isPresented: $showingDetail, onDismiss: { startTimer() }) {
                    AdDetailView(ad: ads[min(currentIndex, ads.count - 1)])
                }

                if ads.count > 1 {
                    Text("Swipe to browse • Tap to view details")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.gray.opacity(0.4))
                }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private func startTimer() {
        guard ads.count > 1 else { return }
        stopTimer()
        let t = Timer(timeInterval: 6.0, repeats: true) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % ads.count
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }
}

// MARK: - Live Ad Strip

struct LiveAdStripView: View {
    @StateObject private var manager = SupabaseManager.shared
    var filteredAds: [SupabaseAd] { manager.activeAds }

    var body: some View {
        Group {
            if filteredAds.isEmpty {
                EmptyView()
            } else {
                RotatingAdStripView(ads: filteredAds)
                    .padding(.vertical, 4)
            }
        }
        .task { await manager.fetchActiveAds() }
    }
}

// MARK: - Advertiser Signup View

struct AdvertiserSignupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var businessName = ""
    @State private var tagline = ""
    @State private var category = "lawyer"
    @State private var selectedPlan = "basic"
    @State private var billingPreference = "monthly"
    @State private var advertiserEmail = ""
    @State private var advertiserPin = ""
    @State private var showPin = false
    @State private var phone = ""
    @State private var websiteURL = ""
    @State private var streetAddress = ""
    @State private var cityName = ""
    @State private var stateName = ""
    @State private var zipCode = ""
    @State private var appointmentOnly = false
    @State private var hideAddress = false
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    @State private var selectedLogoItem: PhotosPickerItem?
    @State private var selectedLogoData: Data?

    private var isFormValid: Bool {
        !businessName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !tagline.trimmingCharacters(in: .whitespaces).isEmpty &&
        !advertiserEmail.trimmingCharacters(in: .whitespaces).isEmpty &&
        advertiserPin.count == 4
    }

    private var logoUploadAllowed: Bool {
        selectedPlan == "featured" || selectedPlan == "premium"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // HEADER
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").foregroundColor(.yellow).font(.title2.bold())
                    }
                    Spacer()
                    ZStack {
                        Image(systemName: "shield.fill").font(.system(size: 45)).foregroundColor(.yellow)
                        VStack(spacing: -1) {
                            Text("ON").font(.system(size: 7, weight: .black))
                            Text("THA").font(.system(size: 6, weight: .black))
                            Text("SET").font(.system(size: 9, weight: .black))
                        }.foregroundColor(.black).offset(y: -2)
                    }
                    Spacer()
                    Image(systemName: "xmark").opacity(0)
                }
                .padding(.horizontal, 25).padding(.vertical, 10)

                ScrollView {
                    VStack(spacing: 20) {

                        VStack(spacing: 6) {
                            Text("ADVERTISE WITH US")
                                .font(.title2.bold()).foregroundColor(.yellow)
                            Text("Reach the riding community in your area")
                                .font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
                        }
                        .padding(.top, 10)

                        // PLAN SELECTOR
                        VStack(spacing: 10) {
                            Text("SELECT YOUR PLAN")
                                .font(.caption.bold()).foregroundColor(.yellow)
                            VStack(spacing: 8) {
                                planSelector(title: "Basic", price: "$19.99/mo", badge: nil,
                                    desc: "Name + tagline + address",
                                    features: "Standard banner • Home page only",
                                    value: "basic", color: .gray)
                                planSelector(title: "Featured", price: "$29.99/mo", badge: "⭐",
                                    desc: "Logo + links + address",
                                    features: "Gold border • Logo upload • Home page",
                                    value: "featured", color: .orange)
                                planSelector(title: "Premium", price: "$49.99/mo", badge: "👑",
                                    desc: "Maximum exposure",
                                    features: "Yellow glow • Logo • ALL pages",
                                    value: "premium", color: .yellow)
                            }
                        }
                        .padding(.horizontal)

                        // BILLING PREFERENCE
                        VStack(spacing: 10) {
                            Text("BILLING PREFERENCE")
                                .font(.caption.bold()).foregroundColor(.yellow)
                            HStack(spacing: 8) {
                                Button(action: { billingPreference = "monthly" }) {
                                    VStack(spacing: 4) {
                                        Text("🔄 MONTHLY").font(.caption.bold())
                                        Text("Auto-renews each month")
                                            .font(.system(size: 9))
                                            .foregroundColor(billingPreference == "monthly" ? .black.opacity(0.7) : .gray)
                                    }
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(billingPreference == "monthly" ? Color.yellow : Color.white.opacity(0.06))
                                    .foregroundColor(billingPreference == "monthly" ? .black : .white)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow.opacity(0.4), lineWidth: 1))
                                }
                                Button(action: { billingPreference = "onetime" }) {
                                    VStack(spacing: 4) {
                                        Text("1️⃣ ONE-TIME").font(.caption.bold())
                                        Text("Manual renewal each month")
                                            .font(.system(size: 9))
                                            .foregroundColor(billingPreference == "onetime" ? .black.opacity(0.7) : .gray)
                                    }
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(billingPreference == "onetime" ? Color.orange : Color.white.opacity(0.06))
                                    .foregroundColor(billingPreference == "onetime" ? .black : .white)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.4), lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal)

                        // LOGO UPLOAD
                        VStack(spacing: 10) {
                            HStack {
                                Text("BUSINESS LOGO")
                                    .font(.caption2.bold())
                                    .foregroundColor(logoUploadAllowed ? .yellow : .gray)
                                if !logoUploadAllowed {
                                    Text("(Featured & Premium only)")
                                        .font(.caption2).foregroundColor(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 5)

                            if logoUploadAllowed {
                                PhotosPicker(selection: $selectedLogoItem, matching: .images) {
                                    ZStack {
                                        if let data = selectedLogoData, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable().scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow, lineWidth: 2))
                                        } else {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white.opacity(0.08))
                                                .frame(width: 100, height: 100)
                                                .overlay(
                                                    VStack(spacing: 6) {
                                                        Image(systemName: "photo.badge.plus")
                                                            .font(.title2).foregroundColor(.yellow)
                                                        Text("Add Logo")
                                                            .font(.caption2.bold()).foregroundColor(.gray)
                                                    }
                                                )
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                Text("Logo appears in your ad banner")
                                    .font(.caption2).foregroundColor(.gray).multilineTextAlignment(.center)
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.03))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        VStack(spacing: 6) {
                                            Image(systemName: "lock.fill")
                                                .font(.title2).foregroundColor(.gray.opacity(0.3))
                                            Text("Upgrade to\nFeatured")
                                                .font(.caption2).foregroundColor(.gray.opacity(0.4))
                                                .multilineTextAlignment(.center)
                                        }
                                    )
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .padding(.horizontal)
                        .onChange(of: selectedLogoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    var compression: CGFloat = 0.8
                                    var compressed = uiImage.jpegData(compressionQuality: compression) ?? data
                                    while compressed.count > 300_000 && compression > 0.1 {
                                        compression -= 0.1
                                        compressed = uiImage.jpegData(compressionQuality: compression) ?? compressed
                                    }
                                    selectedLogoData = compressed
                                }
                            }
                        }

                        // FORM FIELDS
                        VStack(spacing: 16) {
                            formField(label: "BUSINESS NAME") {
                                TextField("e.g. Iron Mile Cycles", text: $businessName)
                                    .modifier(FormTextFieldStyle())
                            }
                            formField(label: "TAGLINE") {
                                TextField("e.g. Parts. Service. Custom builds.", text: $tagline)
                                    .modifier(FormTextFieldStyle())
                            }
                            formField(label: "EMAIL ADDRESS (REQUIRED)") {
                                TextField("your@email.com", text: $advertiserEmail)
                                    .modifier(FormTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            formField(label: "SECURITY PIN (REQUIRED — 4 digits to edit your ad)") {
                                HStack {
                                    if showPin {
                                        TextField("4-digit PIN", text: $advertiserPin)
                                            .keyboardType(.numberPad)
                                            .modifier(FormTextFieldStyle())
                                            .onChange(of: advertiserPin) { _, v in
                                                advertiserPin = String(v.filter { $0.isNumber }.prefix(4))
                                            }
                                    } else {
                                        SecureField("4-digit PIN", text: $advertiserPin)
                                            .keyboardType(.numberPad)
                                            .modifier(FormTextFieldStyle())
                                            .onChange(of: advertiserPin) { _, v in
                                                advertiserPin = String(v.filter { $0.isNumber }.prefix(4))
                                            }
                                    }
                                    Button(action: { showPin.toggle() }) {
                                        Image(systemName: showPin ? "eye.slash" : "eye")
                                            .foregroundColor(.gray).padding(.trailing, 8)
                                    }
                                }
                                .background(Color.white.opacity(0.08)).cornerRadius(10)
                                Text("You'll use this PIN to update your ad info later")
                                    .font(.caption2).foregroundColor(.gray)
                            }
                            formField(label: "CATEGORY") {
                                VStack(spacing: 8) {
                                    HStack(spacing: 8) {
                                        categoryButton(label: "⚖️ Lawyer / Legal", value: "lawyer")
                                        categoryButton(label: "🏍️ Motorcycle Shop", value: "motorcycle_shop")
                                    }
                                    HStack(spacing: 8) {
                                        categoryButton(label: "🍺 Biker Friendly Bar", value: "biker_bar")
                                        categoryButton(label: "🎭 Entertainer / DJ / Band", value: "entertainer")
                                    }
                                    HStack(spacing: 8) {
                                        categoryButton(label: "🪡 Sewing & Patches", value: "sewing")
                                        categoryButton(label: "🎨 Custom Paint", value: "custom_paint")
                                    }
                                    HStack(spacing: 8) {
                                        categoryButton(label: "🧥 Leather & Apparel", value: "leather_apparel")
                                        categoryButton(label: "🚗 Towing & Roadside", value: "towing")
                                    }
                                    HStack(spacing: 8) {
                                        categoryButton(label: "🖋️ Tattoo Artist", value: "tattoo")
                                        categoryButton(label: "📸 Photographer", value: "photographer")
                                    }
                                    HStack(spacing: 8) {
                                        categoryButton(label: "🏨 Hotel & Lodging", value: "hotel")
                                        categoryButton(label: "🍔 Food Truck", value: "food_truck")
                                    }
                                    HStack(spacing: 8) {
                                        categoryButton(label: "✨ Detailing", value: "detailing")
                                        categoryButton(label: "🏍️ Motorcycle Dealer", value: "dealer")
                                    }
                                    HStack(spacing: 8) {
                                        categoryButton(label: "🧵 Embroidery", value: "embroidery")
                                        categoryButton(label: "💈 Barber / Hair / Braids", value: "barber")
                                    }
                                }
                            }
                            // APPOINTMENT TOGGLE
                            VStack(alignment: .leading, spacing: 10) {
                                Text("BOOKING TYPE")
                                    .font(.caption2.bold()).foregroundColor(.yellow).padding(.leading, 5)
                                HStack(spacing: 12) {
                                    Button(action: { appointmentOnly = false }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: appointmentOnly ? "circle" : "checkmark.circle.fill")
                                                .foregroundColor(.yellow)
                                            Text("Walk-ins Welcome")
                                                .font(.caption.bold())
                                                .foregroundColor(appointmentOnly ? .gray : .white)
                                        }
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(appointmentOnly ? Color.white.opacity(0.05) : Color.yellow.opacity(0.15))
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(appointmentOnly ? Color.gray.opacity(0.3) : Color.yellow.opacity(0.5), lineWidth: 1))
                                    }
                                    Button(action: { appointmentOnly = true }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: appointmentOnly ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(.yellow)
                                            Text("By Appointment Only")
                                                .font(.caption.bold())
                                                .foregroundColor(appointmentOnly ? .white : .gray)
                                        }
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(appointmentOnly ? Color.yellow.opacity(0.15) : Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(appointmentOnly ? Color.yellow.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1))
                                    }
                                }
                            }

                            // ADDRESS SECTION
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("LOCATION")
                                        .font(.caption2.bold()).foregroundColor(.yellow).padding(.leading, 5)
                                    Spacer()
                                    // Hide address toggle
                                    Button(action: { hideAddress.toggle() }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: hideAddress ? "eye.slash.fill" : "eye.fill")
                                                .font(.caption).foregroundColor(hideAddress ? .orange : .gray)
                                            Text(hideAddress ? "Address Hidden" : "Show Address")
                                                .font(.caption2.bold())
                                                .foregroundColor(hideAddress ? .orange : .gray)
                                        }
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(hideAddress ? Color.orange.opacity(0.1) : Color.white.opacity(0.05))
                                        .cornerRadius(6)
                                    }
                                }

                                if hideAddress {
                                    // Still collect city/state for location-based filtering
                                    Text("Your full address stays private. We only use your city/state to show your ad to nearby riders.")
                                        .font(.caption2).foregroundColor(.gray)
                                        .padding(10)
                                        .background(Color.orange.opacity(0.08))
                                        .cornerRadius(8)
                                    HStack(spacing: 12) {
                                        formField(label: "CITY") {
                                            TextField("City", text: $cityName).modifier(FormTextFieldStyle())
                                        }
                                        formField(label: "STATE") {
                                            TextField("ST", text: $stateName).modifier(FormTextFieldStyle())
                                        }.frame(width: 70)
                                        formField(label: "ZIP") {
                                            TextField("00000", text: $zipCode)
                                                .modifier(FormTextFieldStyle()).keyboardType(.numberPad)
                                        }.frame(width: 90)
                                    }
                                } else {
                                    formField(label: "STREET ADDRESS (OPTIONAL)") {
                                        TextField("123 Main Street", text: $streetAddress)
                                            .modifier(FormTextFieldStyle())
                                    }
                                    HStack(spacing: 12) {
                                        formField(label: "CITY") {
                                            TextField("City", text: $cityName).modifier(FormTextFieldStyle())
                                        }
                                        formField(label: "STATE") {
                                            TextField("ST", text: $stateName).modifier(FormTextFieldStyle())
                                        }.frame(width: 70)
                                        formField(label: "ZIP") {
                                            TextField("00000", text: $zipCode)
                                                .modifier(FormTextFieldStyle()).keyboardType(.numberPad)
                                        }.frame(width: 90)
                                    }
                                }
                            }
                            formField(label: "PHONE NUMBER (OPTIONAL)") {
                                TextField("e.g. 7025550100", text: $phone)
                                    .modifier(FormTextFieldStyle()).keyboardType(.phonePad)
                            }
                            formField(label: "WEBSITE (OPTIONAL)") {
                                TextField("e.g. yoursite.com", text: $websiteURL)
                                    .modifier(FormTextFieldStyle()).keyboardType(.URL)
                                    .autocapitalization(.none)
                            }
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("WHAT HAPPENS NEXT").font(.caption.bold()).foregroundColor(.yellow)
                            Text("After submitting your ad will be reviewed and approved within 24 hours. You will then be contacted via email or phone to complete your \(billingPreference == "monthly" ? "monthly recurring" : "one-time") payment of \(selectedPlan == "premium" ? "$49.99" : selectedPlan == "featured" ? "$29.99" : "$19.99").")
                                .font(.caption).foregroundColor(.gray)
                        }
                        .padding().background(Color.white.opacity(0.05))
                        .cornerRadius(10).padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }

                Button(action: { Task { await submitAd() } }) {
                    HStack {
                        if isSubmitting { ProgressView().tint(.black).padding(.trailing, 4) }
                        Text(isSubmitting ? "SUBMITTING..." : "SUBMIT FOR REVIEW")
                            .font(.headline.bold()).foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(isFormValid && !isSubmitting ? Color.yellow : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || isSubmitting)
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Submitted!", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your ad has been submitted for review. We will be in touch within 24 hours to complete your \(billingPreference == "monthly" ? "monthly recurring" : "one-time") payment setup.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func planSelector(title: String, price: String, badge: String?, desc: String, features: String, value: String, color: Color) -> some View {
        Button(action: { selectedPlan = value }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if let badge = badge { Text(badge).font(.system(size: 14)) }
                        Text(title).font(.headline.bold())
                            .foregroundColor(selectedPlan == value ? .black : .white)
                        Text(price).font(.caption.bold())
                            .foregroundColor(selectedPlan == value ? .black.opacity(0.7) : color)
                    }
                    Text(desc).font(.caption)
                        .foregroundColor(selectedPlan == value ? .black.opacity(0.7) : .gray)
                    Text(features).font(.system(size: 10))
                        .foregroundColor(selectedPlan == value ? .black.opacity(0.6) : .gray.opacity(0.6))
                }
                Spacer()
                if selectedPlan == value {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.black).font(.title3)
                }
            }
            .padding()
            .background(selectedPlan == value ? color : Color.white.opacity(0.06))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(selectedPlan == value ? 0 : 0.4), lineWidth: 1))
            .shadow(color: selectedPlan == value ? color.opacity(0.3) : .clear, radius: 5)
        }
    }

    private func categoryButton(label: String, value: String) -> some View {
        Button(action: { category = value }) {
            Text(label).font(.caption.bold())
                .foregroundColor(category == value ? .black : .yellow)
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(category == value ? Color.yellow : Color.white.opacity(0.06))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow.opacity(0.4), lineWidth: 1))
        }
    }

    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption2.bold()).foregroundColor(.yellow).padding(.leading, 5)
            content()
        }
    }

    private func submitAd() async {
        isSubmitting = true

        var logoURL: String? = nil
        if logoUploadAllowed, let logoData = selectedLogoData {
            let fileName = "logo-\(UUID().uuidString).jpg"
            do {
                logoURL = try await SupabaseManager.shared.uploadImage(
                    data: logoData, bucket: "ad-banners", fileName: fileName
                )
            } catch {
                print("⚠️ Logo upload failed: \(error)")
            }
        }

        // Build address — if hideAddress, only use city/state/zip for geocoding, don't display street
        var addressParts: [String] = []
        if !hideAddress && !streetAddress.isEmpty { addressParts.append(streetAddress) }
        if !cityName.isEmpty { addressParts.append(cityName) }
        if !stateName.isEmpty { addressParts.append(stateName) }
        if !zipCode.isEmpty { addressParts.append(zipCode) }
        let fullAddress = addressParts.joined(separator: ", ")

        // Build full address for geocoding (always includes street even if hidden from display)
        var geocodeParts: [String] = []
        if !streetAddress.isEmpty { geocodeParts.append(streetAddress) }
        if !cityName.isEmpty { geocodeParts.append(cityName) }
        if !stateName.isEmpty { geocodeParts.append(stateName) }
        if !zipCode.isEmpty { geocodeParts.append(zipCode) }
        let fullGeocodeAddress = geocodeParts.joined(separator: ", ")

        // Build notes to store appointment-only, hide-address flags, and full geocode address
        var adNotes = ""
        if appointmentOnly { adNotes += "appointment_only" }
        if hideAddress { adNotes += adNotes.isEmpty ? "hide_address" : ",hide_address" }
        if hideAddress && !fullGeocodeAddress.isEmpty {
            adNotes += ",geocode:\(fullGeocodeAddress)"
        }

        let newAd = SupabaseAd(
            id: UUID(),
            businessName: businessName,
            tagline: appointmentOnly ? tagline + " • By Appointment Only" : tagline,
            category: category,
            phone: phone.isEmpty ? nil : phone,
            websiteURL: websiteURL.isEmpty ? nil : websiteURL,
            imageURL: logoURL,
            address: fullAddress.isEmpty ? nil : fullAddress,
            status: "pending",
            plan: selectedPlan,
            advertiserEmail: advertiserEmail.isEmpty ? nil : advertiserEmail,
            paymentStatus: "unpaid",
            paidUntil: nil,
            notes: adNotes.isEmpty ? nil : adNotes,
            billingPreference: billingPreference,
            advertiserPin: advertiserPin.isEmpty ? nil : advertiserPin
        )

        do {
            try await SupabaseManager.shared.submitAd(newAd)
            isSubmitting = false
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
            showError = true
        }
    }
}
