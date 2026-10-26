import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: LoginViewModel
    @State private var submission: Task<Void, Never>?
    private let onSignIn: () -> Void

    init(service: any LoginServiceProtocol, onSignIn: @escaping () -> Void = {}) {
        _model = State(initialValue: LoginViewModel(service: service))
        self.onSignIn = onSignIn
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("field.email", text: $model.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("field.password", text: $model.password)
                        .textContentType(.password)
                }
                .disabled(model.isSubmitting)
                Section {
                    Button {
                        guard submission == nil else { return }
                        submission = Task {
                            await model.login()
                            if model.didSignIn { onSignIn() }
                            submission = nil
                        }
                    } label: {
                        if model.isSubmitting {
                            HStack { ProgressView(); Text("auth.signingIn") }
                        } else {
                            Text("auth.signIn")
                        }
                    }
                    .disabled(model.isSubmitting)
                }
                if let error = model.errorMessage {
                    Section { Text(error).foregroundStyle(.red) }
                }
                if model.didSignIn {
                    Section { Text("auth.signedIn") }
                }
            }
            .navigationTitle("auth.signIn")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close") { dismiss() }
                }
            }
        }
        .onDisappear {
            submission?.cancel()
            submission = nil
            model.password = ""
        }
    }
}

#if DEBUG
#Preview { LoginView(service: LoginPreviewService()) }
#endif
