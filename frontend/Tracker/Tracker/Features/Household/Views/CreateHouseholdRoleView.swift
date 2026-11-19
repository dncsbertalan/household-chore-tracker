import SwiftUI

struct CreateHouseholdRoleView: View {
    @Bindable var viewModel: HouseholdRolesViewModel
    @State private var name = ""
    @State private var permissions: Set<HouseholdPermission> = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HouseholdRoleForm(name: $name, permissions: $permissions)
            .disabled(!viewModel.canCreate || viewModel.isSaving)
            .navigationTitle("Create role")
            .navigationBarTitleDisplayMode(.inline)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .navigationBarBackButtonHidden(viewModel.isSaving)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving { ProgressView() }
                    else {
                        Button {
                            Task {
                                if await viewModel.create(name: name, permissions: permissions) { dismiss() }
                            }
                        } label: {
                            if viewModel.isSaving {
                                ProgressView()
                            } else {
                                Image(systemName: "checkmark")
                            }
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(!viewModel.canCreate(name: name))
                    }
                }
            }
            .alert("Unable to create role", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
            } message: { Text(viewModel.errorMessage ?? "") }
    }
}

#Preview {
    CreateHouseholdRolePreview()
}

private struct CreateHouseholdRolePreview: View {
    @State private var viewModel = HouseholdRolesViewModel(
        householdId: PreviewHouseholdRepository.mockedData[0].id, repository: PreviewHouseholdRoleRepository()
    )
    var body: some View {
        NavigationStack { CreateHouseholdRoleView(viewModel: viewModel) }
            .task { await viewModel.load() }
    }
}
