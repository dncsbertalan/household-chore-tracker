import SwiftUI

struct EditHouseholdView: View {
    let onSaved: () -> Void
    let onReload: () -> Void
    @Environment(HouseholdStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var model: EditHouseholdViewModel

    init(household: Household, userId: UUID, onSaved: @escaping () -> Void, onReload: @escaping () -> Void) {
        self.onSaved = onSaved; self.onReload = onReload
        _model = State(initialValue: EditHouseholdViewModel(household: household, accountId: userId))
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("household.details") {
                    TextField("household.name", text: $model.name)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier("editHouseholdName")
                    TextField("household.description", text: $model.description, axis: .vertical)
                        .lineLimit(3...8)
                        .accessibilityIdentifier("editHouseholdDescription")
                    if !model.hasValidDetails { Text("household.error.details").foregroundStyle(.red) }
                }
                .disabled(!model.isEditable)
                if let error = model.errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red).accessibilityIdentifier("editHouseholdError")
                        if model.needsReload {
                            Button("household.edit.reload") { dismiss(); onReload() }
                        }
                    }
                }
            }
            .disabled(model.isSaving)
            .navigationTitle("household.edit.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }.disabled(model.isSaving)
                }
                if model.isEditable {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            Task {
                                if await model.save(using: store) != nil { onSaved(); dismiss() }
                            }
                        } label: {
                            if model.isSaving { ProgressView() } else { Text("common.save") }
                        }
                        .disabled(!model.canSave)
                        .accessibilityIdentifier("saveHouseholdDetails")
                    }
                }
            }
        }
        .interactiveDismissDisabled(model.isSaving)
    }
}
