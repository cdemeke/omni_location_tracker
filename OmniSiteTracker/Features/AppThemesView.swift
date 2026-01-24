//
//  AppThemesView.swift
//  OmniSiteTracker
//
//  Theme customization options
//

import SwiftUI

struct AppTheme: Identifiable {
    let id = UUID()
    let name: String
    let primaryColor: Color
    let secondaryColor: Color
    let backgroundColor: Color
    let isPremium: Bool
}

@MainActor
@Observable
final class ThemeManager {
    var currentTheme: AppTheme
    var useSystemAppearance = true
    var prefersDarkMode = false
    
    let availableThemes: [AppTheme] = [
        AppTheme(name: "Default", primaryColor: .blue, secondaryColor: .secondary, backgroundColor: .clear, isPremium: false),
        AppTheme(name: "Ocean", primaryColor: .cyan, secondaryColor: .teal, backgroundColor: .clear, isPremium: false),
        AppTheme(name: "Forest", primaryColor: .green, secondaryColor: .mint, backgroundColor: .clear, isPremium: false),
        AppTheme(name: "Sunset", primaryColor: .orange, secondaryColor: .red, backgroundColor: .clear, isPremium: false),
        AppTheme(name: "Lavender", primaryColor: .purple, secondaryColor: .indigo, backgroundColor: .clear, isPremium: true),
        AppTheme(name: "Rose", primaryColor: .pink, secondaryColor: .red, backgroundColor: .clear, isPremium: true)
    ]
    
    init() {
        currentTheme = availableThemes[0]
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }
}

struct AppThemesView: View {
    @State private var manager = ThemeManager()
    
    var body: some View {
        List {
            Section("Appearance") {
                Toggle("Use System Appearance", isOn: $manager.useSystemAppearance)
                
                if !manager.useSystemAppearance {
                    Toggle("Dark Mode", isOn: $manager.prefersDarkMode)
                }
            }
            
            Section("Color Theme") {
                ForEach(manager.availableThemes) { theme in
                    Button {
                        if !theme.isPremium {
                            manager.setTheme(theme)
                        }
                    } label: {
                        HStack {
                            Circle()
                                .fill(theme.primaryColor)
                                .frame(width: 30, height: 30)
                            
                            Text(theme.name)
                                .foregroundStyle(.primary)
                            
                            if theme.isPremium {
                                Text("PRO")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.yellow)
                                    .foregroundStyle(.black)
                                    .clipShape(Capsule())
                            }
                            
                            Spacer()
                            
                            if manager.currentTheme.id == theme.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            
            Section("Preview") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Primary")
                        Spacer()
                        RoundedRectangle(cornerRadius: 8)
                            .fill(manager.currentTheme.primaryColor)
                            .frame(width: 60, height: 30)
                    }
                    
                    HStack {
                        Text("Secondary")
                        Spacer()
                        RoundedRectangle(cornerRadius: 8)
                            .fill(manager.currentTheme.secondaryColor)
                            .frame(width: 60, height: 30)
                    }
                    
                    Button("Sample Button") {}
                        .buttonStyle(.borderedProminent)
                        .tint(manager.currentTheme.primaryColor)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Themes")
    }
}

#Preview {
    NavigationStack {
        AppThemesView()
    }
}
