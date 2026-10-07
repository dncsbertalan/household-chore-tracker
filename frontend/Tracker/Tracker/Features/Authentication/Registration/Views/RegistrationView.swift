import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: RegistrationModel
    @State private var submission: Task<Void, Never>?

    init(service: any Registering) {
        _model = State(initialValue: RegistrationModel(service: service))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("field.firstName", text: $model.firstName)
                        .textContentType(.givenName)
                    TextField("field.lastName", text: $model.lastName)
                        .textContentType(.familyName)
                    TextField("field.email", text: $model.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("field.registrationPassword", text: $model.password)
                        .textContentType(.newPassword)
                }
                .disabled(model.isSubmitting)

                Section {
                    Button {
                        guard submission == nil else { return }
                        submission = Task {
                            await model.register()
                            submission = nil
                        }
                    } label: {
                        if model.isSubmitting {
                            HStack {
                                ProgressView()
                                Text("auth.registering")
                            }
                        } else {
                            Text("auth.register")
                        }
                    }
                    .disabled(model.isSubmitting)
                }

                if let error = model.errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
                if let user = model.registeredUser {
                    Section {
                        Text("registration.success \(user.email)")
                        Text("registration.signInSeparately")
                    }
                }
            }
            .navigationTitle("auth.register")
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
#Preview {
    RegistrationView(service: RegistrationPreviewService())
}
#endif
