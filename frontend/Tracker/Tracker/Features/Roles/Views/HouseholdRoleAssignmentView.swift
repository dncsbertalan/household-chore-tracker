import SwiftUI

struct HouseholdRoleAssignmentView: View {
    let userId: UUID
    let onSaved: (HouseholdRolesResponse) async -> Void
    let onReload: () -> Void
    let repository: any HouseholdRoleRepositoryProtocol
    @Environment(\.dismiss) private var dismiss
    @State private var model: HouseholdRoleAssignmentViewModel
    
    init(data: HouseholdRolesResponse, member: HouseholdMember, userId: UUID,
         repository: any HouseholdRoleRepositoryProtocol,
         onSaved: @escaping (HouseholdRolesResponse) async -> Void, onReload: @escaping () -> Void) {
        self.repository = repository
        self.userId = userId; self.onSaved = onSaved; self.onReload = onReload
        _model = State(initialValue: HouseholdRoleAssignmentViewModel(data: data, member: member))
    }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("roles.assignedRole", selection: $model.selectedRoleId) {
                        ForEach(model.data.household.roles, id: \.householdRoleId) { role in
                            Text(role.name).tag(role.householdRoleId)
                        }
                    }
                    .pickerStyle(.inline)
                    .accessibilityIdentifier("memberRolePicker")
                } footer: { Text("roles.assignmentHelp") }
                if let error = model.mutation.roleError?.message {
                    Section {
                        Text(error).foregroundStyle(.red).accessibilityIdentifier("assignRoleError")
                        if model.mutation.roleError?.needsReload == true { Button("roles.reload") { dismiss(); onReload() } }
                    }
                }
            }
            .disabled(model.mutation.isPending)
            .navigationTitle("roles.assign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() }.disabled(model.mutation.isPending) }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await save()
                        }
                    } label: {
                        if model.mutation.isPending { ProgressView() } else { Text("common.save") }
                    }
                    .disabled(!model.canSave || model.mutation.isPending || model.mutation.roleError?.needsReload == true).accessibilityIdentifier("saveMemberRole")
                }
            }
        }
        .interactiveDismissDisabled(model.mutation.isPending)
    }
    private func save() async {
        if let response = await model.save(accountId: userId, using: repository) {
            await onSaved(response)
            dismiss()
        }
    }

}

#if DEBUG
#Preview("Assign member role") {
    HouseholdRoleAssignmentView(data: HouseholdRolesPreview.data, member: HouseholdRolesPreview.data.household.members[1],
        userId: HouseholdRolesPreview.accountId, repository: HouseholdRolesPreview.repository(), onSaved: { _ in }, onReload: {})
}
#endif
