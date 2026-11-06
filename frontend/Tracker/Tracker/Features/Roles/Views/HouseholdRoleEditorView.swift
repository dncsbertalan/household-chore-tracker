import SwiftUI

struct HouseholdRoleEditorView: View {
    let userId: UUID
    let onSaved: (HouseholdRolesResponse) async -> Void
    let onReload: () -> Void
    let repository: any HouseholdRoleRepositoryProtocol
    @Environment(\.dismiss) private var dismiss
    @State private var model: HouseholdRoleEditorViewModel

    init(data: HouseholdRolesResponse, role: HouseholdRole?, userId: UUID,
         repository: any HouseholdRoleRepositoryProtocol,
         onSaved: @escaping (HouseholdRolesResponse) async -> Void, onReload: @escaping () -> Void) {
        self.repository = repository
        self.userId = userId; self.onSaved = onSaved; self.onReload = onReload
        _model = State(initialValue: HouseholdRoleEditorViewModel(data: data, role: role))
    }

    private var catalog: [HouseholdPermission] {
        HouseholdPermission.allCases.filter { permission in model.data.permissions.contains { $0.name == permission } }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("household.roleName", text: $model.name)
                        .disabled(!model.isEditable)
                        .accessibilityIdentifier("householdRoleName")
                    if !model.name.isEmpty && !HouseholdConstraints.isValidRoleName(model.name) {
                        Text("household.error.roles").foregroundStyle(.red)
                    }
                } footer: {
                    if model.role?.isSystemRole == true { Text("roles.systemRole") }
                    else { Text("roles.appliesToMembers") }
                }
                if let error = model.mutation.roleError?.message {
                    Section {
                        Text(error).foregroundStyle(.red).accessibilityIdentifier("saveRoleError")
                        if model.mutation.roleError?.needsReload == true {
                            Button("roles.reload") { dismiss(); onReload() }
                        }
                    }
                }

                Section("household.permissions") {
                    ForEach(catalog) { permission in
                        Toggle(permission.title, isOn: Binding(
                            get: { model.selectedPermissions.contains(permission) },
                            set: { enabled in
                                if enabled { model.selectedPermissions.insert(permission) }
                                else { model.selectedPermissions.remove(permission) }
                            }))
                        .disabled(!model.isEditable)
                        .accessibilityIdentifier("rolePermission-\(permission.rawValue)")
                    }
                }
            }
            .disabled(model.mutation.isPending)
            .navigationTitle(model.role == nil ? "roles.create" : "roles.details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .disabled(model.mutation.isPending)
                }
                if model.isEditable {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            Task {
                                await save()
                            }
                        } label: {
                            if model.mutation.isPending { ProgressView() } else { Image(systemName: "checkmark") }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                        .disabled(!model.canSave || model.mutation.isPending || model.mutation.roleError?.needsReload == true)
                        .accessibilityIdentifier("saveHouseholdRole")
                    }
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
#Preview("Create role") {
    HouseholdRoleEditorView(data: HouseholdRolesPreview.data, role: nil,
        userId: HouseholdRolesPreview.accountId, repository: HouseholdRolesPreview.repository(), onSaved: { _ in }, onReload: {})
}

#Preview("Edit role") {
    HouseholdRoleEditorView(data: HouseholdRolesPreview.data, role: HouseholdRolesPreview.data.household.roles[1],
        userId: HouseholdRolesPreview.accountId, repository: HouseholdRolesPreview.repository(), onSaved: { _ in }, onReload: {})
}

#Preview("System role") {
    HouseholdRoleEditorView(data: HouseholdRolesPreview.data, role: HouseholdRolesPreview.data.household.roles[0],
        userId: HouseholdRolesPreview.accountId, repository: HouseholdRolesPreview.repository(), onSaved: { _ in }, onReload: {})
}
#endif
