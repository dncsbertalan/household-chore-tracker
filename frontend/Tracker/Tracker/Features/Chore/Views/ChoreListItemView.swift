import SwiftUI

struct ChoreListItemView: View {
    let chore: ChoreResponse

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(chore.title).font(.headline)
            if let description = chore.description, !description.isEmpty {
                Text(description).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.xl))
    }
}
