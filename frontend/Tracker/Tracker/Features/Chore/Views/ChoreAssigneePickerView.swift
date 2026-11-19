import SwiftUI

struct ChoreAssigneePickerView: View {
    @Bindable var viewModel: ChoreDetailViewModel
    @State private var selection: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let household = viewModel.household {
                    ForEach(household.members) { member in
                        Button {
                            if selection.contains(member.id) { selection.remove(member.id) }
                            else { selection.insert(member.id) }
                        } label: {
                            HStack {
                                HouseholdMemberNameView(member: member, isCurrentUser: member.userId == household.me.userId)
                                Spacer()
                                if selection.contains(member.id) { Image(systemName: "checkmark") }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .disabled(viewModel.isBusy)
            .navigationTitle("Assign members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Label("Cancel", systemImage: "xmark") }
                        .disabled(viewModel.isActing)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isActing { ProgressView() }
                    else {
                        Button {
                            Task { if await viewModel.assignMembers(selection) { dismiss() } }
                        } label: { Label("Save", systemImage: "checkmark") }
                        .disabled(!viewModel.canAssignMembers || viewModel.isBusy || selection == Set(viewModel.chore?.assignedMemberIds ?? []))
                    }
                }
            }
            .task { selection = Set(viewModel.chore?.assignedMemberIds ?? []) }
            .alert("Unable to assign members", isPresented: Binding(
                get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("Refresh") { Task { await viewModel.load() } }
                Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
            } message: { Text(viewModel.errorMessage ?? "") }
        }
        .interactiveDismissDisabled(viewModel.isActing)
    }
}
