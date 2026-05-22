//
//  GestureControlsView.swift
//  OmniSiteTracker
//
//  Custom gesture controls for quick actions
//

import SwiftUI

@MainActor
@Observable
final class GestureManager {
    var swipeLeftAction: QuickAction = .nextSite
    var swipeRightAction: QuickAction = .previousSite
    var doubleTapAction: QuickAction = .logCurrent
    var longPressAction: QuickAction = .openMenu
    
    enum QuickAction: String, CaseIterable {
        case nextSite = "Next Site"
        case previousSite = "Previous Site"
        case logCurrent = "Log Current"
        case openMenu = "Open Menu"
        case showStats = "Show Stats"
        case none = "None"
    }
    
    func save() {
        UserDefaults.standard.set(swipeLeftAction.rawValue, forKey: "swipeLeft")
        UserDefaults.standard.set(swipeRightAction.rawValue, forKey: "swipeRight")
        UserDefaults.standard.set(doubleTapAction.rawValue, forKey: "doubleTap")
        UserDefaults.standard.set(longPressAction.rawValue, forKey: "longPress")
    }
    
    func load() {
        if let left = UserDefaults.standard.string(forKey: "swipeLeft"),
           let action = QuickAction(rawValue: left) {
            swipeLeftAction = action
        }
    }
}

struct GestureControlsView: View {
    @State private var manager = GestureManager()
    
    var body: some View {
        List {
            Section("Swipe Gestures") {
                Picker("Swipe Left", selection: $manager.swipeLeftAction) {
                    ForEach(GestureManager.QuickAction.allCases, id: \.self) { action in
                        Text(action.rawValue).tag(action)
                    }
                }
                
                Picker("Swipe Right", selection: $manager.swipeRightAction) {
                    ForEach(GestureManager.QuickAction.allCases, id: \.self) { action in
                        Text(action.rawValue).tag(action)
                    }
                }
            }
            
            Section("Tap Gestures") {
                Picker("Double Tap", selection: $manager.doubleTapAction) {
                    ForEach(GestureManager.QuickAction.allCases, id: \.self) { action in
                        Text(action.rawValue).tag(action)
                    }
                }
                
                Picker("Long Press", selection: $manager.longPressAction) {
                    ForEach(GestureManager.QuickAction.allCases, id: \.self) { action in
                        Text(action.rawValue).tag(action)
                    }
                }
            }
            
            Section("Preview") {
                GesturePreviewView()
            }
        }
        .navigationTitle("Gesture Controls")
        .onChange(of: manager.swipeLeftAction) { _, _ in manager.save() }
        .onChange(of: manager.swipeRightAction) { _, _ in manager.save() }
        .onChange(of: manager.doubleTapAction) { _, _ in manager.save() }
        .onChange(of: manager.longPressAction) { _, _ in manager.save() }
    }
}

struct GesturePreviewView: View {
    @State private var lastGesture = "None"
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Try gestures here")
                .font(.headline)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(.blue.opacity(0.2))
                .frame(height: 150)
                .overlay {
                    Text(lastGesture)
                        .font(.title2)
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width < -50 {
                                lastGesture = "Swipe Left"
                            } else if value.translation.width > 50 {
                                lastGesture = "Swipe Right"
                            }
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            lastGesture = "Double Tap"
                        }
                )
                .simultaneousGesture(
                    LongPressGesture()
                        .onEnded { _ in
                            lastGesture = "Long Press"
                        }
                )
        }
        .padding(.vertical)
    }
}

#Preview {
    NavigationStack {
        GestureControlsView()
    }
}
