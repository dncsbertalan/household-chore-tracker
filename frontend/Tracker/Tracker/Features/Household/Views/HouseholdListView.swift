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

    init(viewModel: HouseholdsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(viewModel.householdSummaries) { household in
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text(household.name)
                                .font(.title2.bold())
                            
                            Spacer()
                        }
                        
                        Text("\(viewModel.householdSummaries.count) members")
                        
                        ForEach(household.members) { member in
                            AvatarView(firstName: member.firstName, lastName: member.lastName, size: 32)
                        }

                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.xl))
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("household.households")
        .scrollEdgeEffectStyle(.soft, for: .top)
        .overlay {
            if viewModel.isLoading && viewModel.householdSummaries.isEmpty {
                ProgressView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.sheet = .createHousehold
                } label: {
                    Label("household.create", systemImage: "plus")
                }
                .disabled(appState.currentUserId == nil)
                .accessibilityIdentifier("addHousehold")
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .alert("Unable to load households", isPresented: Binding(
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
        HouseholdListView(viewModel: HouseholdsViewModel(
            householdRepository: PreviewHouseholdRepository()
        ))
    }
    .environment(HouseholdRouter())
    .environment(AppState())
}
