import SwiftUI

struct HouseholdRoleEditorView: View {
    let userId: UUID
    let onSaved: (HouseholdRolesResponse) -> Void
    let onReload: () -> Void
    @Environment(HouseholdStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var model: HouseholdRoleEditorViewModel

    init(data: HouseholdRolesResponse, role: HouseholdResponse.Role?, userId: UUID,
         onSaved: @escaping (HouseholdRolesResponse) -> Void, onReload: @escaping () -> Void) {
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
                if let error = model.errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red).accessibilityIdentifier("saveRoleError")
                        if model.needsReload {
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
            .disabled(model.isSaving)
            .navigationTitle(model.role == nil ? "roles.create" : "roles.details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }.disabled(model.isSaving)
                }
                if model.isEditable {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            Task {
                                if let response = await model.save(accountId: userId, using: store) {
                                    onSaved(response); dismiss()
                                }
                            }
                        } label: {
                            if model.isSaving { ProgressView() } else { Text("common.save") }
                        }
                        .disabled(!model.canSave)
                        .accessibilityIdentifier("saveHouseholdRole")
                    }
                }
            }
        }
        .interactiveDismissDisabled(model.isSaving)
    }
}
