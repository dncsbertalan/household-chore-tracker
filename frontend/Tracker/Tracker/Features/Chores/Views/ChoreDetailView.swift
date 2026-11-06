import SwiftUI

struct ChoreDetailView: View {
    let choreId: UUID
    let userId: UUID
    @Environment(HouseholdStore.self) private var store
    @State private var model = ChoreDetailViewModel()
    @State private var isEditing = false
    @State private var deletion = ChoreDeletionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    private var household: Household? {
        model.chore.flatMap { store.household(id: $0.householdId) }
    }
    
    private var canEdit: Bool {
        guard !model.isActing, model.actionError == nil, let chore = model.chore, chore.isEditable, let household else { return false }
        return HouseholdAuthorizationService().hasPermission(.choreUpdate, in: household, userId: userId)
    }
    
    var body: some View {
        Group {
            if model.isLoading {
                ProgressView()
            } else if let error = model.errorMessage {
                ContentUnavailableView {
                    Label("chores.detail.title", systemImage: "checklist")
                } description: { Text(error) } actions: {
                    Button("household.retry") { Task { await reload() } }
                }
            } else if let chore = model.chore {
                details(chore)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(model.chore?.title ?? AppLocalization.string("chores.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canEdit {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isEditing = true } label: {
                        Label("chores.edit.action", systemImage: "pencil")
                    }
                    .accessibilityIdentifier("editChore")
                }
            }
        }
        .disabled(deletion.isDeleting)
        .confirmationDialog("chores.delete.confirmTitle", isPresented: $deletion.isShowingConfirmation, titleVisibility: .visible) {
            Button("chores.delete", role: .destructive) {
                Task { await deletion.confirmDeletion(accountId: userId, using: store) }
            }
            Button("common.cancel", role: .cancel) { deletion.cancelConfirmation() }
        } message: {
            if let chore = deletion.pendingChore {
                Text(String(format: AppLocalization.string(chore.pattern == .once ? "chores.delete.confirmMessage" : "chores.delete.confirmRecurringMessage"), chore.title))
            }
        }
        .onChange(of: deletion.didDelete) { _, deleted in if deleted { dismiss() } }
        .sensoryFeedback(.success, trigger: model.successRevision)
        .task { await reload() }
        .refreshable { await reload() }
        .sheet(isPresented: $isEditing) {
            if let chore = model.chore, let household {
                EditChoreView(chore: chore, household: household, userId: userId,
                              onSaved: model.didUpdate, onReload: { Task { await reload() } })
            }
        }
    }
    
