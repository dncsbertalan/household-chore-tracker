//
//  NameTextfieldView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 18..
//

import SwiftUI

struct NameTextfieldView: View {
    let title: LocalizedStringKey
    @Binding var text: String

    @FocusState private var isFocused: Bool

    init(_ title: LocalizedStringKey, text: Binding<String>) {
        self.title = title
        self._text = text
    }

    var body: some View {
        TextField(title, text: $text)
            .font(.system(size: 28, weight: .medium))
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.continue)
            .focused($isFocused)
            .padding(.horizontal, 40)
            .frame(height: 64)
            .background {
                Capsule()
                    .fill(Color(uiColor: .secondarySystemBackground))
            }
            .overlay(alignment: .trailing) {
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .transition(
                        .opacity.combined(with: .scale(scale: 0.8))
                    )
                    .accessibilityLabel("common.clearText")
                    .padding(.trailing, 16)
                }
            }
    }
}

#Preview {
    @Previewable @State var name = "My Household"

    VStack(spacing: 24) {
        NameTextfieldView("Household name", text: $name)
        NameTextfieldView("Enter a name", text: .constant(""))
    }
    .padding(24)
}
