//
//  EventRow.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/7/25.
//

import SwiftUI
import SwiftData

struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 15) {
            // MINI FLYER THUMBNAIL - SHOWS ENTIRE IMAGE
            if let data = event.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "music.note").foregroundColor(.yellow))
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(event.title.uppercased())
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.yellow)
                
                // Parse location to show venue name
                let locationParts = event.locationName.split(separator: "|").map { String($0) }
                if let venueName = locationParts.first {
                    Label(venueName, systemImage: "mappin")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                } else {
                    Label(event.locationName, systemImage: "mappin")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}
