import SwiftUI

struct ChoreDetailView: View {
    let choreId: UUID
    let userId: UUID
    @Environment(HouseholdStore.self) private var store
    @State private var model = ChoreDetailViewModel()
    @State private var isEditing = false

    private var household: HouseholdResponse? {
        model.chore.flatMap { store.household(id: $0.householdId) }
    }

    private var canEdit: Bool {
        guard let chore = model.chore, chore.isEditable, let household else { return false }
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

    private func reload() async { await model.load(id: choreId, accountId: userId, store: store) }
}

@MainActor
enum ChoreMemberName {
    static func name(id: UUID, members: [HouseholdResponse.Member], userId: UUID, index: Int) -> String {
        if let member = members.first(where: { $0.householdMemberId == id }) {
            if let nickname = member.nickname?.trimmingCharacters(in: .whitespacesAndNewlines), !nickname.isEmpty { return nickname }
            if member.userId == userId { return AppLocalization.string("chores.assignees.you") }
        }
        return String(format: AppLocalization.string("chores.assignees.memberFormat"), index + 1)
    }
}
