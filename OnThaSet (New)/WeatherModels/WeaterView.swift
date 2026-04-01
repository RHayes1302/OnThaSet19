//
//  WeatherView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/16/26.
//

import SwiftUI
import CoreLocation

struct WeatherView: View {
    @StateObject private var weatherViewModel = WeatherViewModel()
    @ObservedObject private var locationManager = LocationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var hasLoadedWeather = false

    var body: some View {
        ZStack(alignment: .topLeading) {

            // BACKGROUND
            Color.clear
                .background {
                    ZStack {
                        Image("Road").resizable().aspectRatio(contentMode: .fill)
                        Color.black.opacity(0.5)
                    }
                    .ignoresSafeArea()
                }
                .allowsHitTesting(false)

            // MAIN CONTENT
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {

                    // LOGO
                    ZStack {
                        Image(systemName: "shield.fill").font(.system(size: 80)).foregroundColor(.yellow)
                        VStack(spacing: -2) {
                            Text("ON").font(.system(size: 12, weight: .black))
                            Text("THA").font(.system(size: 10, weight: .black))
                            Text("SET").font(.system(size: 15, weight: .black))
                        }.foregroundColor(.black).offset(y: -4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 70)

                    // TITLE
                    Text("Ride Forecast")
                        .font(.system(size: 48, weight: .black, design: .serif))
                        .foregroundStyle(.white).shadow(radius: 5)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)

                    // LOCATION STATUS
                    if let _ = locationManager.userLocation {
                        Text(weatherViewModel.cityName.isEmpty ? "Loading..." : weatherViewModel.cityName.uppercased())
                            .font(.title3.bold()).foregroundColor(.yellow)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("📍 Your Location")
                            .font(.caption).foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        VStack(spacing: 15) {
                            Image(systemName: "location.slash")
                                .font(.system(size: 40)).foregroundColor(.yellow.opacity(0.5))
                            Text("Location Not Available").font(.headline).foregroundColor(.white)
                            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                                Text("Please enable location services in Settings")
                                    .font(.caption).foregroundColor(.gray)
                                    .multilineTextAlignment(.center).padding(.horizontal, 40)
                                Button(action: {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("OPEN SETTINGS").font(.caption.bold()).foregroundColor(.black)
                                        .padding(.horizontal, 20).padding(.vertical, 10)
                                        .background(Color.yellow).cornerRadius(5)
                                }
                            } else {
                                Text("Requesting location...")
                                    .font(.caption).foregroundColor(.gray)
                                    .multilineTextAlignment(.center).padding(.horizontal, 40)
                                Button(action: { locationManager.requestLocation() }) {
                                    Text("ENABLE LOCATION").font(.caption.bold()).foregroundColor(.black)
                                        .padding(.horizontal, 20).padding(.vertical, 10)
                                        .background(Color.yellow).cornerRadius(5)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 40)
                    }

                    // RIDE SAFETY BANNER
                    if !weatherViewModel.rideSafetyMessage.isEmpty {
                        HStack(spacing: 15) {
                            ZStack {
                                Image(systemName: "shield.fill").font(.system(size: 45)).foregroundColor(.yellow)
                                VStack(spacing: -1) {
                                    Text("ON").font(.system(size: 7, weight: .black))
                                    Text("THA").font(.system(size: 6, weight: .black))
                                    Text("SET").font(.system(size: 9, weight: .black))
                                }.foregroundColor(.black).offset(y: -2)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(weatherViewModel.rideSafetyMessage).font(.headline).fontWeight(.black)
                                Text(weatherViewModel.cityName.uppercased()).font(.caption2).tracking(2)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(weatherViewModel.rideSafetyColor.opacity(0.95))
                        .cornerRadius(12).foregroundStyle(.white).padding(.horizontal)
                    }

                    // PREMIUM AD BANNER
                    PremiumAdStripView()

                    // RIGHT NOW CARD
                    if !weatherViewModel.currentTemp.isEmpty {
                        VStack(spacing: 12) {
                            Text("RIGHT NOW").font(.caption.bold()).foregroundColor(.yellow)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)

                            HStack(spacing: 20) {
                                Image(systemName: weatherViewModel.mapWeatherCode(weatherViewModel.currentWeatherCode))
                                    .symbolRenderingMode(.multicolor).font(.system(size: 60))

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(weatherViewModel.currentTemp)
                                        .font(.system(size: 64, weight: .black)).foregroundColor(.white)
                                    HStack(spacing: 6) {
                                        Image(systemName: "wind").font(.caption).foregroundColor(.yellow)
                                        Text("Wind: \(weatherViewModel.currentWindSpeed)")
                                            .font(.subheadline).foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(15).padding(.horizontal)
                        }
                    }

                    // 7-DAY FORECAST
                    if !weatherViewModel.dailyForecasts.isEmpty {
                        Text("7-DAY FORECAST").font(.caption.bold()).foregroundColor(.yellow)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)

                        VStack(spacing: 0) {
                            ForEach(weatherViewModel.dailyForecasts) { day in
                                HStack {
                                    Text(day.day).font(.system(size: 16, weight: .bold))
                                        .frame(width: 75, alignment: .leading).foregroundStyle(.black)
                                    Spacer()
                                    Image(systemName: day.iconName).symbolRenderingMode(.multicolor).font(.title3)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Text(day.lowTemp).opacity(0.7)
                                        Text("/")
                                        Text(day.highTemp).bold()
                                    }
                                    .foregroundStyle(.black).frame(width: 90, alignment: .trailing)
                                }
                                .padding().background(Color.white)
                                if day.id != weatherViewModel.dailyForecasts.last?.id {
                                    Divider().background(Color.gray.opacity(0.3))
                                }
                            }
                        }
                        .cornerRadius(15).padding(.horizontal)
                        .shadow(color: .black.opacity(0.3), radius: 10)
                    }
                }
                .padding(.bottom, 40)
            }

            // YELLOW BACK BUTTON
            Button {
                weatherViewModel.reset()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.yellow)
                    .padding(12).background(Color.black.opacity(0.6)).clipShape(Circle())
            }
            .padding(.leading, 20).padding(.top, 10)
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if weatherViewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    ProgressView("ANALYZING...").tint(.yellow).foregroundStyle(.yellow)
                }
            }
        }
        .onAppear { locationManager.requestLocation() }
        .onChange(of: locationManager.userLocation) { oldLocation, newLocation in
            if let location = newLocation, !hasLoadedWeather {
                hasLoadedWeather = true
                Task { await weatherViewModel.fetchWeatherByLocation(location) }
            }
        }
    }
}
