import SwiftUI
import SwiftData

struct HouseholdListView: View {
    let currentUserService: (any CurrentUserServiceProtocol)?
    let model: CurrentUserViewModel
    @Environment(HouseholdRouter.self) private var router
    @Environment(\.syncEngine) private var syncEngine
    @Query private var households: [LocalHousehold]

    init(currentUserService: (any CurrentUserServiceProtocol)? = nil, model: CurrentUserViewModel) {
        self.currentUserService = currentUserService
        self.model = model

        if let userId = model.userId {
            _households = Query(filter: #Predicate<LocalHousehold> {
                $0.deletedAt == nil && $0.householdMembers.contains { member in
                    member.userId == userId && member.deletedAt == nil && member.role.deletedAt == nil
                }
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
                    Text(model.errorMessage ?? AppLocalization.string("household.error.currentUser"))
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
        .refreshable { await syncEngine?.refresh() }
    }

    @ViewBuilder
    private var householdList: some View {
        if households.isEmpty {
            List {
                ContentUnavailableView("household.empty", systemImage: "house",
                                       description: Text("household.emptyHelp"))
                    .listRowBackground(Color.clear)
            }
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
        .modelContainer(for: AppSchema.models, inMemory: true)
}
#endif
