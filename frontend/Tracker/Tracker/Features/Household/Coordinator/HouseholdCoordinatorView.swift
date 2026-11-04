import SwiftUI

struct HouseholdCoordinatorView: View {
    var currentUserService: (any CurrentUserServiceProtocol)? = nil
    var invitationRepository: HouseholdInvitationRepository? = nil
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var invitationWasSent = false
    @State private var toastIsVisible = false
    @State private var toastTask: Task<Void, Never>?
    @State private var model = CurrentUserViewModel()
    @State private var router = HouseholdRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            HouseholdListView(
                currentUserService: currentUserService,
                model: model,
                invitationRepository: invitationRepository
            )
            .navigationDestination(for: HouseholdRoute.self) { route in
                destination(for: route)
            }
        }
        .sheet(item: $router.sheet, onDismiss: showInvitationToast) { sheet in
            switch sheet {
            case .createHousehold:
                if let userId = model.userId {
                    CreateHouseholdView(userId: userId)
                }
            case .createChore(let householdId):
                if let userId = model.userId {
                    CreateChoreView(householdId: householdId, userId: userId)
                }
            case .sendInvitation(let householdId):
                if let userId = model.userId, let invitationRepository {
                    SendHouseholdInvitationView(householdId: householdId, userId: userId,
                                                repository: invitationRepository) {
                        invitationWasSent = true
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if toastIsVisible {
                SuccessToast(title: "invitation.send.sent")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .sensoryFeedback(.success, trigger: toastIsVisible) { _, visible in visible }
        .onDisappear {
            toastTask?.cancel()
            toastIsVisible = false
        }
        .environment(router)
    }

    private func showInvitationToast() {
        guard invitationWasSent else { return }
        invitationWasSent = false
        toastTask?.cancel()
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) { toastIsVisible = true }
        UIAccessibility.post(notification: .announcement, argument: AppLocalization.string("invitation.send.sent"))
        toastTask = Task {
            do { try await Task.sleep(for: .seconds(3)) } catch { return }
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.2)) { toastIsVisible = false }
        }
    }

    @ViewBuilder
    private func destination(for route: HouseholdRoute) -> some View {
        switch route {
        case .choreDetail(let choreId):
            if let userId = model.userId {
                ChoreDetailView(choreId: choreId, userId: userId)
            }
        case .detail(let householdId):
            if let userId = model.userId {
                HouseholdDetailView(householdId: householdId, userId: userId, invitationRepository: invitationRepository)
            }
        }
    }
}

#if DEBUG
    #Preview {
        HouseholdCoordinatorView(
            currentUserService: CurrentUserPreviewService()
        )
        .environmentObject(AppState())
        .environment(HouseholdStore())
    }
#endif
