//
//  LoginView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel
    
    //@Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    private enum Field: Int, Hashable {
        case email
        case password
    }
    
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
        /*.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "xmark") }
                    .accessibilityLabel("common.close")
            }
        }*/
        .alert("login.signIn.unable.label",isPresented: $viewModel.showError) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Please try again.")
        }
        .interactiveDismissDisabled(viewModel.isLoggingIn)
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
                Text("Welcome back")
                    .font(.system(size: 32, weight: .bold))
                    .fontDesign(.rounded)
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
        VStack(spacing: Theme.Spacing.md) {
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
                    Task { await viewModel.login() }
                    focusedField = nil
                }
        }
    }
    
    
    private var footer: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Button {
                Task { await viewModel.login() }
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    if viewModel.isLoggingIn {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("common.signIn")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.glassProminent)
            .disabled(!viewModel.canLogin)
            
            HStack(spacing: Theme.Spacing.xs) {
                Text("common.noAccount.question")
                    .foregroundStyle(.secondary)
                
                Button("common.noAccount.createAccount") {
                    // Navigate to registration
                }
                .fontWeight(.semibold)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
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


#Preview("full") {
    let container = DependencyContainer()
    
    Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .fullScreenCover(isPresented: .constant(true)) {
            LoginView(authService: container.authService, appState: AppState())
        }
}

#Preview("sheet") {
    let container = DependencyContainer()
    
    Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            LoginView(authService: container.authService, appState: AppState())
        }
}

#Preview {
    let container = DependencyContainer()

    LoginView(authService: container.authService, appState: AppState())
}
