import SwiftData
import SwiftUI

struct CreateHouseholdView: View {
    let userId: UUID
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var model = CreateHouseholdViewModel()
    @State private var path: [Step] = []
    @FocusState private var focusedField: NameField?
    
    private enum Step: Hashable {
        case firstRole, permissions
    }
    
    private enum NameField: Hashable {
        case household, role
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            nameStep
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .firstRole: firstRoleStep
                    case .permissions: permissionsStep
                    }
                }
        }
    }
    
    private var nameStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "house.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            nameField("household.name", text: $model.name, field: .household)
                .accessibilityIdentifier("householdName")
                .onSubmit(continueToFirstRole)
            
            Spacer()
        }
        .padding()
        .onAppear { focusedField = .household }
        .toolbar {
            workflowToolbar(title: "household.continue", isEnabled: model.canContinueWithName,
                            action: continueToFirstRole)
        }
    }
    
    private var firstRoleStep: some View {
        VStack(spacing: 24) {
            Text("household.chooseRole")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            
            nameField("household.roleName", text: $model.firstRoleName, field: .role)
                .accessibilityIdentifier("householdRoleName")
                .onSubmit(continueToPermissions)
            
            Spacer()
        }
        .padding()
        .onAppear { focusedField = .role }
        .toolbar {
            workflowToolbar(title: "household.continue", isEnabled: model.canContinueWithFirstRole,
                            action: continueToPermissions)
        }
    }
    
    private var permissionsStep: some View {
        Form {
            Section("household.permissions") {
                ForEach(HouseholdPermission.allCases) { permission in
                    Toggle(permission.title, isOn: Binding(
                        get: { model.firstRolePermissions.contains(permission) },
                        set: { enabled in
                            if enabled {
                                model.firstRolePermissions.insert(permission)
                            } else {
                                model.firstRolePermissions.remove(permission)
                            }
                        }
                    ))
                }
            }
            if let error = model.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("household.permissions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            workflowToolbar(title: "household.createAction", isEnabled: model.canCreate) {
                model.create(userId: userId, using: LocalHouseholdRepository(container: context.container))
                if model.didSave { dismiss() }
            }
        }
    }
    
    private func nameField(_ title: LocalizedStringKey, text: Binding<String>, field: NameField) -> some View {
        TextField(title, text: text)
            .font(.system(size: 28, weight: .medium))
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.continue)
            .focused($focusedField, equals: field)
            .padding(.horizontal, 40)
            .frame(height: 64)
            .background {
                Capsule()
                    .fill(Color(uiColor: .secondarySystemBackground))
            }
            .overlay(alignment: .trailing) {
                if !text.wrappedValue.isEmpty {
                    Button {
                        text.wrappedValue = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .accessibilityLabel("common.clearText")
                    .padding(.trailing, 16)
                }
            }
    }
    
    private func continueToFirstRole() {
        guard model.canContinueWithName else { return }
        focusedField = nil
        path.append(.firstRole)
    }
    
    private func continueToPermissions() {
        guard model.canContinueWithFirstRole else { return }
        model.prepareFirstRole()
        focusedField = nil
        path.append(.permissions)
    }
    
    @ToolbarContentBuilder
    private func workflowToolbar(title: LocalizedStringKey, isEnabled: Bool,
                                 action: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if path.isEmpty {
                Button { dismiss() } label: { Image(systemName: "xmark") }
                    .accessibilityLabel("common.close")
                    .accessibilityIdentifier("exitHouseholdCreation")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: action) { Text(title) }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(!isEnabled)
        }
    }
}

#Preview {
    Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            CreateHouseholdView(userId: UUID())
                .modelContainer(for: AppSchema.models,
                                inMemory: true)
        }
}
