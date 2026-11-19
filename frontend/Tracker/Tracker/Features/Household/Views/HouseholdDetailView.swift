//
//  HouseholdDetailView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 18..
//

import SwiftUI

struct HouseholdDetailView: View {
    @Environment(HouseholdRouter.self) private var router

    @State private var viewModel: HouseholdDetailViewModel
    
    init(viewModel: HouseholdDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            if let household = viewModel.household {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {

                    Text("household.members")
                        .font(.title2.bold())

                    ForEach(household.members) { member in
                        Button {
                            router.navigate(to: .householdMemberDetails(member, isCurrentUser: member.userId == household.me.userId))
                        } label: {
                            HStack(spacing: Theme.Spacing.md) {
                                AvatarView(firstName: member.firstName, lastName: member.lastName, size: 44)
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    HouseholdMemberNameView(member: member, isCurrentUser: member.userId == household.me.userId)
                                    Text(member.householdRole.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.xl))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(viewModel.household?.name ?? "household.household")
        .scrollEdgeEffectStyle(.soft, for: .top)
        .overlay {
            if viewModel.isLoading && viewModel.household == nil { ProgressView() }
        }
        .toolbar {
            if let household = viewModel.household,
               household.me.householdRole.permissions.contains(.memberInvite) == true {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { router.present(.createHouseholdInvitation(household: household)) } label: {
                        Label("household.invitation.inviteMember", systemImage: "person.badge.plus")
                    }
                    .accessibilityIdentifier("inviteHouseholdMember")
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alert("Unable to load household", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Retry") { Task { await viewModel.load() } }
            Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        HouseholdDetailView(viewModel: HouseholdDetailViewModel(
            householdId: PreviewHouseholdRepository.mockedData[0].id,
            householdRepository: PreviewHouseholdRepository()
        ))
    }
    .environment(HouseholdRouter())
}
