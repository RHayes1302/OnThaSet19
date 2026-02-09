//
//  HighlightedEventRow.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import SwiftUI
import SwiftData

// MARK: - Event Row Component

struct HighlightedEventRow: View {
    let event: Event
    let isHighlighted: Bool
    let locationService: LocationManager
    
    var body: some View {
        HStack(spacing: 15) {
            // Thumbnail
            if let data = event.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay(
                        isHighlighted ?
                        VStack {
                            HStack {
                                Text("THIS WEEK")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.yellow)
                                    .cornerRadius(4)
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(4)
                        : nil
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "music.note").foregroundColor(.yellow))
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    if isHighlighted {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                    Text(event.title.uppercased())
                        .font(.headline)
                        .foregroundColor(isHighlighted ? .yellow : .white)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: isHighlighted ? "calendar.badge.exclamationmark" : "calendar")
                        .font(.caption2)
                        .foregroundColor(isHighlighted ? .yellow : .gray)
                    
                    Text(event.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(isHighlighted ? .yellow : .white)
                }
                
                let locationParts = event.locationName.split(separator: "|").map { String($0) }
                if let venueName = locationParts.first {
                    HStack(spacing: 4) {
                        Label(venueName, systemImage: "mappin")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        
                        if let distance = locationService.distanceString(to: event) {
                            Text("• \(distance)")
                                .font(.caption2.bold())
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(isHighlighted ? .yellow : .gray)
        }
        .padding()
        .background(
            Group {
                if isHighlighted {
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.15), Color.yellow.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    LinearGradient(
                        colors: [Color.white.opacity(0.05), Color.white.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}
