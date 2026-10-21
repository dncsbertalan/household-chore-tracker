import SwiftUI
import SwiftData

struct HouseholdListView: View {
    let currentUserService: (any CurrentUserFetching)?
    let model: HouseholdMainViewModel
    @Environment(HouseholdRouter.self) private var router
    @Query private var households: [LocalHousehold]

    init(currentUserService: (any CurrentUserFetching)? = nil, model: HouseholdMainViewModel) {
        self.currentUserService = currentUserService
        self.model = model

        if let userId = model.userId {
            _households = Query(filter: #Predicate<LocalHousehold> {
                $0.createdByUserId == userId && $0.deletedAt == nil
            })
        } else {
            _households = Query(filter: #Predicate<LocalHousehold> { _ in false })
        }
    }

    var body: some View {
        Group {
            if model.userId != nil {
                householdList
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
                    router.sheet = .createHousehold
                } label: {
                    Label("household.create", systemImage: "plus")
                }
                .disabled(model.userId == nil)
                .accessibilityIdentifier("addHousehold")
            }
        }
        .task { await model.loadUser(service: currentUserService) }
    }

    @ViewBuilder
    private var householdList: some View {
        if households.isEmpty {
            ContentUnavailableView("household.empty", systemImage: "house",
                                   description: Text("household.emptyHelp"))
        } else {
            List(households) { household in
                NavigationLink(value: HouseholdRoute.detail(householdId: household.householdId)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(household.name).font(.headline)
                        if let description = household.householdDescription, !description.isEmpty {
                            Text(description).foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityIdentifier("household-\(household.householdId.uuidString)")
            }
        }
    }
}

#if DEBUG
#Preview {
    HouseholdCoordinatorView(currentUserService: CurrentUserPreviewService())
        .modelContainer(for: TrackerSchema.models, inMemory: true)
}
#endif
