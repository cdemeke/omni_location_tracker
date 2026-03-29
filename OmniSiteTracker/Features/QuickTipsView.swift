//
//  QuickTipsView.swift
//  OmniSiteTracker
//
//  Daily tips and best practices
//

import SwiftUI

struct Tip: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let category: String
    let icon: String
}

struct QuickTipsView: View {
    @State private var currentTipIndex = 0
    @AppStorage("lastTipDate") private var lastTipDate = ""
    
    private let tips: [Tip] = [
        Tip(title: "Rotate Evenly", content: "Try to use each site an equal number of times per month for best results.", category: "Rotation", icon: "arrow.triangle.2.circlepath"),
        Tip(title: "Clean Hands First", content: "Always wash your hands before handling equipment or touching the site.", category: "Hygiene", icon: "hands.sparkles"),
        Tip(title: "Check for Redness", content: "Inspect each site before use and avoid any that show signs of irritation.", category: "Safety", icon: "eye"),
        Tip(title: "Stay Hydrated", content: "Proper hydration can improve site absorption and healing.", category: "Health", icon: "drop"),
        Tip(title: "Document Changes", content: "Take photos of any unusual reactions to discuss with your healthcare provider.", category: "Tracking", icon: "camera"),
        Tip(title: "Room Temperature", content: "Let equipment reach room temperature before use for better comfort.", category: "Comfort", icon: "thermometer.medium"),
        Tip(title: "Regular Check-ins", content: "Schedule regular appointments to review your rotation patterns with your doctor.", category: "Healthcare", icon: "calendar.badge.clock")
    ]
    
    private var tipOfTheDay: Tip {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        if lastTipDate != today {
            currentTipIndex = Int.random(in: 0..<tips.count)
            lastTipDate = today
        }
        
        return tips[currentTipIndex]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Tip of the Day
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text("Tip of the Day")
                            .font(.headline)
                    }
                    
                    VStack(spacing: 12) {
                        Image(systemName: tipOfTheDay.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(.blue)
                        
                        Text(tipOfTheDay.title)
                            .font(.title3)
                            .bold()
                        
                        Text(tipOfTheDay.content)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
                
                // All Tips
                VStack(alignment: .leading, spacing: 16) {
                    Text("All Tips")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(tips) { tip in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: tip.icon)
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tip.title)
                                    .font(.headline)
                                
                                Text(tip.content)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text(tip.category)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.secondary.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("Quick Tips")
    }
}

#Preview {
    NavigationStack {
        QuickTipsView()
    }
}
