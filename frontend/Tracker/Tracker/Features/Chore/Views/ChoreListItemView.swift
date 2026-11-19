import SwiftUI

struct ChoreListItemView: View {
    let chore: ChoreResponse

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(chore.title).font(.headline)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            if chore.isOnDemand {
                Label("On demand", systemImage: "hand.tap")
                    .font(.caption.weight(.semibold)).foregroundStyle(.tint)
            }
            if let occurrence = chore.occurrence {
                ChoreStatusCapsule(status: occurrence.occurrenceStatus)
                if let due = occurrence.dueAt {
                    Text("Due \(due.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else if chore.isOnDemand {
                Text("Ready to start").font(.subheadline).foregroundStyle(.secondary)
            }
            if let description = chore.description, !description.isEmpty {
                Text(description).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.xl))
    }
}
