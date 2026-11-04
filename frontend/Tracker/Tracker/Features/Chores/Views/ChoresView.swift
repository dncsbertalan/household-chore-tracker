import SwiftUI

struct ChoresView: View {
    @Environment(ChoresRouter.self) private var router
    let userId: UUID
    @Environment(HouseholdStore.self) private var store
    @State private var isLoading = false
    @State private var errorMessage: String?
    private var households: [HouseholdResponse] { store.households }
    private var chores: [ChoreResponse] { store.chores }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("chores.title", systemImage: "checklist")
                } description: { Text(errorMessage) } actions: {
                    Button("household.retry") { Task { await refresh() } }
                }
            } else if households.isEmpty {
                ContentUnavailableView {
                    Label("household.empty", systemImage: "house")
                } description: {
                    Text("chores.householdRequiredHelp")
                } actions: {
                    Button {
                        router.sheet = .createHousehold
                    } label: {
                        Label("household.create", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("createHouseholdFromChores")
                }
            } else if chores.isEmpty {
                ContentUnavailableView("chores.empty", systemImage: "checklist",
                                       description: Text("chores.emptyHelp"))
            } else {
                List {
                    ForEach(households) { household in
                        let householdChores = chores.filter { $0.householdId == household.householdId }
                        if !householdChores.isEmpty {
                            Section(household.name) {
                                ForEach(householdChores, id: \.choreId) { chore in
                                    NavigationLink(value: ChoreRoute.detail(choreId: chore.id)) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(chore.title).font(.headline)
                                            if let description = chore.description, !description.isEmpty {
                                                Text(description).foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .accessibilityIdentifier("chore-\(chore.choreId.uuidString)")
                                }
                            }
                        }
                    }
                }
            }
        }
        .task { await refresh() }
        .refreshable { await refresh() }
    }

    private func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await store.households(accountId: userId)
            _ = try await store.chores(accountId: userId)
        } catch is CancellationError { }
        catch { errorMessage = error.localizedDescription }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ChoresView(userId: UUID())
            .navigationTitle("chores.title")
    }
    .environment(ChoresRouter())
    .environment(HouseholdStore())
}
#endif
