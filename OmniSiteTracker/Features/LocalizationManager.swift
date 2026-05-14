//
//  LocalizationManager.swift
//  OmniSiteTracker
//
//  Multi-language support with dynamic locale switching
//

import SwiftUI

@MainActor
@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()
    
    private(set) var currentLocale: Locale = .current
    private(set) var supportedLanguages: [SupportedLanguage] = SupportedLanguage.allCases
    private(set) var currentLanguage: SupportedLanguage = .english
    
    enum SupportedLanguage: String, CaseIterable, Identifiable {
        case english = "en"
        case spanish = "es"
        case french = "fr"
        case german = "de"
        case italian = "it"
        case portuguese = "pt"
        case japanese = "ja"
        case korean = "ko"
        case chinese = "zh"
        case arabic = "ar"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            case .french: return "Français"
            case .german: return "Deutsch"
            case .italian: return "Italiano"
            case .portuguese: return "Português"
            case .japanese: return "日本語"
            case .korean: return "한국어"
            case .chinese: return "中文"
            case .arabic: return "العربية"
            }
        }
        
        var isRTL: Bool {
            self == .arabic
        }
    }
    
    private init() {
        loadSavedLanguage()
    }
    
    private func loadSavedLanguage() {
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = SupportedLanguage(rawValue: saved) {
            currentLanguage = language
            currentLocale = Locale(identifier: saved)
        }
    }
    
    func setLanguage(_ language: SupportedLanguage) {
        currentLanguage = language
        currentLocale = Locale(identifier: language.rawValue)
        UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
    }
    
    func localizedString(_ key: String, comment: String = "") -> String {
        // In production, this would load from localized bundles
        return NSLocalizedString(key, comment: comment)
    }
    
    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.dateStyle = style
        return formatter.string(from: date)
    }
    
    func formatNumber(_ number: Double, decimals: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.locale = currentLocale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

struct LanguageSettingsView: View {
    @State private var manager = LocalizationManager.shared
    
    var body: some View {
        List {
            Section("Select Language") {
                ForEach(manager.supportedLanguages) { language in
                    Button {
                        manager.setLanguage(language)
                    } label: {
                        HStack {
                            Text(language.displayName)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if manager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            
            Section("Preview") {
                LabeledContent("Date", value: manager.formatDate(Date()))
                LabeledContent("Number", value: manager.formatNumber(1234.56))
            }
        }
        .navigationTitle("Language")
        .environment(\.layoutDirection, manager.currentLanguage.isRTL ? .rightToLeft : .leftToRight)
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
