import SwiftUI

// MARK: - Model

struct JournalStyle {
    var name: String = ""
    var color: Color = JournalPalette.colors[7]
    var icon: JournalIcon = .symbol("rectangle.stack.fill")
}

enum JournalIcon: Hashable {
    case emoji(String)
    case symbol(String)
}

enum JournalPalette {
    static let colors: [Color] = [
        Color(red: 0.63, green: 0.35, blue: 0.51), // plum
        Color(red: 0.88, green: 0.35, blue: 0.33), // red
        Color(red: 0.84, green: 0.54, blue: 0.80), // pink
        Color(red: 0.87, green: 0.54, blue: 0.53), // salmon
        Color(red: 0.80, green: 0.60, blue: 0.51), // tan
        Color(red: 0.94, green: 0.63, blue: 0.43), // orange
        Color(red: 0.34, green: 0.75, blue: 0.60), // green
        Color(red: 0.35, green: 0.69, blue: 0.84), // sky blue
        Color(red: 0.26, green: 0.35, blue: 0.74), // royal blue
        Color(red: 0.50, green: 0.62, blue: 0.72), // slate
        Color(red: 0.50, green: 0.56, blue: 0.93), // periwinkle
        Color(red: 0.48, green: 0.45, blue: 0.80), // purple
        Color.black
    ]

    static let icons: [JournalIcon] = [
        .emoji("😀"),
        .symbol("rectangle.stack.fill"),
        .symbol("house.fill"),
        .symbol("bed.double.fill"),
        .symbol("stove.fill"),
        .symbol("books.vertical.fill"),
        .symbol("phone.fill"),
        .symbol("key.fill"),
        .symbol("plus.forwardslash.minus"),
        .symbol("puzzlepiece.extension.fill"),
        .symbol("balloon.2.fill"),
        .symbol("lightbulb.fill"),
        .symbol("camera.macro"),
        .symbol("airplane")
    ]
}

// MARK: - Main view

struct NewJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var style = JournalStyle()
    @State private var customColor: Color = .teal
    @State private var usingCustomColor = false
    @FocusState private var nameFocused: Bool

    var onSave: ((JournalStyle) -> Void)? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 7)
    private var canSave: Bool {
        !style.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 16)

            ScrollView {
                VStack(spacing: 28) {
                    preview
                        .padding(.top, 24)

                    nameField

                    colorGrid

                    iconGrid
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color(.systemBackground))
        .onAppear { nameFocused = true }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color(.systemBackground)))
                    .overlay(Circle().stroke(Color(.separator).opacity(0.5), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
            .accessibilityLabel("Cancel")

            Spacer()

            Button {
                onSave?(style)
                dismiss()
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(canSave ? Color.white : Color.white.opacity(0.9))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle().fill(canSave ? Color.accentColor : Color(.systemGray3))
                    )
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
            .disabled(!canSave)
            .accessibilityLabel("Save")
            .animation(.easeInOut(duration: 0.2), value: canSave)
        }
    }

    // MARK: Preview

    private var preview: some View {
        ZStack {
            Circle()
                .fill(style.color.opacity(0.18))
                .frame(width: 96, height: 96)

            iconView(style.icon, size: 40, tint: style.color)
        }
        .animation(.easeInOut(duration: 0.2), value: style.color)
    }

    // MARK: Name field

    private var nameField: some View {
        ZStack {
            TextField("", text: $style.name, prompt:
                        Text("Journal Name")
                            .foregroundColor(Color(.systemGray3))
            )
            .font(.system(size: 28, weight: .medium))
            .multilineTextAlignment(.center)
            .focused($nameFocused)
            .submitLabel(.done)
            .onSubmit { nameFocused = false }
            // Keep the text visually centered by reserving space for the clear button
            .padding(.horizontal, 52)

            HStack {
                Spacer()
                if !style.name.isEmpty {
                    Button {
                        style.name = ""
                        nameFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(.systemGray3))
                    }
                    .padding(.trailing, 18)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .accessibilityLabel("Clear name")
                }
            }
        }
        .frame(height: 64)
        .background(
            Capsule().fill(Color(.secondarySystemBackground))
        )
        .animation(.easeInOut(duration: 0.15), value: style.name.isEmpty)
    }

    // MARK: Colors

    private var colorGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(Array(JournalPalette.colors.enumerated()), id: \.offset) { _, color in
                Button {
                    usingCustomColor = false
                    style.color = color
                } label: {
                    colorSwatch(color, selected: !usingCustomColor && style.color == color)
                }
                .buttonStyle(.plain)
            }

            // Custom color picker (rainbow swatch)
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red],
                            center: .center
                        )
                    )
                    .overlay(
                        Circle().fill(
                            RadialGradient(colors: [.white.opacity(0.7), .clear],
                                           center: .center, startRadius: 0, endRadius: 24)
                        )
                    )
                    .overlay {
                        if usingCustomColor {
                            Circle().stroke(Color.white, lineWidth: 3).padding(4)
                            Circle().stroke(customColor, lineWidth: 3)
                        }
                    }

                ColorPicker("", selection: $customColor, supportsOpacity: false)
                    .labelsHidden()
                    .opacity(0.015) // invisible but tappable
                    .scaleEffect(2.2)
            }
            .aspectRatio(1, contentMode: .fit)
            .onChange(of: customColor) { _, newValue in
                usingCustomColor = true
                style.color = newValue
            }
        }
    }

    private func colorSwatch(_ color: Color, selected: Bool) -> some View {
        Circle()
            .fill(color)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if selected {
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 3)
                        .padding(4)
                    Circle()
                        .stroke(color, lineWidth: 3)
                }
            }
    }

    // MARK: Icons

    private var iconGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(JournalPalette.icons, id: \.self) { icon in
                let selected = style.icon == icon
                Button {
                    style.icon = icon
                } label: {
                    ZStack {
                        Circle()
                            .fill(selected ? style.color.opacity(0.18) : Color(.secondarySystemBackground))

                        iconView(icon, size: 22, tint: selected ? style.color : Color(.systemGray))

                        if selected {
                            Circle()
                                .stroke(Color.indigo, lineWidth: 3)
                                .padding(-6)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .padding(selected ? 0 : 0)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    // MARK: Helpers

    @ViewBuilder
    private func iconView(_ icon: JournalIcon, size: CGFloat, tint: Color) -> some View {
        switch icon {
        case .emoji(let value):
            if tint == Color(.systemGray) {
                // Unselected emoji slot in the grid uses the monochrome smiley like Journal does
                Image(systemName: "face.smiling")
                    .font(.system(size: size, weight: .regular))
                    .foregroundStyle(tint)
            } else {
                Text(value).font(.system(size: size))
            }
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(tint)
        }
    }
}

// MARK: - Preview

#Preview {
    Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            NewJournalView()
                .presentationDetents([.large])
                .presentationCornerRadius(44)
        }
}
