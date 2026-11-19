import SwiftUI

struct CreateHouseholdInvitationView: View {
    @State private var viewModel: CreateHouseholdInvitationViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: CreateHouseholdInvitationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Email") {
                    TextField("Email address", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section {
                    Picker("Role", selection: $viewModel.selectedRoleId) {
                        ForEach(viewModel.household.roles) { role in
                            Text(role.name).tag(Optional(role.id))
                        }
                    }
                    if viewModel.household.roles.isEmpty {
                        Text("household.roles.noAvailable").foregroundStyle(.secondary)
                    }
                }
                header: {
                    //Text("Select a role")
                }
                footer: {
                    Text("Choose the role for the member you are inviting")
                }
            }
            .disabled(viewModel.isInviting)
            .navigationTitle("household.invitation.inviteMember")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Label("common.cancel", systemImage: "xmark")
                    }
                    .disabled(viewModel.isInviting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await viewModel.invite()
                            if viewModel.invitationSucceeded { dismiss() }
                        }
                    }
                    label: {
                        if viewModel.isInviting {
                            ProgressView().accessibilityLabel("Sending invitation")
                        }
                        else {
                            Image(systemName: "checkmark")
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(!viewModel.canInvite || viewModel.isInviting)
                }
            }
            .alert("Unable to invite member", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
            } message: { Text(viewModel.errorMessage ?? "") }
        }
        .interactiveDismissDisabled(viewModel.isInviting)
    }
}

#Preview {
    @Previewable @State var household: HouseholdResponse?
    
    CreateHouseholdInvitationView(viewModel: CreateHouseholdInvitationViewModel(
        household: HouseholdResponse.mockData, repository: PreviewHouseholdInvitationRepository()
    ))
}
