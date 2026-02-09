//
//  LocationAuthorizationView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/29/26.
//

import SwiftUI
import CoreLocation

struct LocationAuthorizationView: View {
    // USE SHARED LOCATION MANAGER
    @ObservedObject var locationManager = LocationManager.shared
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // LOGO
                ZStack {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.yellow)
                    VStack(spacing: -2) {
                        Text("ON").font(.system(size: 16, weight: .black))
                        Text("THA").font(.system(size: 12, weight: .black))
                        Text("SET").font(.system(size: 20, weight: .black))
                    }
                    .foregroundColor(.black)
                    .offset(y: -4)
                }
                
                // LOCATION ICON
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .symbolRenderingMode(.hierarchical)
                
                // TITLE
                Text("Find Events Near You")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // DESCRIPTION
                VStack(spacing: 15) {
                    featureRow(icon: "mappin.and.ellipse", text: "Discover events happening nearby")
                    featureRow(icon: "ruler", text: "See distance to each event")
                    featureRow(icon: "location.fill.viewfinder", text: "Get accurate weather forecasts")
                    featureRow(icon: "arrow.triangle.turn.up.right.circle", text: "Navigate to venues easily")
                }
                .padding(.horizontal, 40)
                
                // PRIVACY NOTE
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.yellow)
                        Text("Your privacy is protected")
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                    }
                    
                    Text("We only use your location to show nearby events.\nYour location is never shared with others.")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // ENABLE LOCATION BUTTON
                Button(action: {
                    print("🔘 Enable Location button tapped")
                    locationManager.requestLocation()
                    // Dismiss after permission request
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isPresented = false
                    }
                }) {
                    Text("Enable Location")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                
                // SKIP BUTTON
                Button(action: {
                    isPresented = false
                }) {
                    Text("Skip for Now")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .padding(.vertical, 40)
        }
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.yellow)
                .frame(width: 30)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// Preview
struct LocationAuthorizationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationAuthorizationView(isPresented: .constant(true))
    }
}
