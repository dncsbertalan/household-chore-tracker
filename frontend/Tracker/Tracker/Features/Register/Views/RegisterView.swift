//
//  LoginView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

import SwiftUI

struct RegisterView: View {
    @State private var viewModel: RegisterViewModel
    
    @Environment(WelcomeRouter.self) private var router
    @FocusState private var focusedField: Field?
        
    private enum Field: Int, Hashable {
        case firstName
        case lastName
        case email
        case password
    }
    
    init(authService: any AuthenticationServiceProtocol) {
        _viewModel = State(
            initialValue: RegisterViewModel(authService: authService)
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 72)
                    
                    header
                        .padding(.bottom, 48)
                    
                    form
                    
                    Spacer(minLength: 48)
                    
                    footer
                }
                .frame(maxWidth: 400)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
                .frame(minHeight: geometry.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemBackground))
        }
        /*.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "xmark") }
                    .accessibilityLabel("common.close")
            }
        }*/
        .alert("login.signIn.unable.label",isPresented: $viewModel.showError) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "common.tryAgain.please Please try again.")
        }
        .interactiveDismissDisabled(viewModel.isRegistering)
    }
    
    private var header: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Image(systemName: "house")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 80, height: 80)
                .background(
                    Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 22)
                )
            
            VStack(spacing: Theme.Spacing.sm) {
                Text("register.welcome")
                    .font(.system(size: 32, weight: .bold))
                    .fontDesign(.rounded)
                    .tracking(-0.8)
                
                Text("register.label")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var form: some View {
        VStack(spacing: Theme.Spacing.md) {
            TextField("common.firstName",text: $viewModel.firstName)
                .textContentType(.givenName)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .modifier(LoginFieldStyle())
                .focused($focusedField, equals: .firstName)
                .onSubmit {
                    focusedField = .lastName
                }
            
            TextField("common.lastName",text: $viewModel.lastName)
                .textContentType(.familyName)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .modifier(LoginFieldStyle())
                .focused($focusedField, equals: .lastName)
                .onSubmit {
                    focusedField = .email
                }
            
            TextField("common.emailAddress",text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .modifier(LoginFieldStyle())
                .focused($focusedField, equals: .email)
                .onSubmit {
                    focusedField = .password
                }
            
            SecureField("common.password",text: $viewModel.password)
                .textContentType(.password)
                .submitLabel(.done)
                .modifier(LoginFieldStyle())
                .focused($focusedField, equals: .password)
                .onSubmit {
                    focusedField = nil
                }
        }
    }
    
    
    private var footer: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Button {
                Task { await register() }
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    if viewModel.isRegistering {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("common.signUp")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.glassProminent)
            .disabled(!viewModel.canRegister)
        }
    }
    
    private func register() async {
        await viewModel.register()

        if viewModel.registrationSucceeded {
            focusedField = nil
            router.replace(with: .login)
        }
    }
}

private struct LoginFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .padding(.horizontal, Theme.Spacing.lg)
            .frame(height: 56)
            .background(
                Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
            )
    }
}

#Preview {
    let container = DependencyContainer()

    RegisterView(authService: container.authService)
        .environment(WelcomeRouter())
}
