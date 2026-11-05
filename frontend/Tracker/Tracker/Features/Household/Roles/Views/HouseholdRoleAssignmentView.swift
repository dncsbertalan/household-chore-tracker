import SwiftUI

struct HouseholdRoleAssignmentView: View {
    let userId: UUID
    let onSaved: (HouseholdRolesResponse) -> Void
    let onReload: () -> Void
    @Environment(HouseholdStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var model: HouseholdRoleAssignmentViewModel
    
    init(data: HouseholdRolesResponse, member: HouseholdResponse.Member, userId: UUID,
         onSaved: @escaping (HouseholdRolesResponse) -> Void, onReload: @escaping () -> Void) {
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
                if let error = model.errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red).accessibilityIdentifier("assignRoleError")
                        if model.needsReload { Button("roles.reload") { dismiss(); onReload() } }
                    }
                }
            }
            .disabled(model.isSaving)
            .navigationTitle("roles.assign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() }.disabled(model.isSaving) }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if let response = await model.save(accountId: userId, using: store) { onSaved(response); dismiss() }
                        }
                    } label: {
                        if model.isSaving { ProgressView() } else { Text("common.save") }
                    }
                    .disabled(!model.canSave).accessibilityIdentifier("saveMemberRole")
                }
            }
        }
        .interactiveDismissDisabled(model.isSaving)
    }
}
