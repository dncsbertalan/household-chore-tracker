import SwiftUI

struct DismissButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityLabel("common.close")
    }
}

#Preview {
    DismissButton()
}
