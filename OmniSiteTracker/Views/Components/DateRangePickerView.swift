//
//  DateRangePickerView.swift
//  OmniSiteTracker
//
//  A date range picker component with preset buttons and custom date selection.
//

import SwiftUI

/// Date range picker with preset options and custom date selection
struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date

    @State private var showCustomDates = false

    private let today = Date()

    var body: some View {
        VStack(spacing: 16) {
            // Preset buttons
            presetButtonsRow

            // Custom date pickers (expandable)
            if showCustomDates {
                customDatePickers
            }

            // Toggle custom dates button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCustomDates.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showCustomDates ? "chevron.up" : "chevron.down")
                        .font(.caption)
                    Text(showCustomDates ? "Hide Custom Dates" : "Custom Date Range")
                        .font(.subheadline)
                }
                .foregroundColor(.textSecondary)
            }
        }
        .padding(16)
        .neumorphicCard()
    }

    // MARK: - Preset Buttons

    private var presetButtonsRow: some View {
        HStack(spacing: 8) {
            PresetButton(title: "7 days", isSelected: isLast7DaysSelected) {
                selectPreset(days: 7)
            }
            PresetButton(title: "30 days", isSelected: isLast30DaysSelected) {
                selectPreset(days: 30)
            }
            PresetButton(title: "90 days", isSelected: isLast90DaysSelected) {
                selectPreset(days: 90)
            }
            PresetButton(title: "All time", isSelected: isAllTimeSelected) {
                selectAllTime()
            }
        }
    }

    // MARK: - Custom Date Pickers

    private var customDatePickers: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Start")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .frame(width: 50, alignment: .leading)

                DatePicker(
                    "",
                    selection: $startDate,
                    in: ...min(endDate, today),
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
            }

            HStack {
                Text("End")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .frame(width: 50, alignment: .leading)

                DatePicker(
                    "",
                    selection: $endDate,
                    in: startDate...today,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Preset Selection Logic

    private func selectPreset(days: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            endDate = Calendar.current.startOfDay(for: today)
            startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        }
    }

    private func selectAllTime() {
        withAnimation(.easeInOut(duration: 0.2)) {
            endDate = Calendar.current.startOfDay(for: today)
            // Set to a far past date to represent "all time"
            startDate = Calendar.current.date(byAdding: .year, value: -10, to: endDate) ?? endDate
        }
    }

    // MARK: - Selection State Checks

    private var isLast7DaysSelected: Bool {
        let expectedStart = Calendar.current.date(byAdding: .day, value: -7, to: Calendar.current.startOfDay(for: today))
        return Calendar.current.isDate(startDate, inSameDayAs: expectedStart ?? today) &&
               Calendar.current.isDate(endDate, inSameDayAs: today)
    }

    private var isLast30DaysSelected: Bool {
        let expectedStart = Calendar.current.date(byAdding: .day, value: -30, to: Calendar.current.startOfDay(for: today))
        return Calendar.current.isDate(startDate, inSameDayAs: expectedStart ?? today) &&
               Calendar.current.isDate(endDate, inSameDayAs: today)
    }

    private var isLast90DaysSelected: Bool {
        let expectedStart = Calendar.current.date(byAdding: .day, value: -90, to: Calendar.current.startOfDay(for: today))
        return Calendar.current.isDate(startDate, inSameDayAs: expectedStart ?? today) &&
               Calendar.current.isDate(endDate, inSameDayAs: today)
    }

    private var isAllTimeSelected: Bool {
        // Consider "All time" selected if start date is more than 5 years ago
        let fiveYearsAgo = Calendar.current.date(byAdding: .year, value: -5, to: today)
        return startDate < (fiveYearsAgo ?? today) &&
               Calendar.current.isDate(endDate, inSameDayAs: today)
    }
}

// MARK: - Preset Button Component

private struct PresetButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color.appAccent, Color.appAccent.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                : AnyShapeStyle(Color.appBackgroundSecondary)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        DateRangePickerView(
            startDate: .constant(Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()),
            endDate: .constant(Date())
        )
        .padding()
    }
    .background(WarmGradientBackground())
}
