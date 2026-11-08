//
//  LoginView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel

    init(authService: any AuthenticationServiceProtocol, appState: AppState) {
        _viewModel = State(
            initialValue: LoginViewModel(authService: authService, appState: appState)
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
        //.navigationBarBackButtonHidden()
        .alert(
            "Unable to Sign In",
            isPresented: $viewModel.showError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Please try again.")
        }
        
    }

    private var header: some View {
        VStack(spacing: 20) {
            Image(systemName: "house")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 80, height: 80)
                .background(
                    Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 22)
                )

            VStack(spacing: 8) {
                Text("Welcome back")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(-0.8)

                Text("Sign in to continue to your household.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var form: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                TextField(
                    "Email address",
                    text: $viewModel.email
                )
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .modifier(LoginFieldStyle())

                SecureField(
                    "Password",
                    text: $viewModel.password
                )
                .textContentType(.password)
                .submitLabel(.go)
                .modifier(LoginFieldStyle())
                .onSubmit {
                    Task { await viewModel.login() }
                }
            }

            Button("Forgot password?") {
                // Navigate to password recovery
            }
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity, alignment: .trailing)

            Button {
                Task { await viewModel.login() }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(
                Color.primary.opacity(0.92),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .disabled(!viewModel.canLogin)
            .opacity(viewModel.canLogin ? 1 : 0.5)
        }
    }

    private var footer: some View {
        HStack(spacing: 5) {
            Text("Don't have an account?")
                .foregroundStyle(.secondary)

            Button("Create account") {
                // Navigate to registration
            }
            .fontWeight(.semibold)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity)
    }
}

private struct LoginFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 14)
            )
    }
}


#Preview {
    LoginView(authService: AuthenticationService.shared, appState: AppState())
}
