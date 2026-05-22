//
//  AppLockView.swift
//  OmniSiteTracker
//
//  Lock screen with biometric/PIN protection
//

import SwiftUI
import LocalAuthentication

@MainActor
@Observable
final class AppLockManager {
    var isLocked = false
    var isEnabled = false
    var lockTimeout: Int = 0 // 0 = immediate
    private var lastActiveTime: Date?
    
    func lock() {
        isLocked = true
    }
    
    func unlock() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock OmniSite Tracker"
            )
            if success {
                isLocked = false
            }
            return success
        } catch {
            return false
        }
    }
    
    func checkLock() {
        guard isEnabled else { return }
        
        if let lastActive = lastActiveTime {
            let elapsed = Date().timeIntervalSince(lastActive)
            if elapsed > Double(lockTimeout * 60) {
                lock()
            }
        }
    }
    
    func updateActivity() {
        lastActiveTime = Date()
    }
}

struct AppLockView: View {
    @State private var manager = AppLockManager()
    @State private var unlockFailed = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("OmniSite Tracker")
                .font(.title)
                .bold()
            
            Text("Unlock to continue")
                .foregroundStyle(.secondary)
            
            Button {
                Task {
                    let success = await manager.unlock()
                    unlockFailed = !success
                }
            } label: {
                Label("Unlock", systemImage: "faceid")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            
            if unlockFailed {
                Text("Authentication failed")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            
            Spacer()
        }
    }
}

struct AppLockSettingsView: View {
    @State private var manager = AppLockManager()
    
    private let timeoutOptions = [
        (0, "Immediately"),
        (1, "After 1 minute"),
        (5, "After 5 minutes"),
        (15, "After 15 minutes")
    ]
    
    var body: some View {
        List {
            Section {
                Toggle("Enable App Lock", isOn: $manager.isEnabled)
            }
            
            if manager.isEnabled {
                Section("Lock Timeout") {
                    ForEach(timeoutOptions, id: \.0) { option in
                        Button {
                            manager.lockTimeout = option.0
                        } label: {
                            HStack {
                                Text(option.1)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if manager.lockTimeout == option.0 {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("App Lock")
    }
}

#Preview {
    AppLockView()
}
