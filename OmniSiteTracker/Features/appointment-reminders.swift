//
//  appointment-reminders.swift
//  OmniSiteTracker
//
//  Doctor appointment reminders
//

import SwiftUI

struct appointmentremindersView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Doctor appointment reminders")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This feature is coming soon!")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    appointmentremindersView()
}
