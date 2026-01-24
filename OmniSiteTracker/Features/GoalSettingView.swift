//
//  GoalSettingView.swift
//  OmniSiteTracker
//
//  Set and track rotation goals
//

import SwiftUI
import SwiftData

@Model
final class RotationGoal {
    var id: UUID
    var title: String
    var targetValue: Int
    var currentValue: Int
    var goalType: String
    var deadline: Date?
    var isCompleted: Bool
    var createdAt: Date
    
    init(title: String, targetValue: Int, goalType: String, deadline: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.targetValue = targetValue
        self.currentValue = 0
        self.goalType = goalType
        self.deadline = deadline
        self.isCompleted = false
        self.createdAt = Date()
    }
    
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return Double(currentValue) / Double(targetValue)
    }
}

struct GoalSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RotationGoal.createdAt, order: .reverse) private var goals: [RotationGoal]
    @State private var showingAddGoal = false
    
    var body: some View {
        List {
            Section {
                Button {
                    showingAddGoal = true
                } label: {
                    Label("Add Goal", systemImage: "plus.circle.fill")
                }
            }
            
            Section("Active Goals") {
                ForEach(goals.filter { !$0.isCompleted }) { goal in
                    GoalRow(goal: goal)
                }
            }
            
            if goals.contains(where: { $0.isCompleted }) {
                Section("Completed") {
                    ForEach(goals.filter { $0.isCompleted }) { goal in
                        GoalRow(goal: goal)
                    }
                }
            }
        }
        .navigationTitle("Goals")
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView()
        }
    }
}

struct GoalRow: View {
    @Bindable var goal: RotationGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                    .strikethrough(goal.isCompleted)
                
                Spacer()
                
                Button {
                    goal.isCompleted.toggle()
                } label: {
                    Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(goal.isCompleted ? .green : .secondary)
                }
            }
            
            ProgressView(value: goal.progress)
                .tint(goal.progress >= 1 ? .green : .blue)
            
            HStack {
                Text("\(goal.currentValue)/\(goal.targetValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let deadline = goal.deadline {
                    Text("Due: \(deadline.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var targetValue = 10
    @State private var goalType = "placements"
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(7*24*60*60)
    
    private let goalTypes = ["placements", "streak", "sites"]
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Goal Title", text: $title)
                
                Stepper("Target: \(targetValue)", value: $targetValue, in: 1...100)
                
                Picker("Goal Type", selection: $goalType) {
                    Text("Placements").tag("placements")
                    Text("Streak Days").tag("streak")
                    Text("Unique Sites").tag("sites")
                }
                
                Toggle("Set Deadline", isOn: $hasDeadline)
                
                if hasDeadline {
                    DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let goal = RotationGoal(
                            title: title,
                            targetValue: targetValue,
                            goalType: goalType,
                            deadline: hasDeadline ? deadline : nil
                        )
                        modelContext.insert(goal)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        GoalSettingView()
    }
    .modelContainer(for: RotationGoal.self, inMemory: true)
}
