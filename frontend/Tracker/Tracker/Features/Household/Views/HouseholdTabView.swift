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
        case .invitations:
            HouseholdInvitationListView(viewModel: HouseholdInvitationListViewModel(householdInvitationRepository: container.householdInvitationRepository))
        case .householdDetail(let householdId):
            HouseholdInvitationListView(viewModel: HouseholdInvitationListViewModel(householdInvitationRepository: container.householdInvitationRepository))
        }
    }
    
    @ViewBuilder
    private func sheetDestination(for sheet: HouseholdSheet) -> some View {
        NavigationStack {
            switch sheet {
            case .createHousehold:
                CreateHouseholdView(viewModel: CreateHouseholdViewModel(householdRepository: container.householdRepository))
            }
        }
    }
}

#Preview {
    HouseholdTabView()
        .environment(\.container, DependencyContainer.mock())
        .environment(AppState())
}
