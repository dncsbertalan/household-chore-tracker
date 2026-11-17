//
//  HouseholdInvitationListView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

import SwiftUI

struct HouseholdInvitationListView: View {
    @State private var viewModel: HouseholdInvitationListViewModel
    @Environment(HouseholdRouter.self) private var router
    @Environment(AppState.self) private var appState

    init(viewModel: HouseholdInvitationListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(viewModel.householdInvitations) { invitation in
                    HouseholdInvitationListItemView(
                        invitation: invitation,
                        isProcessing: viewModel.processingInvitationIDs.contains(invitation.id),
                        onAccept: { Task { await viewModel.accept(invitation) } },
                        onDecline: { Task { await viewModel.decline(invitation) } }
                    )
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("household.invitations")
        .scrollEdgeEffectStyle(.soft, for: .top)
        .overlay {
            if viewModel.isLoading && viewModel.householdInvitations.isEmpty {
                ProgressView()
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .alert("Unable to update invitations", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        HouseholdInvitationListView(viewModel: HouseholdInvitationListViewModel(
            householdInvitationRepository: PreviewHouseholdInvitationRepository()
        ))
    }
    .environment(HouseholdRouter())
    .environment(AppState())
}
