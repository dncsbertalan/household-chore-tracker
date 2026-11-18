//
//  HouseholdListView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 16..
//

import SwiftUI

struct HouseholdListView: View {
    @State private var viewModel: HouseholdsViewModel
    @Environment(HouseholdRouter.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.container) private var container

    init(viewModel: HouseholdsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                ForEach(viewModel.householdSummaries) { household in
                    Button {
                        router.navigate(to: .householdDetail(household.householdId))
                    }
                    label: {
                        HouseholdListItemView(household: household)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("household.households")
        .scrollEdgeEffectStyle(.soft, for: .top)
        .overlay {
            if viewModel.isLoadingSummaries && viewModel.householdSummaries.isEmpty {
                ProgressView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    router.navigate(to: .invitations)
                } label: {
                    Label("invitation.list.inbox", systemImage: "tray")
                }
                .badge(viewModel.householdInvitations.count)
                .accessibilityIdentifier("invitationInbox")
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.present(.createHousehold)
                } label: {
                    Label("household.create", systemImage: "plus")
                }
                .accessibilityIdentifier("addHousehold")
            }
        }
        .task {
            await viewModel.load()
        }
        .onChange(of: router.sheet) { oldValue, newValue in
            if oldValue == .createHousehold && newValue == nil {
                Task { await viewModel.load() }
            }
        }
        .refreshable {
            await viewModel.load()
        }
        .alert("Unable to load households", isPresented: Binding(
            get: { viewModel.summariesErrorMessage != nil },
            set: { if !$0 { viewModel.summariesErrorMessage = nil } }
        )) {
            Button("common.ok", role: .cancel) { viewModel.summariesErrorMessage = nil }
        } message: {
            Text(viewModel.summariesErrorMessage ?? "")
        }
    }
}

private let previewAppState: AppState = {
    let appState = AppState()
    appState.isAuthenticated = true
    return appState
}()

#Preview {
    NavigationStack {
        HouseholdListView(viewModel: HouseholdsViewModel(
            householdRepository: PreviewHouseholdRepository(),
            householdInvitationRepository: PreviewHouseholdInvitationRepository()
        ))
    }
    .environment(HouseholdRouter())
    .environment(previewAppState)
    .environment(\.container, DependencyContainer.mock())
}
