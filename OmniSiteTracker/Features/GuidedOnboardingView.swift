//
//  GuidedOnboardingView.swift
//  OmniSiteTracker
//
//  Interactive onboarding experience
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let backgroundColor: Color
}

struct GuidedOnboardingView: View {
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to OmniSite",
            description: "Track and optimize your site rotation for better outcomes",
            imageName: "figure.wave",
            backgroundColor: .blue
        ),
        OnboardingPage(
            title: "Smart Rotation",
            description: "Get intelligent suggestions based on your history and healing patterns",
            imageName: "arrow.triangle.2.circlepath",
            backgroundColor: .green
        ),
        OnboardingPage(
            title: "Track Symptoms",
            description: "Log any symptoms and see correlations with specific sites",
            imageName: "heart.text.square",
            backgroundColor: .orange
        ),
        OnboardingPage(
            title: "Stay on Schedule",
            description: "Reminders and notifications keep you on track",
            imageName: "bell.badge",
            backgroundColor: .purple
        )
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    VStack(spacing: 32) {
                        Spacer()
                        
                        Image(systemName: page.imageName)
                            .font(.system(size: 100))
                            .foregroundStyle(.white)
                        
                        Text(page.title)
                            .font(.title)
                            .bold()
                            .foregroundStyle(.white)
                        
                        Text(page.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 32)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(page.backgroundColor.gradient)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        hasCompletedOnboarding = true
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }
}

struct OnboardingTipView: View {
    let title: String
    let message: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Got it", action: action)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .padding()
    }
}

#Preview {
    GuidedOnboardingView()
}
