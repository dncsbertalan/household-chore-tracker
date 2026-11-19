//
//  HouseholdMemberDetailView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 19..
//

import SwiftUI

struct HouseholdMemberDetailView: View {
    @Environment(\.container) private var container
    @State private var showsNicknameEditor = false
    @State private var viewModel: HouseholdMemberDetailViewModel
    private var member: HouseholdMemberResponse { viewModel.member }
    let isCurrentUser: Bool
    
    init(member: HouseholdMemberResponse, isCurrentUser: Bool, repository: any HouseholdRepositoryProtocol) {
        self.isCurrentUser = isCurrentUser
        _viewModel = State(initialValue: HouseholdMemberDetailViewModel(member: member, repository: repository))
    }
    
    var body: some View {
        List {
            // MARK: Name and profile pic
            Section {
                VStack(spacing: Theme.Spacing.lg) {
                    AvatarView(firstName: member.firstName, lastName: member.lastName, size: 104)
                    HouseholdMemberNameView(member: member, isCurrentUser: isCurrentUser,
                                            font: .title.bold(), alignment: .center)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
            
            // MARK: Role
            Section {
                if viewModel.canAssignRole {
                    NavigationLink {
                        HouseholdMemberRolePickerView(viewModel: viewModel)
                    }
                    label: {
                        LabeledContent("Role", value: member.householdRole.name)
                    }
                } else {
                    LabeledContent("Role", value: member.householdRole.name)
                }
            }
            
            // MARK: Joined
            Section {
                LabeledContent("Joined", value: member.joinedAt.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showsNicknameEditor = true } label: {
                    Label("Edit nickname", systemImage: "pencil")
                }
                .disabled(viewModel.isLoading || viewModel.isSaving)
            }
        }
        .sheet(isPresented: $showsNicknameEditor) {
            HouseholdMemberNicknameView(viewModel: viewModel)
        }
        .task { await viewModel.load() }
        .alert("Unable to load member", isPresented: Binding(
            get: { viewModel.errorMessage != nil && !showsNicknameEditor },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Retry") { Task { await viewModel.load() } }
            Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
        } message: { Text(viewModel.errorMessage ?? "") }
            .navigationTitle("Member")
            .navigationBarTitleDisplayMode(.inline)
            .scrollEdgeEffectStyle(.soft, for: .top)
    }
    
    private var roleLabel: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Role").font(.subheadline).foregroundStyle(.secondary)
            Text(member.householdRole.name).font(.headline)
        }
    }
}

#Preview {
    NavigationStack {
        HouseholdMemberDetailView(member: PreviewHouseholdRepository.mockedData[0].members[0], isCurrentUser: true, repository: PreviewHouseholdRepository())
    }
    .environment(\.container, DependencyContainer.mock())
}
