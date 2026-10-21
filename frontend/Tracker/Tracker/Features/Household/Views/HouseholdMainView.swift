import SwiftUI
import SwiftData

struct HouseholdMainView: View {
    var currentUserService: (any CurrentUserFetching)? = nil
    let model: HouseholdMainViewModel
    @Environment(HouseholdRouter.self) private var router

    var body: some View {
        Group {
            if let userId = model.userId {
                HouseholdListView(userId: userId)
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
}

#if DEBUG
#Preview {
    HouseholdCoordinatorView(currentUserService: CurrentUserPreviewService())
        .modelContainer(for: TrackerSchema.models,
                        inMemory: true)
}
#endif
