import SwiftData
import SwiftUI

struct CreateChoreView: View {
    let userId: UUID
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var households: [LocalHousehold]
    @State private var model: CreateChoreViewModel
    @State private var path: [Step] = []
    @FocusState private var isTitleFocused: Bool

    private enum Step: Hashable {
        case schedule, assignment
    }

    init(householdId: UUID, userId: UUID) {
        self.userId = userId
        _model = State(initialValue: CreateChoreViewModel(householdId: householdId, userId: userId))
        _households = Query(filter: #Predicate<LocalHousehold> {
            $0.householdId == householdId && $0.createdByUserId == userId && $0.deletedAt == nil
        })
    }

    private var members: [LocalHouseholdMember] {
        (households.first?.householdMembers ?? [])
            .filter { $0.deletedAt == nil }
            .sorted { $0.householdMemberId.uuidString < $1.householdMemberId.uuidString }
    }

    private var availableMemberIds: Set<UUID> { Set(members.map(\.householdMemberId)) }

    var body: some View {
        NavigationStack(path: $path) {
            detailsStep
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .schedule: scheduleStep
                    case .assignment: assignmentStep
                    }
                }
        }
        .onChange(of: availableMemberIds) { _, memberIds in
            model.selectedMemberIds.formIntersection(memberIds)
            model.requiredApprovalCount = min(model.requiredApprovalCount, max(1, memberIds.count))
            if memberIds.isEmpty { model.requiresApproval = false }
        }
    }

    private var detailsStep: some View {
        Group {
            if households.first != nil {
                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "checklist")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary)

                        TextField("chores.name", text: $model.title)
                            .font(.system(size: 28, weight: .medium))
                            .multilineTextAlignment(.center)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.continue)
                            .focused($isTitleFocused)
                            .onSubmit(continueToSchedule)
                            .padding(.horizontal, 40)
                            .frame(height: 64)
                            .background {
                                Capsule().fill(Color(uiColor: .secondarySystemBackground))
                            }
                            .overlay(alignment: .trailing) {
                                if !model.title.isEmpty {
                                    Button { model.title = "" } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.tertiary)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("common.clearText")
                                    .padding(.trailing, 16)
                                }
                            }
                            .accessibilityIdentifier("choreName")

                        TextField("chores.description", text: $model.description, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                            }
                            .accessibilityIdentifier("choreDescription")

                        if !model.title.isEmpty && !model.canContinueWithDetails {
                            Text("chores.error.details")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear { isTitleFocused = true }
            } else {
                ContentUnavailableView("household.unavailable", systemImage: "house",
                                       description: Text("household.unavailableHelp"))
            }
        }
        .navigationTitle("chores.create")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            workflowToolbar(title: "household.continue",
                            isEnabled: households.first != nil && model.canContinueWithDetails,
                            action: continueToSchedule)
        }
    }

    private var scheduleStep: some View {
        Form {
            Section("chores.schedule.title") {
                Picker("chores.schedule.pattern", selection: $model.pattern) {
                    ForEach(ChoreCreationPattern.allCases) { pattern in
                        Text(pattern.title).tag(pattern)
                    }
                }
                .accessibilityIdentifier("choreSchedulePattern")

                if model.pattern == .fixed || model.pattern == .afterCompletion {
                    Stepper(value: $model.recurrenceInterval, in: 1...365) {
                        LabeledContent("chores.schedule.interval", value: model.recurrenceInterval.formatted())
                    }
                    Picker("chores.schedule.unit", selection: $model.recurrenceUnit) {
                        ForEach(ChoreRecurrenceUnit.allCases, id: \.self) { unit in
                            Text(unit.title).tag(unit)
                        }
                    }
                }
            }

            if model.pattern == .onDemand {
                Section {
                    Text("chores.schedule.onDemandHelp").foregroundStyle(.secondary)
                }
            } else {
                Section {
                    if model.pattern == .fixed {
                        DatePicker("chores.schedule.startsAt", selection: $model.scheduledAt)
                    } else {
                        Toggle("chores.schedule.hasTime", isOn: $model.hasScheduledTime)
                        if model.hasScheduledTime {
                            DatePicker("chores.schedule.scheduledAt", selection: $model.scheduledAt)
                        }
                    }
                    Toggle("chores.schedule.hasDeadline", isOn: $model.hasDeadline)
                    if model.hasDeadline {
                        DatePicker(selection: $model.dueAt) {
                            if model.pattern == .once {
                                Text("chores.schedule.deadline")
                            } else {
                                Text("chores.schedule.firstDeadline")
                            }
                        }
                    }
                } footer: {
                    if model.pattern == .afterCompletion {
                        Text("chores.schedule.afterCompletionHelp")
                    }
                }
            }

            if !model.canContinueWithSchedule {
                Section {
                    Text("chores.error.schedule").foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("chores.schedule.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            workflowToolbar(title: "household.continue", isEnabled: model.canContinueWithSchedule) {
                guard model.canContinueWithSchedule else { return }
                path.append(.assignment)
            }
        }
    }

    private var assignmentStep: some View {
        Form {
            Section {
                ForEach(Array(members.enumerated()), id: \.element.householdMemberId) { index, member in
                    Toggle(memberName(member, index: index), isOn: Binding(
                        get: { model.selectedMemberIds.contains(member.householdMemberId) },
                        set: { selected in
                            if selected {
                                model.selectedMemberIds.insert(member.householdMemberId)
                            } else {
                                model.selectedMemberIds.remove(member.householdMemberId)
                            }
                        }
                    ))
                }
                if members.isEmpty {
                    Text("chores.assignees.empty").foregroundStyle(.secondary)
                }
            } header: {
                Text("chores.assignees.title")
            } footer: {
                Text("chores.assignees.help")
            }

            Section("chores.approvals.title") {
                Toggle("chores.approvals.required", isOn: $model.requiresApproval)
                    .disabled(members.isEmpty)
                if model.requiresApproval {
                    Stepper(value: $model.requiredApprovalCount, in: 1...max(1, availableMemberIds.count)) {
                        LabeledContent("chores.approvals.count", value: model.requiredApprovalCount.formatted())
                    }
                }
            }

            if let error = model.errorMessage {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("chores.assignment.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            workflowToolbar(title: "chores.create",
                            isEnabled: households.first != nil && model.canCreate(availableMemberIds: availableMemberIds)) {
                model.create(using: LocalChoreRepository(container: context.container))
                if model.didSave { dismiss() }
            }
        }
    }

    private func memberName(_ member: LocalHouseholdMember, index: Int) -> String {
        if let nickname = member.nickname?.trimmingCharacters(in: .whitespacesAndNewlines), !nickname.isEmpty {
            return nickname
        }
        if member.userId == userId { return AppLocalization.string("chores.assignees.you") }
        return String(format: AppLocalization.string("chores.assignees.memberFormat"), index + 1)
    }

    private func continueToSchedule() {
        guard households.first != nil, model.canContinueWithDetails else { return }
        isTitleFocused = false
        path.append(.schedule)
    }

    @ToolbarContentBuilder
    private func workflowToolbar(title: LocalizedStringKey, isEnabled: Bool,
                                 action: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if path.isEmpty {
                DismissButton().accessibilityIdentifier("exitChoreCreation")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: action) { Text(title) }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(!isEnabled)
        }
    }
}

#if DEBUG
#Preview {
    let container = try! ModelContainer(for: AppSchema.schema,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let userId = UUID()
    let household = LocalHousehold(householdId: UUID(), name: "Home", createdByUserId: userId,
                                   localRevision: 1, status: .pending, householdRoles: [], householdMembers: [])
    container.mainContext.insert(household)
    let role = LocalHouseholdRole(householdRoleId: UUID(), name: "Owner", permissions: [.choreCreate],
                                  household: household, isSystemRole: false, members: [])
    container.mainContext.insert(role)
    let member = LocalHouseholdMember(householdMemberId: UUID(), userId: userId,
                                      household: household, role: role, localRevision: 1, status: .pending)
    container.mainContext.insert(member)
    return CreateChoreView(householdId: household.householdId, userId: userId)
        .modelContainer(container)
}
#endif
