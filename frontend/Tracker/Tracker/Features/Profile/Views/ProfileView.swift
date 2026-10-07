import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: ProfileModel
    @State private var reload: Task<Void, Never>?

    init(service: any CurrentUserFetching) {
        _model = State(initialValue: ProfileModel(service: service))
    }

    var body: some View {
        NavigationStack {
            Form {
                if model.isLoading {
                    Section { ProgressView("profile.loading") }
                }
                if let user = model.user {
                    Section {
                        LabeledContent("field.firstName", value: user.firstName)
                        LabeledContent("field.lastName", value: user.lastName)
                        LabeledContent("field.email", value: user.email)
                        LabeledContent("field.userID", value: user.id.uuidString)
                    }
                }
                if let error = model.errorMessage {
                    Section { Text(error).foregroundStyle(.red) }
                }
                Section {
                    Button("profile.fetch") {
                        guard reload == nil else { return }
                        reload = Task {
                            await model.load()
                            reload = nil
                        }
                    }
                    .disabled(model.isLoading)
                }
            }
            .navigationTitle("profile.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close") { dismiss() }
                }
            }
        }
        .task { await model.load() }
        .onDisappear {
            reload?.cancel()
            reload = nil
        }
    }
}

#if DEBUG
#Preview { ProfileView(service: CurrentUserPreviewService()) }
#endif
