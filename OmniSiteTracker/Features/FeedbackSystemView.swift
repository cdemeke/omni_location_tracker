//
//  FeedbackSystemView.swift
//  OmniSiteTracker
//
//  In-app feedback submission
//

import SwiftUI

struct FeedbackSystemView: View {
    @State private var feedbackType: FeedbackType = .suggestion
    @State private var title = ""
    @State private var description = ""
    @State private var email = ""
    @State private var includeSystemInfo = true
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    
    enum FeedbackType: String, CaseIterable {
        case bug = "Bug Report"
        case suggestion = "Feature Suggestion"
        case question = "Question"
        case praise = "Praise"
    }
    
    var body: some View {
        Form {
            Section("Type") {
                Picker("Feedback Type", selection: $feedbackType) {
                    ForEach(FeedbackType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("Details") {
                TextField("Title", text: $title)
                
                TextEditor(text: $description)
                    .frame(minHeight: 100)
            }
            
            Section("Contact (Optional)") {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
            }
            
            Section {
                Toggle("Include System Info", isOn: $includeSystemInfo)
            } footer: {
                Text("Includes iOS version, app version, and device model to help diagnose issues.")
            }
            
            Section {
                Button {
                    submitFeedback()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                        }
                        Text("Submit Feedback")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(title.isEmpty || description.isEmpty || isSubmitting)
            }
        }
        .navigationTitle("Send Feedback")
        .alert("Thank You!", isPresented: $showingSuccess) {
            Button("OK") {
                title = ""
                description = ""
            }
        } message: {
            Text("Your feedback has been submitted successfully.")
        }
    }
    
    private func submitFeedback() {
        isSubmitting = true
        
        // Simulate submission
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            showingSuccess = true
        }
    }
}

#Preview {
    NavigationStack {
        FeedbackSystemView()
    }
}
