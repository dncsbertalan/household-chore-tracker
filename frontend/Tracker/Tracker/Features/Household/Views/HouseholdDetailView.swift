//
//  HouseholdDetailView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 18..
//

import SwiftUI

struct HouseholdDetailView: View {
    @State private var viewModel: HouseholdDetailViewModel

    init(viewModel: HouseholdDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            if let household = viewModel.household {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text(household.name)
                        .font(.largeTitle.bold())
                    Text("household.members")
                        .font(.title2.bold())
                    ForEach(household.members) { member in
                        HStack(spacing: Theme.Spacing.md) {
                            AvatarView(firstName: member.firstName, lastName: member.lastName, size: 44)
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text("\(member.firstName) \(member.lastName)")
                                    .font(.headline)
                                Text(member.householdRole.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.xl))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(viewModel.household?.name ?? "household.household")
        .navigationBarTitleDisplayMode(.inline)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .overlay {
            if viewModel.isLoading && viewModel.household == nil { ProgressView() }
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
}
