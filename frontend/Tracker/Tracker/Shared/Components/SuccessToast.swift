import SwiftUI

struct SuccessToast: View {
    let title: LocalizedStringKey
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(title).font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background {
            if reduceTransparency {
                Capsule().fill(Color(.secondarySystemBackground))
            }
        }
        .glassEffect(reduceTransparency ? .identity : .regular, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("successToast")
        .allowsHitTesting(false)
    }
}
