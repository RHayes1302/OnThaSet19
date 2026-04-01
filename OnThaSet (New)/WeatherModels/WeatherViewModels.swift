//
//  WeatherViewModels.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/16/26.
//

import SwiftUI
import CoreLocation

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var cityName: String = ""
    @Published var dailyForecasts: [DayForecast] = []
    @Published var isLoading: Bool = false
    @Published var rideSafetyMessage: String = ""
    @Published var rideSafetyColor: Color = .green
    @Published var errorMessage: String = ""

    // REAL-TIME current conditions
    @Published var currentTemp: String = ""
    @Published var currentWindSpeed: String = ""
    @Published var currentWeatherCode: Int = 0

    func searchWeather() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        self.isLoading = true
        self.errorMessage = ""

        let encodedCity = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let geocodingURL = "https://geocoding-api.open-meteo.com/v1/search?name=\(encodedCity)&count=1"

        do {
            guard let gUrl = URL(string: geocodingURL) else { self.isLoading = false; return }
            let (gData, _) = try await URLSession.shared.data(from: gUrl)
            let gResult = try JSONDecoder().decode(GeocodingResponse.self, from: gData)

            if let location = gResult.results?.first {
                await fetchWeatherData(lat: location.latitude, lng: location.longitude, name: location.name)
            } else {
                self.errorMessage = "Location not found"
            }
        } catch {
            self.errorMessage = "Failed to load weather"
        }

        self.isLoading = false
    }

    func searchWeatherByCoordinates(latitude: Double, longitude: Double, locationName: String) async {
        self.isLoading = true
        self.errorMessage = ""
        await fetchWeatherData(lat: latitude, lng: longitude, name: locationName)
        self.isLoading = false
    }

    func fetchWeatherByLocation(_ location: CLLocation) async {
        self.isLoading = true
        self.errorMessage = ""
        let geocoder = CLGeocoder()
        var cityLabel = "Your Location"
        if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
            cityLabel = placemark.locality ?? placemark.administrativeArea ?? "Your Location"
        }
        await fetchWeatherData(lat: location.coordinate.latitude, lng: location.coordinate.longitude, name: cityLabel)
        self.isLoading = false
    }

    private func fetchWeatherData(lat: Double, lng: Double, name: String) async {
        let weatherURL = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lng)&current_weather=true&daily=weathercode,temperature_2m_max,temperature_2m_min&timezone=auto&temperature_unit=fahrenheit&windspeed_unit=mph"

        do {
            guard let wUrl = URL(string: weatherURL) else { return }
            let (wData, _) = try await URLSession.shared.data(from: wUrl)
            let wResult = try JSONDecoder().decode(ForecastResponse.self, from: wData)
            self.parseWeather(wResult, name: name)
        } catch {
            self.errorMessage = "Failed to load weather"
        }
    }

    private func parseWeather(_ result: ForecastResponse, name: String) {
        self.cityName = name

        // REAL-TIME current conditions
        let current = result.current_weather
        self.currentTemp = "\(Int(current.temperature))°F"
        self.currentWindSpeed = "\(Int(current.windspeed)) mph"
        self.currentWeatherCode = current.weathercode

        // Ride Safety
        if current.windspeed > 20 {
            rideSafetyMessage = "DANGEROUS WINDS: HIGH RISK"
            rideSafetyColor = .red
        } else if current.windspeed > 12 {
            rideSafetyMessage = "CAUTION: STICKY CONDITIONS"
            rideSafetyColor = .yellow
        } else {
            rideSafetyMessage = "CLEAR TO RIDE: OPTIMAL"
            rideSafetyColor = .green
        }

        var forecasts: [DayForecast] = []
        for i in 0..<result.daily.time.count {
            forecasts.append(DayForecast(
                day: i == 0 ? "TODAY" : formatDate(result.daily.time[i]),
                highTemp: "\(Int(result.daily.temperature_2m_max[i]))°F",
                lowTemp: "\(Int(result.daily.temperature_2m_min[i]))°F",
                iconName: mapWeatherCode(result.daily.weathercode[i])
            ))
        }
        self.dailyForecasts = forecasts
    }

    private func formatDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    func mapWeatherCode(_ code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2, 3: return "cloud.sun.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...77: return "cloud.rain.fill"
        case 80...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }

    func reset() {
        cityName = ""
        searchText = ""
        dailyForecasts = []
        rideSafetyMessage = ""
        rideSafetyColor = .green
        errorMessage = ""
        currentTemp = ""
        currentWindSpeed = ""
        currentWeatherCode = 0
    }
}
