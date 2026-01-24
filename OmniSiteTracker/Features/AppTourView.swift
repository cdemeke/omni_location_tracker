//
//  AppTourView.swift
//  OmniSiteTracker
//
//  Guided app tour for new users
//

import SwiftUI

struct TourStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let highlightElement: String?
}

struct AppTourView: View {
    @State private var currentStep = 0
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenTour") private var hasSeenTour = false
    
    private let steps: [TourStep] = [
        TourStep(
            title: "Log Your Sites",
            description: "Tap the + button to log each site placement quickly and easily",
            imageName: "plus.circle.fill",
            highlightElement: "addButton"
        ),
        TourStep(
            title: "View Your History",
            description: "See your complete placement history and track patterns over time",
            imageName: "clock.fill",
            highlightElement: "historyTab"
        ),
        TourStep(
            title: "Get Smart Suggestions",
            description: "The app learns your patterns and suggests optimal rotation sites",
            imageName: "lightbulb.fill",
            highlightElement: "suggestionsCard"
        ),
        TourStep(
            title: "Set Reminders",
            description: "Never forget a site change with customizable notifications",
            imageName: "bell.fill",
            highlightElement: "reminderSettings"
        ),
        TourStep(
            title: "Track Your Progress",
            description: "Celebrate achievements and maintain your logging streak",
            imageName: "chart.line.uptrend.xyaxis",
            highlightElement: "statsView"
        )
    ]
    
    var body: some View {
        VStack {
            // Progress indicator
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStep ? Color.blue : Color.secondary.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding()
            
            Spacer()
            
            // Content
            VStack(spacing: 32) {
                Image(systemName: steps[currentStep].imageName)
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                
                Text(steps[currentStep].title)
                    .font(.title)
                    .bold()
                
                Text(steps[currentStep].description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if currentStep < steps.count - 1 {
                    Button("Next") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        hasSeenTour = true
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }
}

#Preview {
    AppTourView()
}
