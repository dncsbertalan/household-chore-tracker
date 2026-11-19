import SwiftUI

struct ChoreDetailView: View {
    @State private var viewModel: ChoreDetailViewModel
    @Environment(AppState.self) private var appState

    init(viewModel: ChoreDetailViewModel) { _viewModel = State(initialValue: viewModel) }

    var body: some View {
        List {
            if let chore = viewModel.chore {
                if let description = chore.description, !description.isEmpty {
                    Section {
                        Text(description)
                    }
                }
                if chore.isOnDemand {
                    Section {
                        Label("On demand", systemImage: "hand.tap")
                        if chore.actions?.canCreateOccurrence == true {
                            Button {
                                Task { await viewModel.startOccurrence() }
                            } label: {
                                HStack {
                                    Text("Start occurrence")
                                    if viewModel.isStarting { ProgressView() }
                                }
                            }
                            .disabled(viewModel.isStarting || viewModel.isLoading)
                        }
                    } footer: {
                        Text("This is a reusable chore. Start an occurrence when it needs to be done.")
                    }
                }
                
                Section("Current occurrence") {
                    if let occurrence = chore.occurrence {
                        occurrenceDetails(occurrence)
                    } else {
                        Text("No occurrence started yet.").foregroundStyle(.secondary)
                    }
                }
                
                Section("Assigned members") {
                    if chore.assignedMembers.isEmpty { Text("Unassigned").foregroundStyle(.secondary) }
                    ForEach(chore.assignedMembers) { member in
                        HStack {
                            AvatarView(firstName: member.firstName, lastName: member.lastName, size: 36)
                            HouseholdMemberNameView(member: member, isCurrentUser: member.userId == appState.currentUserId)
                        }
                    }
                }
                if let history = chore.occurrences, history.count > 1 {
                    Section("Previous occurrences") {
                        ForEach(history.filter { $0.id != chore.occurrence?.id }) { occurrence in
                            VStack(alignment: .leading) { occurrenceDetails(occurrence) }
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.chore?.title ?? "Chore")
        .navigationBarTitleDisplayMode(.inline)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .overlay {
            if viewModel.isLoading && viewModel.chore == nil {
                ProgressView()
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alert("Unable to update chore", isPresented: Binding(
            get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
        } message: { Text(viewModel.errorMessage ?? "") }
    }
    
    @ViewBuilder private func occurrenceDetails(_ occurrence: ChoreResponse.Occurrence) -> some View {
        LabeledContent("Status", value: occurrence.occurrenceStatus.label)
        if let scheduled = occurrence.scheduledAt {
            LabeledContent("Scheduled", value: scheduled.formatted(date: .abbreviated, time: .shortened))
        }
        if let due = occurrence.dueAt {
            LabeledContent("Due", value: due.formatted(date: .abbreviated, time: .shortened))
        }
    }
}

#Preview {
    NavigationStack {
        ChoreDetailView(viewModel: ChoreDetailViewModel(choreId: UUID(), repository: PreviewChoreRepository()))
    }
    .environment(AppState())
}
