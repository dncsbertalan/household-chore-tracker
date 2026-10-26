import SwiftData
import SwiftUI

struct HouseholdCoordinatorView: View {
    var currentUserService: (any CurrentUserServiceProtocol)? = nil
    @State private var model = CurrentUserViewModel()
    @State private var router = HouseholdRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            HouseholdListView(
                currentUserService: currentUserService,
                model: model
            )
            .navigationDestination(for: HouseholdRoute.self) { route in
                destination(for: route)
            }
        }
        .sheet(item: $router.sheet) { sheet in
            switch sheet {
            case .createHousehold:
                if let userId = model.userId {
                    CreateHouseholdView(userId: userId)
                }
            case .createChore(let householdId):
                if let userId = model.userId {
                    CreateChoreView(householdId: householdId, userId: userId)
                }
            }
        }
        .environment(router)
    }

    @ViewBuilder
    private func destination(for route: HouseholdRoute) -> some View {
        switch route {
        case .detail(let householdId):
            if let userId = model.userId {
                HouseholdDetailView(householdId: householdId, userId: userId)
            }
        }
    }
}

#if DEBUG
    #Preview {
        HouseholdCoordinatorView(
            currentUserService: CurrentUserPreviewService()
        )
        .modelContainer(for: AppSchema.models, inMemory: true)
    }
#endif
