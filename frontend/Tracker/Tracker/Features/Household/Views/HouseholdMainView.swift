import SwiftUI
import SwiftData

struct HouseholdMainView: View {
    var currentUserService: (any CurrentUserFetching)? = nil
    @Bindable private var model = HouseholdMainViewModel()
    @State private var isCreatingHousehold = false

    var body: some View {
        NavigationStack {
            Group {
                if let userId = model.userId {
                    HouseholdList(userId: userId)
                } else if model.isLoading {
                    ProgressView()
                } else {
                    ContentUnavailableView {
                        Label("household.title", systemImage: "house")
                    } description: {
                        Text(model.errorMessage ?? String(localized: "household.error.currentUser"))
                    } actions: {
                        Button("household.retry") {
                            Task { await model.loadUser(service: currentUserService) }
                        }
                    }
                }
            }
            .navigationTitle("household.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreatingHousehold = true
                    } label: {
                        Label("household.create", systemImage: "plus")
                    }
                    .disabled(model.userId == nil)
                    .accessibilityIdentifier("addHousehold")
                }
            }
        }
        .sheet(isPresented: $isCreatingHousehold) {
            if let userId = model.userId { CreateHouseholdView(userId: userId) }
        }
        .task { await model.loadUser(service: currentUserService) }
    }
}

private struct HouseholdList: View {
    @Query private var households: [LocalHousehold]

    init(userId: UUID) {
        _households = Query(filter: #Predicate<LocalHousehold> { $0.createdByUserId == userId })
    }

    var body: some View {
        if households.isEmpty {
            ContentUnavailableView("household.empty", systemImage: "house",
                                   description: Text("household.emptyHelp"))
        } else {
            List(households) { household in
                VStack(alignment: .leading, spacing: 4) {
                    Text(household.name).font(.headline)
                    if let description = household.householdDescription, !description.isEmpty {
                        Text(description).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    HouseholdMainView(currentUserService: CurrentUserPreviewService())
        .modelContainer(for: TrackerSchema.models,
                        inMemory: true)
}
#endif
