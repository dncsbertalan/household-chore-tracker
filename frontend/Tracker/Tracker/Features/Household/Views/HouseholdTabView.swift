//
//  HouseholdTabView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 16..
//

import SwiftUI

struct HouseholdTabView: View {
    @Environment(\.container) private var container
    @State private var router = HouseholdRouter()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            HouseholdListView(viewModel: HouseholdsViewModel(
                householdRepository: container.householdRepository,
                householdInvitationRepository: container.householdInvitationRepository
            ))
                .navigationDestination(for: HouseholdRoute.self) { route in
                    destination(for: route)
                }
        }
        .sheet(item: $router.sheet) { sheet in
            sheetDestination(for: sheet)
        }
        .environment(router)
    }
    
    @ViewBuilder
    private func destination(for route: HouseholdRoute) -> some View {
        switch route {
        case .householdRoles(let householdId):
            HouseholdRolesView(viewModel: HouseholdRolesViewModel(householdId: householdId, repository: container.householdRoleRepository))
        case .choreDetail(let choreId):
            ChoreDetailView(viewModel: ChoreDetailViewModel(choreId: choreId, repository: container.choreRepository, householdRepository: container.householdRepository))
        case .createChore(let household):
            CreateChoreView(viewModel: CreateChoreViewModel(household: household, repository: container.choreRepository))
        case .invitations:
            HouseholdInvitationListView(viewModel: HouseholdInvitationListViewModel(householdInvitationRepository: container.householdInvitationRepository))
        case .householdDetail(let householdId):
            HouseholdDetailView(viewModel: HouseholdDetailViewModel(householdId: householdId, householdRepository: container.householdRepository, choreRepository: container.choreRepository))
        case .householdMemberDetails(let member, let isCurrentUser):
            HouseholdMemberDetailView(member: member, isCurrentUser: isCurrentUser, repository: container.householdRepository)
        }
    }
    
    @ViewBuilder
    private func sheetDestination(for sheet: HouseholdSheet) -> some View {
        NavigationStack {
            switch sheet {
            case .createChore(let household):
                CreateChoreView(viewModel: CreateChoreViewModel(household: household, repository: container.choreRepository), showsCancel: true)
            case .assistedChore(let household):
                ChoreAssistanceView(viewModel: ChoreAssistanceViewModel(household: household, repository: container.choreSuggestionRepository),
                                    choreRepository: container.choreRepository)
            case .createHousehold:
                CreateHouseholdView(viewModel: CreateHouseholdViewModel(householdRepository: container.householdRepository))
            case .createHouseholdInvitation(let household):
                CreateHouseholdInvitationView(viewModel: CreateHouseholdInvitationViewModel(
                    household: household, repository: container.householdInvitationRepository
                ))
            }
        }
    }
}

#Preview {
    HouseholdTabView()
        .environment(\.container, DependencyContainer.mock())
        .environment(AppState())
}
