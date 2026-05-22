//
//  AppCustomizationView.swift
//  OmniSiteTracker
//
//  Customize app appearance and behavior
//

import SwiftUI

@MainActor
@Observable
final class AppCustomization {
    var accentColor: String = "blue"
    var iconStyle: IconStyle = .filled
    var listDensity: ListDensity = .normal
    var showAnimations = true
    var hapticFeedback = true
    var startScreen: StartScreen = .home
    
    enum IconStyle: String, CaseIterable {
        case filled = "Filled"
        case outlined = "Outlined"
        case monochrome = "Monochrome"
    }
    
    enum ListDensity: String, CaseIterable {
        case compact = "Compact"
        case normal = "Normal"
        case comfortable = "Comfortable"
    }
    
    enum StartScreen: String, CaseIterable {
        case home = "Home"
        case log = "Quick Log"
        case history = "History"
        case calendar = "Calendar"
    }
}

struct AppCustomizationView: View {
    @State private var customization = AppCustomization()
    
    private let accentColors = ["blue", "green", "orange", "purple", "pink", "red"]
    
    var body: some View {
        List {
            Section("Accent Color") {
                HStack(spacing: 12) {
                    ForEach(accentColors, id: \.self) { color in
                        Circle()
                            .fill(colorFor(color))
                            .frame(width: 36, height: 36)
                            .overlay {
                                if customization.accentColor == color {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.white)
                                }
                            }
                            .onTapGesture {
                                customization.accentColor = color
                            }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Icons") {
                Picker("Icon Style", selection: $customization.iconStyle) {
                    ForEach(AppCustomization.IconStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
            }
            
            Section("Layout") {
                Picker("List Density", selection: $customization.listDensity) {
                    ForEach(AppCustomization.ListDensity.allCases, id: \.self) { density in
                        Text(density.rawValue).tag(density)
                    }
                }
            }
            
            Section("Behavior") {
                Toggle("Show Animations", isOn: $customization.showAnimations)
                Toggle("Haptic Feedback", isOn: $customization.hapticFeedback)
                
                Picker("Start Screen", selection: $customization.startScreen) {
                    ForEach(AppCustomization.StartScreen.allCases, id: \.self) { screen in
                        Text(screen.rawValue).tag(screen)
                    }
                }
            }
            
            Section {
                Button("Reset to Defaults") {
                    customization = AppCustomization()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Customization")
    }
    
    private func colorFor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        default: return .blue
        }
    }
}

#Preview {
    NavigationStack {
        AppCustomizationView()
    }
}
