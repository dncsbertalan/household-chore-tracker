import SwiftUI

struct HouseholdMemberRolePickerView: View {
    @Bindable var viewModel: HouseholdMemberDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRoleId: UUID?
    
    private var selectedRole: HouseholdRoleResponse? {
        viewModel.roles.first { $0.id == selectedRoleId }
    }
    
    var body: some View {
        List {
            Section {
                if !viewModel.canAssignRole {
                    Text("You don’t have permission to change member roles.")
                } else {
                    ForEach(viewModel.roles) { role in
                        Button {
                            selectedRoleId = role.id
                        } label: {
                            HStack {
                                Text(role.name)
                                Spacer()
                                if role.id == selectedRoleId {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                        .disabled(viewModel.isSaving || viewModel.isLoading)
                    }
                }
            }
            footer: {
                Text("household.changeRole.footer")
            }
        }
        .navigationTitle("household.changeRole")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                }
                label: {
                    Label("common.cancel", systemImage: "xmark")
                }
                .disabled(viewModel.isSaving)
            }
            
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button {
                        guard let role = selectedRole else { return }
                        Task {
                            if await viewModel.assign(role) { dismiss() }
                        }
                    } label: {
                        Label("Save role", systemImage: "checkmark")
                    }
                    .disabled(!viewModel.canAssignRole || viewModel.isLoading || selectedRole == nil
                              || selectedRoleId == viewModel.member.householdRole.id)
                }
            }
        }
        .refreshable { await viewModel.load() }
        .alert("Unable to update role", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
        } message: { Text(viewModel.errorMessage ?? "") }
            .task {
                selectedRoleId = viewModel.member.householdRole.id
                await viewModel.load()
                selectedRoleId = viewModel.member.householdRole.id
            }
            .navigationBarBackButtonHidden()
            .disabled(viewModel.isSaving)
            .interactiveDismissDisabled(viewModel.isSaving)
    }
}

#Preview {
    NavigationStack {
        HouseholdMemberRolePickerView(viewModel: HouseholdMemberDetailViewModel(
            member: PreviewHouseholdRepository.mockedData[0].members[0],
            repository: RolePickerPreviewRepository()
        ))
    }
}

private actor RolePickerPreviewRepository: HouseholdRepositoryProtocol {
    private let sample = PreviewHouseholdRepository.mockedData[0]
    private var selectedRoleId: UUID?
    private let memberRoleId = UUID()
    
    func get(householdId: UUID) async throws -> HouseholdResponse {
        let original = sample.members[0]
        let ownerRole = HouseholdRoleResponse(
            householdRoleId: original.householdRole.id, householdId: sample.id, name: "Owner", isSystemRole: false,
            permissions: HouseholdPermission.allCases,
            createdAt: .now, updatedAt: .now, version: 1
        )
        let memberRole = HouseholdRoleResponse(
            householdRoleId: memberRoleId, householdId: sample.id, name: "Member", isSystemRole: false,
            permissions: [], createdAt: .now, updatedAt: .now, version: 1
        )
        let member = HouseholdMemberResponse(
            householdMemberId: original.id, householdId: sample.id, userId: original.userId,
            email: original.email, firstName: original.firstName, lastName: original.lastName, nickname: original.nickname,
            householdRole: selectedRoleId == memberRoleId ? memberRole : ownerRole,
            joinedAt: original.joinedAt, createdAt: original.createdAt, updatedAt: .now, version: 1
        )
        return HouseholdResponse(householdId: sample.id, name: sample.name, description: sample.description,
                                 members: [member], roles: [ownerRole, memberRole], owner: member, me: member, createdAt: .now)
    }
    
    func assignRole(householdId: UUID, memberId: UUID, request: AssignHouseholdRoleRequest, idempotencyKey: UUID) async throws -> HouseholdResponse {
        selectedRoleId = request.roleId
        return try await get(householdId: householdId)
    }
    
    func updateNickname(householdId: UUID, memberId: UUID, request: UpdateMemberNicknameRequest, idempotencyKey: UUID) async throws -> HouseholdMemberResponse {
        try await PreviewHouseholdRepository().updateNickname(householdId: householdId, memberId: memberId, request: request, idempotencyKey: idempotencyKey)
    }

    func create(_ request: CreateHouseholdRequest, idempotencyKey: UUID) async throws {}
    
    func getSummaries() async throws -> [HouseholdSummaryResponse] { [sample] }
}
