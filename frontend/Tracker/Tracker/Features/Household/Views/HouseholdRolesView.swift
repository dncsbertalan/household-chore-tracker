import SwiftUI

struct HouseholdRolesView: View {
    @State private var viewModel: HouseholdRolesViewModel
    init(viewModel: HouseholdRolesViewModel) { _viewModel = State(initialValue: viewModel) }

    var body: some View {
        List {
            ForEach(viewModel.roles) { role in
                NavigationLink {
                    HouseholdRoleDetailView(role: role, viewModel: viewModel)
                } label: {
                    VStack(alignment: .leading) {
                        Text(role.name).font(.headline)
                        if role.isSystemRole {
                            Text("System role")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            if viewModel.roles.isEmpty && !viewModel.isLoading && viewModel.errorMessage == nil {
                Text("No roles available.").foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Household roles")
        .scrollEdgeEffectStyle(.soft, for: .top)
        .overlay {
            if viewModel.isLoading && viewModel.roles.isEmpty {
                ProgressView()
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alert("Unable to load roles", isPresented: Binding(
            get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Retry") { Task { await viewModel.load() } }
            Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
        } message: { Text(viewModel.errorMessage ?? "") }
    }
}

#Preview {
    NavigationStack {
        HouseholdRolesView(viewModel: HouseholdRolesViewModel(
            householdId: PreviewHouseholdRepository.mockedData[0].id, repository: PreviewHouseholdRoleRepository()
        ))
    }
}
