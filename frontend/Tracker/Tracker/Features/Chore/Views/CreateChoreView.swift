import SwiftUI

struct CreateChoreView: View {
    @State private var viewModel: CreateChoreViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CreateChoreViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Form {
            // MARK: Detail section
            Section("Details") {
                TextField("Title", text: $viewModel.title)
                TextField("Description (optional)", text: $viewModel.description, axis: .vertical).lineLimit(3...6)
            }
            
            // MARK: Schedule
            Section {
                Picker("Repeat", selection: $viewModel.pattern) {
                    ForEach(ChoreCreationPattern.allCases) { Text($0.label).tag($0) }
                }
                
                if viewModel.pattern.isRecurring {
                    Stepper("Every \(viewModel.recurrenceInterval)", value: $viewModel.recurrenceInterval, in: 1...Int(Int32.max))
                    Picker("Unit", selection: $viewModel.recurrenceUnit) {
                        ForEach(ChoreRecurrenceUnit.allCases) { Text($0.label).tag($0) }
                    }
                }
                
                if viewModel.pattern != .onDemand {
                    if viewModel.pattern != .fixed {
                        Toggle("Scheduled date", isOn: $viewModel.hasScheduledDate)
                    }
                    if viewModel.pattern == .fixed || viewModel.hasScheduledDate {
                        DatePicker("Scheduled", selection: $viewModel.scheduledAt)
                    }
                    
                    Toggle("Due date", isOn: $viewModel.hasDueDate)
                    
                    if viewModel.hasDueDate { DatePicker("Due", selection: $viewModel.dueAt) }
                    if let scheduled = viewModel.request.scheduledAt, let due = viewModel.request.dueAt, due < scheduled {
                        Text("Due date must be on or after the scheduled date.").foregroundStyle(.red)
                    }
                    
                }
            }
            header: {
                Text("Schedule")
            }
            footer: {
                Text(scheduleFootnote)
            }
            
            // MARK: Assigne to members
            Section {
                ForEach(viewModel.household.members) { member in
                    Button {
                        if viewModel.assignedMemberIds.contains(member.id) {
                            viewModel.assignedMemberIds.remove(member.id)
                        } else {
                            viewModel.assignedMemberIds.insert(member.id)
                        }
                    } label: {
                        HStack {
                            HouseholdMemberNameView(member: member, isCurrentUser: member.userId == viewModel.household.me.userId)
                            
                            Spacer()
                            
                            if viewModel.assignedMemberIds.contains(member.id) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            header: {
                Text("Assign members")
            }
            footer: {
                Text("Select members of your household to assign this task to.")
            }
            
            // MARK: Approvals
            if viewModel.household.members.count > 1 {
                Section {
                    Stepper("Required approvals: \(viewModel.requiredApprovalCount)", value: $viewModel.requiredApprovalCount,
                            in: 0...viewModel.household.members.count - 1)
                }
                header: {
                    Text("Approvals")
                }
                footer: {
                    Text("The amount of approvals needed for this task to be completed.")
                }
            }
        }
        .disabled(viewModel.isCreating)
        .navigationTitle("Create chore")
        .navigationBarTitleDisplayMode(.inline)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await viewModel.create()
                        if viewModel.creationSucceeded { dismiss() }
                    }
                }
                label: {
                    if viewModel.isCreating {
                        ProgressView()
                    }
                    else {
                        Image(systemName: "checkmark")
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(!viewModel.canCreate)
                
            }
        }
        .navigationBarBackButtonHidden(viewModel.isCreating)
        .alert("Unable to create chore", isPresented: Binding(
            get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
        } message: { Text(viewModel.errorMessage ?? "") }
    }

    private var scheduleFootnote: LocalizedStringKey {
        switch viewModel.pattern {
        case .once:
            "Create a chore to complete once. You can optionally set a scheduled date and a due date."
        case .fixed:
            "Repeat at a fixed interval from the scheduled date. Completing the chore later does not shift its schedule."
        case .afterCompletion:
            "Repeat after the selected interval has passed since completion. The scheduled date and due date apply to the first occurrence."
        case .onDemand:
            "Create a reusable chore with no automatic schedule. Start a new occurrence whenever it is needed."
        }
    }
}

#Preview {
    NavigationStack {
        CreateChoreView(viewModel: CreateChoreViewModel(household: HouseholdResponse.mockData, repository: PreviewChoreRepository()))
    }
}
