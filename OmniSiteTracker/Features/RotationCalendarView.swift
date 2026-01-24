//
//  RotationCalendarView.swift
//  OmniSiteTracker
//
//  Calendar view for rotation planning
//

import SwiftUI
import SwiftData

struct RotationCalendarView: View {
    @Query private var placements: [PlacementLog]
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private var calendar = Calendar.current
    
    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }
    
    private func placementsFor(_ date: Date) -> [PlacementLog] {
        placements.filter { calendar.isDate($0.placedAt, inSameDayAs: date) }
    }
    
    var body: some View {
        VStack {
            // Month header
            HStack {
                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                
                Spacer()
                
                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            
            // Weekday headers
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    CalendarDayCell(
                        date: date,
                        placements: placementsFor(date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date)
                    ) {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
            
            // Selected date details
            if !placementsFor(selectedDate).isEmpty {
                List {
                    ForEach(placementsFor(selectedDate)) { placement in
                        HStack {
                            Text(placement.site)
                                .font(.headline)
                            Spacer()
                            Text(placement.placedAt.formatted(date: .omitted, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
            
            Spacer()
        }
        .navigationTitle("Calendar")
    }
}

struct CalendarDayCell: View {
    let date: Date
    let placements: [PlacementLog]
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.body)
                
                if !placements.isEmpty {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        RotationCalendarView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
