//
//  MedicalInformationView.swift
//  OmniSiteTracker
//
//  Displays medical disclaimer and citations for health information.
//  Required per App Store Review Guidelines 1.4.1.
//

import SwiftUI

/// View displaying medical disclaimer and source citations for all health-related information in the app
struct MedicalInformationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Disclaimer Section
                    disclaimerSection

                    // Site Rotation Information
                    siteRotationSection

                    // Recommended Sites Section
                    recommendedSitesSection

                    // Rest Period Section
                    restPeriodSection

                    // Lipohypertrophy Section
                    lipohypertrophySection

                    // Consult Healthcare Provider
                    consultProviderSection
                }
                .padding(20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Medical Information")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.appAccent)
                }
            }
        }
    }

    // MARK: - Disclaimer Section

    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.appWarning)
                Text("Important Disclaimer")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
            }

            Text("This app is intended as a tracking tool only and does not provide medical advice, diagnosis, or treatment. The information and recommendations in this app are based on general medical guidelines and should not replace advice from your healthcare provider.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)

            Text("Always consult with your endocrinologist, diabetes educator, or healthcare team for personalized guidance on insulin pump site management.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color.appWarning.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appWarning.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Site Rotation Section

    private var siteRotationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why Rotate Infusion Sites?")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Text("Regular rotation of insulin infusion sites is recommended to prevent lipohypertrophy (fatty lumps under the skin) and to ensure consistent insulin absorption. Using the same site repeatedly can lead to tissue changes that affect how insulin is absorbed.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)

            citationLink(
                title: "ADCES: Insulin Infusion Set Site Rotation Toolkit",
                url: "https://www.adces.org/education/danatech/insulin-pumps/pumps-in-professional-practice/insulin-infusion-set-site-rotation-toolkit"
            )

            citationLink(
                title: "NIH: Practical Issues in Continuous Subcutaneous Insulin Infusion",
                url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC3603042/"
            )
        }
        .padding(16)
        .neumorphicCard()
    }

    // MARK: - Recommended Sites Section

    private var recommendedSitesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Infusion Sites")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Text("The body locations available in this app are based on commonly recommended sites for insulin pump infusion sets. These typically include:")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)

            VStack(alignment: .leading, spacing: 8) {
                siteItem("Abdomen (avoiding 2 inches around navel)")
                siteItem("Back of upper arms")
                siteItem("Upper thighs")
                siteItem("Lower back/hip area")
            }
            .padding(.leading, 8)

            Text("Optimal sites may vary based on your pump manufacturer's guidelines and your individual needs. Consult your diabetes care team for personalized recommendations.")
                .font(.caption)
                .foregroundColor(.textMuted)
                .lineSpacing(4)

            citationLink(
                title: "ADCES: Body Placements for Insulin Pumps and Infusion Sets",
                url: "https://www.adces.org/education/danatech/insulin-pumps/insulin-pumps-101/insulin-pump-infusion-set-placements"
            )

            citationLink(
                title: "UCSF Diabetes Teaching Center: Infusion Sets",
                url: "https://diabetesteachingcenter.ucsf.edu/content/insulin-pump-infusion-sets"
            )

            citationLink(
                title: "ISPAD Clinical Practice Consensus Guidelines",
                url: "https://www.ispad.org/resources/ispad-clinical-practice-consensus-guidelines.html"
            )
        }
        .padding(16)
        .neumorphicCard()
    }

    // MARK: - Rest Period Section

    private var restPeriodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Site Rest Periods")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Text("This app uses a default minimum rest period of 18 days before suggesting the same site again. This is based on general recommendations to allow adequate healing time between uses of the same location.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)

            Text("Rest period recommendations vary in medical literature from 1-4 weeks depending on the source. You can adjust this setting based on your healthcare provider's guidance.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)

            citationLink(
                title: "ADCES: Insulin Infusion Set Site Rotation Toolkit",
                url: "https://www.adces.org/education/danatech/insulin-pumps/pumps-in-professional-practice/insulin-infusion-set-site-rotation-toolkit"
            )

            citationLink(
                title: "NIH: Practical Issues in Continuous Subcutaneous Insulin Infusion",
                url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC3603042/"
            )
        }
        .padding(16)
        .neumorphicCard()
    }

    // MARK: - Lipohypertrophy Section

    private var lipohypertrophySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About Lipohypertrophy")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Text("Lipohypertrophy is a common complication of repeated insulin injections or infusion site use. It appears as lumpy or hardened areas under the skin and can significantly impact insulin absorption, leading to unpredictable blood glucose levels.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)

            Text("Regular site rotation is one of the most effective ways to prevent lipohypertrophy. If you notice any lumps or changes at your infusion sites, consult your healthcare provider.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)

            citationLink(
                title: "NIH: Practical Issues in Continuous Subcutaneous Insulin Infusion",
                url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC3603042/"
            )

            citationLink(
                title: "ISPAD Clinical Practice Consensus Guidelines",
                url: "https://www.ispad.org/resources/ispad-clinical-practice-consensus-guidelines.html"
            )
        }
        .padding(16)
        .neumorphicCard()
    }

    // MARK: - Consult Provider Section

    private var consultProviderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "stethoscope")
                    .foregroundColor(.appAccent)
                Text("Consult Your Healthcare Team")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
            }

            Text("Your diabetes care team is the best source for personalized guidance. This app is designed to help you track and organize your site rotation, but it cannot account for your individual medical history, skin condition, activity level, or other factors that may affect site selection.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)

            Text("If you experience any issues with your infusion sites, insulin absorption, or have questions about site management, please contact your healthcare provider.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color.appAccent.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Helper Views

    private func siteItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.appAccent)
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
    }

    private func citationLink(title: String, url: String) -> some View {
        Button {
            if let linkURL = URL(string: url) {
                openURL(linkURL)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundColor(.appAccent)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.appAccent)
                    .underline()
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(.appAccent.opacity(0.7))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MedicalInformationView()
}
