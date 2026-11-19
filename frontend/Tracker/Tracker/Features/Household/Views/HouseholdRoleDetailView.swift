import SwiftUI

struct HouseholdRoleDetailView: View {
    let originalRole: HouseholdRoleResponse
    @Bindable var viewModel: HouseholdRolesViewModel
    @State private var name: String
    @State private var permissions: Set<HouseholdPermission>

    init(role: HouseholdRoleResponse, viewModel: HouseholdRolesViewModel) {
        originalRole = role
        self.viewModel = viewModel
        _name = State(initialValue: role.name)
        _permissions = State(initialValue: Set(role.permissions))
    }
    
    private var role: HouseholdRoleResponse {
        viewModel.roles.first { $0.id == originalRole.id } ?? originalRole
    }
    
    var body: some View {
        HouseholdRoleForm(name: $name, permissions: $permissions, isSystemRole: role.isSystemRole)
        .disabled(!viewModel.canEdit(role) || viewModel.isSaving)
        .navigationTitle(role.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isSaving)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isSaving { ProgressView() }
                else if viewModel.canSave(role, name: name, permissions: permissions) {
                    Button {
                        Task {
                            if await viewModel.save(role, name: name, permissions: permissions) {
                                name = self.role.name
                                permissions = Set(self.role.permissions)
                            }
                        }
                    } label: { Label("Save role", systemImage: "checkmark") }
                }
            }
        }
        .alert("Unable to save role", isPresented: Binding(
            get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Refresh") { Task {
                await viewModel.load()
                name = role.name
                permissions = Set(role.permissions)
            } }
            Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
        } message: { Text(viewModel.errorMessage ?? "") }
    }
}

#Preview {
    HouseholdRoleDetailPreview()
}

private struct HouseholdRoleDetailPreview: View {
    @State private var viewModel = HouseholdRolesViewModel(
        householdId: PreviewHouseholdRepository.mockedData[0].id,
        repository: PreviewHouseholdRoleRepository()
    )

    var body: some View {
        NavigationStack {
            if let role = viewModel.roles.first {
                HouseholdRoleDetailView(role: role, viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .task { await viewModel.load() }
    }
}
