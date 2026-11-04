import SwiftUI

struct EditChoreView: View {
    let household: HouseholdResponse
    let userId: UUID
    let onSaved: (ChoreResponse) -> Void
    let onReload: () -> Void
    @Environment(HouseholdStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var model: EditChoreViewModel

    init(chore: ChoreResponse, household: HouseholdResponse, userId: UUID,
         onSaved: @escaping (ChoreResponse) -> Void, onReload: @escaping () -> Void) {
        self.household = household
        self.userId = userId
        self.onSaved = onSaved
        self.onReload = onReload
        _model = State(initialValue: EditChoreViewModel(chore: chore))
    }

    private var canAssign: Bool {
        HouseholdAuthorizationService().hasPermission(.choreAssignMember, in: household, userId: userId)
    }
    private var members: [HouseholdResponse.Member] {
        household.members.sorted { $0.householdMemberId.uuidString < $1.householdMemberId.uuidString }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("chores.name", text: $model.title)
                        .accessibilityIdentifier("editChoreTitle")
                    TextField("chores.description", text: $model.description, axis: .vertical)
                        .lineLimit(3...6).accessibilityIdentifier("editChoreDescription")
                } header: { Text("chores.detail.title") } footer: {
                    Text("chores.edit.scope")
                }
                Section("chores.schedule.title") {
                    Picker("chores.schedule.pattern", selection: $model.pattern) {
                        ForEach(ChoreCreationPattern.allCases) { Text($0.title).tag($0) }
                    }
                    .accessibilityIdentifier("editChorePattern")
                    if model.isRecurring {
                        Stepper(value: $model.recurrenceInterval, in: 1...max(365, model.original.schedule?.recurrenceInterval ?? 1)) {
                            LabeledContent("chores.schedule.interval", value: model.recurrenceInterval.formatted())
                        }
                        Picker("chores.schedule.unit", selection: $model.recurrenceUnit) {
                            ForEach(ChoreRecurrenceUnit.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                        Picker("chores.edit.timeZone", selection: $model.timeZoneIdentifier) {
                            ForEach(Array(Set(TimeZone.knownTimeZoneIdentifiers + [model.timeZoneIdentifier])).sorted(), id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.navigationLink)
                    }
                    if model.pattern == .fixed { DatePicker("chores.schedule.startsAt", selection: $model.startsAt) }
                    if model.pattern == .afterCompletion { Text("chores.schedule.afterCompletionHelp").foregroundStyle(.secondary) }
                    if model.pattern == .onDemand { Text("chores.schedule.onDemandHelp").foregroundStyle(.secondary) }
                }
                if model.hasOccurrence {
                    Section {
                        if !model.requiresScheduledTime {
                            Toggle("chores.schedule.hasTime", isOn: $model.hasScheduledTime)
                        }
                        if model.hasScheduledTime || model.requiresScheduledTime { DatePicker("chores.schedule.scheduledAt", selection: $model.scheduledAt) }
                        Toggle("chores.schedule.hasDeadline", isOn: $model.hasDeadline)
                        if model.hasDeadline { DatePicker("chores.schedule.deadline", selection: $model.dueAt) }
                        if (model.hasScheduledTime || model.requiresScheduledTime) && model.hasDeadline && model.dueAt < model.scheduledAt {
                            Text("chores.error.schedule").foregroundStyle(.red)
                        }
                    } header: { Text("chores.detail.currentOccurrence") } footer: {
                        if model.original.occurrence == nil { Text("chores.edit.createsOccurrence") }
                        else if model.pattern == .onDemand { Text("chores.edit.keepsOccurrence") }
                    }
                }
                Section {
                    ForEach(Array(members.enumerated()), id: \.element.householdMemberId) { index, member in
                        Toggle(ChoreMemberName.name(id: member.householdMemberId, members: members, userId: userId, index: index), isOn: Binding(
                            get: { model.assignedMemberIds.contains(member.householdMemberId) },
                            set: { selected in
                                if selected { model.assignedMemberIds.insert(member.householdMemberId) }
                                else { model.assignedMemberIds.remove(member.householdMemberId) }
                            }))
                        .disabled(!canAssign)
                    }
                    let hidden = model.assignedMemberIds.subtracting(Set(members.map(\.householdMemberId)))
                    if !hidden.isEmpty {
                        LabeledContent("chores.edit.otherAssignees", value: hidden.count.formatted())
                    }
                } header: { Text("chores.assignees.title") } footer: {
                    if !canAssign { Text("chores.edit.assignmentPermission") }
                }
                Section("chores.approvals.title") {
                    Toggle("chores.approvals.required", isOn: $model.requiresApproval)
                    if model.requiresApproval {
                        Stepper(value: $model.requiredApprovalCount, in: 1...max(1, members.count, model.original.requiredApprovalCount)) {
                            LabeledContent("chores.approvals.count", value: model.requiredApprovalCount.formatted())
                        }
                    }
                }
                if let error = model.errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red).accessibilityIdentifier("editChoreError")
                        if model.needsReload {
                            Button("chores.edit.reload") { dismiss(); onReload() }
                        }
                    }
                }
            }
            .disabled(model.isSaving)
            .navigationTitle("chores.edit.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }.disabled(model.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if let response = await model.save(accountId: userId, using: store) {
                                onSaved(response)
                                dismiss()
                            }
                        }
                    } label: {
                        if model.isSaving { ProgressView() } else { Text("common.save") }
                    }
                    .disabled(!model.canSave).accessibilityIdentifier("saveChoreChanges")
                }
            }
        }
        .environment(\.timeZone, TimeZone(identifier: model.timeZoneIdentifier) ?? .current)
        .interactiveDismissDisabled(model.isSaving)
    }
}
