//
//  ShareSheet.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/29/26.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Share Helper for SwiftData Events
struct EventShareHelper {

    static func createShareMessage(for event: Event) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short

        let locationParts = event.locationName.split(separator: "|").map { String($0) }
        let venueName = locationParts.first ?? "TBA"
        let cityState = locationParts.count >= 5 ? "\(locationParts[2]), \(locationParts[3])" : ""

        return """
        🏍️ CHECK OUT THIS EVENT! 🏍️

        \(event.title.uppercased())

        📅 \(dateFormatter.string(from: event.date))
        📍 \(venueName)
        \(cityState.isEmpty ? "" : "   \(cityState)\n")
        \(event.details.isEmpty ? "" : "ℹ️ \(event.details)\n")
        🛣️ Find more events on the ON THA SET app!

        #OnThaSet #MotoLife #\(event.category.rawValue.replacingOccurrences(of: " ", with: ""))
        """
    }

    static func createShareItems(for event: Event) -> [Any] {
        var items: [Any] = [createShareMessage(for: event)]
        if let imageData = event.imageData, let image = UIImage(data: imageData) {
            items.append(image)
        }
        return items
    }

    static func createStyledShareImage(for event: Event) -> UIImage? {
        guard let imageData = event.imageData,
              let flyerImage = UIImage(data: imageData) else { return nil }

        let size = CGSize(width: 1080, height: 1920)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            flyerImage.draw(in: CGRect(x: 90, y: 300, width: 900, height: 900))

            let brandingAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 60, weight: .black),
                .foregroundColor: UIColor.systemYellow
            ]
            let brandingText = "ON THA SET"
            let brandingSize = brandingText.size(withAttributes: brandingAttrs)
            brandingText.draw(in: CGRect(
                x: (size.width - brandingSize.width) / 2,
                y: 150, width: brandingSize.width, height: brandingSize.height
            ), withAttributes: brandingAttrs)

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            event.title.uppercased().draw(
                in: CGRect(x: 90, y: 1300, width: 900, height: 200),
                withAttributes: titleAttrs
            )

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30, weight: .medium),
                .foregroundColor: UIColor.systemYellow
            ]
            ("📅 " + dateFormatter.string(from: event.date)).draw(
                in: CGRect(x: 90, y: 1500, width: 900, height: 50),
                withAttributes: dateAttrs
            )

            let ctaText = "Download ON THA SET App"
            let ctaAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            let ctaSize = ctaText.size(withAttributes: ctaAttrs)
            ctaText.draw(in: CGRect(
                x: (size.width - ctaSize.width) / 2,
                y: 1700, width: ctaSize.width, height: ctaSize.height
            ), withAttributes: ctaAttrs)
        }
    }
}

// MARK: - Share Helper for Supabase Events
struct SupabaseEventShareHelper {

    static func createShareMessage(title: String, date: Date, locationName: String, details: String, category: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short

        let parts = locationName.split(separator: "|").map { String($0) }
        let venueName = parts.first ?? "TBA"
        let cityState = parts.count >= 5 ? "\(parts[2]), \(parts[3])" : ""

        return """
        🏍️ CHECK OUT THIS EVENT! 🏍️

        \(title.uppercased())

        📅 \(dateFormatter.string(from: date))
        📍 \(venueName)
        \(cityState.isEmpty ? "" : "   \(cityState)\n")
        \(details.isEmpty ? "" : "ℹ️ \(details)\n")
        🛣️ Find more events on the ON THA SET app!

        #OnThaSet #MotoLife #\(category.replacingOccurrences(of: " ", with: ""))
        """
    }

    static func shareItems(for event: SupabaseEvent, flyerImage: UIImage? = nil) -> [Any] {
        let message = createShareMessage(
            title: event.title,
            date: event.date,
            locationName: event.locationName,
            details: event.details,
            category: event.category
        )
        var items: [Any] = [message]
        if let image = flyerImage { items.append(image) }
        return items
    }

    static func shareItems(for event: NearbyEvent, flyerImage: UIImage? = nil) -> [Any] {
        let message = createShareMessage(
            title: event.title,
            date: event.date,
            locationName: event.locationName,
            details: event.details,
            category: event.category
        )
        var items: [Any] = [message]
        if let image = flyerImage { items.append(image) }
        return items
    }
}

// MARK: - Supabase Event Share View
struct SupabaseEventShareView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let date: Date
    let locationName: String
    let details: String
    let category: String
    let imageURL: String?

    @State private var showingNativeShare = false
    @State private var showingCopiedAlert = false
    @State private var flyerImage: UIImage? = nil

    var shareMessage: String {
        SupabaseEventShareHelper.createShareMessage(
            title: title,
            date: date,
            locationName: locationName,
            details: details,
            category: category
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {

                        // HEADER
                        VStack(spacing: 10) {
                            Image(systemName: "megaphone.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.yellow)
                            Text("Share This Event")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text("Help spread the word and grow the community!")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)

                        // PREVIEW
                        VStack(alignment: .leading, spacing: 15) {
                            Text("PREVIEW")
                                .font(.caption.bold())
                                .foregroundColor(.yellow)

                            if let img = flyerImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(12)
                            }

                            Text(shareMessage)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        .padding(.horizontal)

                        // SHARE BUTTONS
                        VStack(spacing: 12) {
                            Button(action: { showingNativeShare = true }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share via...")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            }

                            Button(action: {
                                UIPasteboard.general.string = shareMessage
                                showingCopiedAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy Event Details")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.yellow)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)

                        // TIPS
                        VStack(alignment: .leading, spacing: 10) {
                            Text("💡 SHARING TIPS")
                                .font(.caption.bold())
                                .foregroundColor(.yellow)
                            tipRow(icon: "message.fill", text: "Text friends & family directly")
                            tipRow(icon: "photo.on.rectangle", text: "Post to Instagram/Facebook stories")
                            tipRow(icon: "ellipsis.message.fill", text: "Share in group chats")
                            tipRow(icon: "link", text: "Copy and paste everywhere!")
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.yellow)
                }
            }
            .sheet(isPresented: $showingNativeShare) {
                let items = flyerImage != nil
                    ? [shareMessage, flyerImage!] as [Any]
                    : [shareMessage] as [Any]
                ShareSheet(items: items)
            }
            .alert("Copied!", isPresented: $showingCopiedAlert) {
                Button("OK") { }
            } message: {
                Text("Event details copied to clipboard")
            }
            .task {
                await loadFlyerImage()
            }
        }
    }

    func loadFlyerImage() async {
        guard let urlString = imageURL,
              !urlString.isEmpty,
              let url = URL(string: urlString) else { return }
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let image = UIImage(data: data) {
            flyerImage = image
        }
    }

    func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(.yellow).frame(width: 20)
            Text(text).font(.caption).foregroundColor(.gray)
            Spacer()
        }
    }
}
