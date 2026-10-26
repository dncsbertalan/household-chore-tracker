import SwiftData
import SwiftUI

struct ChoresCoordinatorView: View {
    var currentUserService: (any CurrentUserServiceProtocol)? = nil
    @State private var model = CurrentUserViewModel()
    @State private var router = ChoresRouter()

    var body: some View {
        NavigationStack {
            Group {
                if let userId = model.userId {
                    ChoresView(userId: userId)
                } else if model.isLoading {
                    ProgressView()
                } else {
                    ContentUnavailableView {
                        Label("chores.title", systemImage: "checklist")
                    } description: {
                        Text(model.errorMessage ?? AppLocalization.string("household.error.currentUser"))
                    } actions: {
                        Button("household.retry") {
                            Task { await model.loadUser(service: currentUserService) }
                        }
                    }
                }
            }
            .navigationTitle("chores.title")
            .task { await model.loadUser(service: currentUserService) }
        }
        .sheet(item: $router.sheet) { sheet in
            switch sheet {
            case .createHousehold:
                if let userId = model.userId {
                    CreateHouseholdView(userId: userId)
                }
            }
        }
        .environment(router)
    }
}

#if DEBUG
#Preview {
    ChoresCoordinatorView(currentUserService: CurrentUserPreviewService())
        .modelContainer(for: AppSchema.models, inMemory: true)
}
#endif
