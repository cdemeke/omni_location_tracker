//
//  WeatherIntegrationView.swift
//  OmniSiteTracker
//
//  Weather-based site recommendations
//

import SwiftUI
import WeatherKit
import CoreLocation

@MainActor
@Observable
final class WeatherManager {
    var currentWeather: WeatherInfo?
    var isLoading = false
    var recommendations: [String] = []
    
    struct WeatherInfo {
        let temperature: Double
        let humidity: Double
        let condition: String
        let uvIndex: Int
    }
    
    func fetchWeather(for location: CLLocation) async {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate weather fetch
        try? await Task.sleep(for: .milliseconds(500))
        
        currentWeather = WeatherInfo(
            temperature: 72,
            humidity: 45,
            condition: "Partly Cloudy",
            uvIndex: 5
        )
        
        generateRecommendations()
    }
    
    private func generateRecommendations() {
        guard let weather = currentWeather else { return }
        
        recommendations.removeAll()
        
        if weather.humidity > 70 {
            recommendations.append("High humidity - ensure skin is dry before application")
        }
        
        if weather.temperature > 85 {
            recommendations.append("Hot weather - avoid sun-exposed sites")
        }
        
        if weather.uvIndex > 6 {
            recommendations.append("High UV - keep covered sites protected")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Current conditions are ideal for all sites")
        }
    }
}

struct WeatherIntegrationView: View {
    @State private var weatherManager = WeatherManager()
    @State private var locationManager = CLLocationManager()
    
    var body: some View {
        List {
            if weatherManager.isLoading {
                Section {
                    HStack {
                        ProgressView()
                        Text("Fetching weather...")
                    }
                }
            } else if let weather = weatherManager.currentWeather {
                Section("Current Conditions") {
                    LabeledContent("Temperature", value: "\(Int(weather.temperature))°F")
                    LabeledContent("Humidity", value: "\(Int(weather.humidity))%")
                    LabeledContent("Condition", value: weather.condition)
                    LabeledContent("UV Index", value: "\(weather.uvIndex)")
                }
                
                Section("Recommendations") {
                    ForEach(weatherManager.recommendations, id: \.self) { rec in
                        Label(rec, systemImage: "cloud.sun")
                    }
                }
            } else {
                Section {
                    Button("Get Weather-Based Recommendations") {
                        Task {
                            let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
                            await weatherManager.fetchWeather(for: location)
                        }
                    }
                }
            }
        }
        .navigationTitle("Weather & Sites")
    }
}

#Preview {
    NavigationStack {
        WeatherIntegrationView()
    }
}
