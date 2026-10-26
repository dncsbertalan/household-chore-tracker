import SwiftData
import SwiftUI

struct ChoresView: View {
    @Environment(ChoresRouter.self) private var router
    @Query private var households: [LocalHousehold]
    @Query private var chores: [LocalChore]

    init(userId: UUID) {
        _households = Query(filter: #Predicate<LocalHousehold> { household in
            household.deletedAt == nil && (
                household.createdByUserId == userId || household.householdMembers.contains { member in
                    member.userId == userId && member.deletedAt == nil
                }
            )
        }, sort: \LocalHousehold.name)
        _chores = Query(filter: #Predicate<LocalChore> { chore in
            chore.deletedAt == nil && chore.household.deletedAt == nil && (
                chore.household.createdByUserId == userId || chore.household.householdMembers.contains { member in
                    member.userId == userId && member.deletedAt == nil
                }
            )
        }, sort: \LocalChore.createdAt, order: .reverse)
    }

    var body: some View {
        Group {
            if households.isEmpty {
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
                        let householdChores = chores.filter { $0.household.householdId == household.householdId }
                        if !householdChores.isEmpty {
                            Section(household.name) {
                                ForEach(householdChores, id: \.choreId) { chore in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(chore.title).font(.headline)
                                        if let description = chore.choreDescription, !description.isEmpty {
                                            Text(description).foregroundStyle(.secondary)
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
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ChoresView(userId: UUID())
            .navigationTitle("chores.title")
    }
    .environment(ChoresRouter())
    .modelContainer(for: AppSchema.models, inMemory: true)
}
#endif