    private func details(_ chore: ChoreResponse) -> some View {
        List {
            Section("chores.detail.title") {
                Text(chore.title).font(.title2.bold()).accessibilityIdentifier("choreDetailTitle")
                if let description = chore.description, !description.isEmpty {
                    Text(description).textSelection(.enabled)
                }
                if let occurrence = chore.occurrence {
                    LabeledContent("chores.detail.status", value: occurrence.occurrenceStatus.title)
                        .accessibilityIdentifier("choreCurrentStatus")
                }
                if let household { LabeledContent("chores.detail.household", value: household.name) }
            }
            lifecycleActions(chore)
            Section("chores.schedule.title") {
                LabeledContent("chores.schedule.pattern", value: chore.pattern.title)
                if let schedule = chore.schedule {
                    if let unit = schedule.recurrenceUnit {
                        LabeledContent("chores.schedule.interval", value: schedule.recurrenceInterval.formatted())
                        LabeledContent("chores.schedule.unit", value: unit.title)
                    }
                    if schedule.scheduleType == .fixed { dateRow("chores.schedule.startsAt", schedule.startsAt) }
                    LabeledContent("chores.edit.timeZone", value: schedule.timeZoneIdentifier)
                }
                if chore.pattern == .onDemand { Text("chores.schedule.onDemandHelp").foregroundStyle(.secondary) }
                if chore.pattern == .afterCompletion { Text("chores.schedule.afterCompletionHelp").foregroundStyle(.secondary) }
            }
            Section("chores.detail.defaults") {
                assignees(chore.assignedMemberIds)
                LabeledContent("chores.approvals.count", value: chore.requiredApprovalCount.formatted())
            }
            if let current = chore.occurrence {
                Section {
                    occurrenceDetails(current)
                } header: { Text("chores.detail.currentOccurrence") } footer: {
                    if !current.isEditable { Text("chores.edit.closed") }
                }
            } else {
                Section { Text("chores.detail.noOccurrence").foregroundStyle(.secondary) }
            }
            let history = (chore.occurrences ?? []).filter { $0.id != chore.occurrence?.id }
            if !history.isEmpty {
                Section("chores.detail.history") {
                    ForEach(history) { occurrence in
                        DisclosureGroup {
                            occurrenceDetails(occurrence)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(occurrence.title)
                                Text(occurrence.occurrenceStatus.title).font(.caption).foregroundStyle(.secondary)
                                if let date = ChoreTimestamp.decode(occurrence.scheduledAt ?? occurrence.createdAt) {
                                    Text(date, format: .dateTime.year().month().day().hour().minute())
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            Section("chores.detail.activity") {
                dateRow("chores.detail.createdAt", chore.createdAt)
                dateRow("chores.detail.updatedAt", chore.updatedAt)
                if let memberId = chore.createdByHouseholdMemberId {
                    LabeledContent("chores.detail.createdBy", value: memberName(memberId, index: 0))
                }
                if let memberId = chore.updatedByHouseholdMemberId {
                    LabeledContent("chores.detail.updatedBy", value: memberName(memberId, index: 0))
                }
            }
            deletionSection(chore)
        }
    }
    
    @ViewBuilder
    private func deletionSection(_ chore: ChoreResponse) -> some View {
        if let household, HouseholdAuthorizationService().hasPermission(.choreDelete, in: household, userId: userId) {
            Section {
                Button(role: .destructive) {
                    deletion.requestConfirmation(for: chore, household: household, accountId: userId)
                } label: {
                    if deletion.isDeleting { ProgressView() }
                    else { Label("chores.delete", systemImage: "trash") }
                }
                .disabled(model.isLoading || model.isActing || model.needsReload || deletion.needsReload || deletion.isDeleting)
                .accessibilityIdentifier("deleteChore")
                if let error = deletion.errorMessage {
                    Text(error).foregroundStyle(.red).accessibilityIdentifier("deleteChoreError")
                    if deletion.needsReload { Button("chores.delete.reload") { Task { await reload() } } }
                }
            } footer: { Text("chores.delete.help") }
        }
    }

    @ViewBuilder
    private func occurrenceDetails(_ occurrence: ChoreResponse.Occurrence) -> some View {
        Text(occurrence.title).font(.headline)
        if let description = occurrence.description, !description.isEmpty { Text(description) }
        LabeledContent("chores.detail.status", value: occurrence.occurrenceStatus.title)
        dateRow("chores.schedule.scheduledAt", occurrence.scheduledAt)
        dateRow("chores.schedule.deadline", occurrence.dueAt)
        assignees(occurrence.assignedMemberIds)
        LabeledContent("chores.approvals.count", value: occurrence.requiredApprovalCount.formatted())
        if let chore = model.chore {
            ForEach((chore.completions ?? []).filter { $0.choreOccurrenceId == occurrence.id }) { completion in
                VStack(alignment: .leading, spacing: 8) {
                    Text(completion.status.title).font(.headline)
                    LabeledContent("chores.completion.submittedBy", value: memberName(completion.completedByHouseholdMemberId, index: 0))
                    dateRow("chores.completion.submittedAt", completion.submittedAt)
                    dateRow("chores.completion.resolvedAt", completion.resolvedAt)
                    if completion.requiredApprovalCount > 0 {
                        LabeledContent("chores.completion.progress", value: "\(completion.approvedCount) / \(completion.requiredApprovalCount)")
                    }
                    ForEach(completion.approvals) { approval in
                        LabeledContent(memberName(approval.reviewedByHouseholdMemberId, index: 0), value: approval.decision.title)
                        dateRow("chores.completion.reviewedAt", approval.reviewedAt)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    @ViewBuilder
    private func lifecycleActions(_ chore: ChoreResponse) -> some View {
        if chore.actions?.canComplete == true || chore.actions?.canApprove == true || chore.actions?.canReject == true
            || chore.actions?.canCreateOccurrence == true || chore.pendingCompletion != nil
            || model.actionError != nil || model.successMessage != nil {
            Section {
                if let success = model.successMessage {
                    Label(success, systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                        .accessibilityIdentifier("choreActionSuccess")
                }
                if let pending = chore.pendingCompletion {
                    LabeledContent("chores.completion.progress", value: "\(pending.approvedCount) / \(pending.requiredApprovalCount)")
                        .accessibilityIdentifier("choreApprovalProgress")
                    Text("chores.completion.awaitingApproval").foregroundStyle(.secondary)
                }
                if model.isActing {
                    ProgressView("chores.completion.saving").accessibilityIdentifier("choreActionProgress")
                }
                if let actions = chore.actions {
                    if actions.canCreateOccurrence {
                        actionButton("chores.completion.start", action: .start, identifier: "startChoreOccurrence")
                    }
                    if actions.canComplete, let current = chore.occurrence {
                        actionButton("chores.completion.complete", action: .complete(current.id), identifier: "completeChoreOccurrence")
                    }
                    if let pending = chore.pendingCompletion {
                        if actions.canApprove {
                            actionButton("chores.completion.approve", action: .approve(pending.id), identifier: "approveChoreCompletion")
                        }
                        if actions.canReject {
                            actionButton("chores.completion.reject", action: .reject(pending.id), identifier: "rejectChoreCompletion", destructive: true)
                        }
                    }
                }
                if let error = model.actionError {
                    Text(error).foregroundStyle(.red).accessibilityIdentifier("choreActionError")
                    Button("chores.edit.reload") { Task { await reload() } }
                        .disabled(model.isActing)
                }
            } header: { Text("chores.completion.title") }
        }
    }
    
    private func actionButton(_ title: LocalizedStringKey, action: ChoreAction, identifier: String, destructive: Bool = false) -> some View {
        Button(title, role: destructive ? .destructive : nil) {
            Task { await model.perform(action, accountId: userId, store: store) }
        }
        .disabled(!model.canPerform(action))
        .accessibilityIdentifier(identifier)
    }
    
    @ViewBuilder
    private func assignees(_ ids: [UUID]) -> some View {
        if ids.isEmpty { Text("chores.assignees.empty").foregroundStyle(.secondary) }
        else {
            ForEach(Array(ids.enumerated()), id: \.element) { index, id in
                Label(memberName(id, index: index), systemImage: "person")
            }
        }
    }
    
    @ViewBuilder
    private func dateRow(_ title: LocalizedStringKey, _ timestamp: String?) -> some View {
        if let date = ChoreTimestamp.decode(timestamp) {
            LabeledContent(title) { Text(date, format: .dateTime.year().month().day().hour().minute()) }
        }
    }
    
    private func memberName(_ id: UUID, index: Int) -> String {
        ChoreMemberName.name(id: id, members: household?.members ?? [], userId: userId, index: index)
    }
    
    private func reload() async {
        guard !deletion.isDeleting else { return }
        await model.load(id: choreId, accountId: userId, store: store)
        if model.errorMessage == nil, model.chore != nil { deletion.didReload() }
    }
}

@MainActor
enum ChoreMemberName {
    static func name(id: UUID, members: [HouseholdMember], userId: UUID, index: Int) -> String {
        if let member = members.first(where: { $0.householdMemberId == id }) {
            if member.userInfo.userId == userId { return AppLocalization.string("chores.assignees.you") }
            if let nickname = member.nickname?.trimmingCharacters(in: .whitespacesAndNewlines), !nickname.isEmpty {
                return nickname
            }
        }
        return String(format: AppLocalization.string("chores.assignees.memberFormat"), index + 1)
    }
}
