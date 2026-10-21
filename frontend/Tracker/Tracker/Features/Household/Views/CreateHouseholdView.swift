import SwiftData
import SwiftUI

struct CreateHouseholdView: View {
    let userId: UUID
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable private var model = CreateHouseholdViewModel()
    @State private var path: [Step] = []
    @FocusState private var isFocused: Bool

    
    private enum Step: Hashable {
        case firstRole, review
             //, editRole(UUID)
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            nameStep
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .firstRole: firstRoleStep
                    case .review: reviewStep
                        /*case .editRole(let id):
                         HouseholdRoleEditor(
                         draft: model.roles.first { $0.id == id }
                         ?? HouseholdRoleDraft(householdRoleId: id, name: "", permissions: []),
                         isValid: model.isValidRole,
                         onSave: { role in
                         model.updateRole(role)
                         path.removeLast()
                         }, onExit: { dismiss() }
                         )*/
                    }
                }
        }
    }
    
    private var nameStep: some View {
        VStack(spacing: 24) {            
            Image(systemName: "house.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            TextField("household.name", text: $model.name)
                .font(.system(size: 28, weight: .medium))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.leading, 32)
                .padding(.trailing, 32)
                .frame(height: 64)
                .background {
                    Capsule()
                        .fill(Color(uiColor: .secondarySystemBackground))
                }
                .overlay(alignment: .trailing) {
                    if !model.name.isEmpty {
                        VStack {
                            Button {
                                model.name = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            .accessibilityLabel("Clear text")
                        }
                        .padding(.trailing, 8)
                    }
                }
                .onSubmit {
                    if model.canContinueWithName { path.append(.firstRole) }
                }
                .onAppear {
                    isFocused = true
                }
            
            Spacer()
        }
        .padding()
        .toolbar { exitButton }
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            WorkflowActions(title: "household.continue", isEnabled: model.canContinueWithName) {
                path.append(.firstRole)
            }
        }
    }
    
    private var firstRoleStep: some View {
        Form {
           // HouseholdRoleFields(role: $model.roles[0])
        }
        .navigationTitle("household.firstRole")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar { exitButton }
        .safeAreaInset(edge: .bottom) {
            /*WorkflowActions(title: "household.continue", isEnabled: model.isValidRole(model.roles[0])) {
                path.append(.review)
            }*/
        }
    }
    
    private var reviewStep: some View {
        VStack {
            Section("household.details") {
                Text(HouseholdConstraints.normalizedName(model.name))
                    .font(.headline)
            }
            Section {
               /* ForEach(model.roles) { role in
                    Button {
                        path.append(.editRole(role.id))
                    } label: {
                        HStack {
                            Text(role.name).foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        if model.roles.count > 1 {
                            Button("household.removeRole", role: .destructive) { model.removeRole(role.id) }
                        }
                    }
                }
                Button {
                    path.append(.editRole(UUID()))
                } label: {
                    Label("household.addRole", systemImage: "plus")
                }
                .accessibilityIdentifier("addHouseholdRole")
                */
            } header: {
                Text("household.roles")
            } footer: {
                Text("household.rolesHelp")
            }
            Section {
               /* Picker("household.yourRole", selection: $model.creatorRoleId) {
                    ForEach(model.roles) { role in
                        Text(role.name).tag(role.id)
                    }
                }*/
            } header: {
                Text("household.membership")
            } footer: {
                Text("household.membershipHelp")
            }
            if let error = model.errorMessage {
                Section { Text(error).foregroundStyle(.red) }
            }
        }
        .navigationTitle("household.review")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar { exitButton }
        
    }
    
    @ToolbarContentBuilder
    private var exitButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { dismiss() } label: { Image(systemName: "xmark") }
                .accessibilityLabel("common.close")
                .accessibilityIdentifier("exitHouseholdCreation")
        }
    }
}

/*private struct HouseholdRoleEditor: View {
    @State var draft: HouseholdRoleDraft
    let isValid: (HouseholdRoleDraft) -> Bool
    let onSave: (HouseholdRoleDraft) -> Void
    let onExit: () -> Void
    
    var body: some View {
        Form {
            HouseholdRoleFields(role: $draft)
            if HouseholdConstraints.isValidRoleName(draft.name), !isValid(draft) {
                Text("household.error.uniqueRoleName").foregroundStyle(.red)
            }
        }
        .navigationTitle("household.editRole")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onExit) { Image(systemName: "xmark") }
                    .accessibilityLabel("common.close")
            }
        }
        .safeAreaInset(
            edge: .bottom) {
            WorkflowActions(title: "household.done", isEnabled: isValid(draft)) {
                onSave(draft)
            }
        }
    }
}*/

/*private struct HouseholdRoleFields: View {
    @Binding var role: HouseholdRoleDraft
    
    var body: some View {
        Section {
            TextField("household.roleName", text: $role.name)
                .accessibilityIdentifier("householdRoleName")
        } header: {
            Text("household.roleDetails")
        } footer: {
            NameLengthHint(value: role.name, limit: HouseholdConstraints.roleNameMaxLength)
        }
        Section("household.permissions") {
            ForEach(HouseholdPermission.allCases) { permission in
                Toggle(permission.title, isOn: Binding(
                    get: { role.permissions.contains(permission.rawValue) },
                    set: { enabled in
                        role.permissions.removeAll { $0 == permission.rawValue }
                        if enabled { role.permissions.append(permission.rawValue) }
                    }
                ))
            }
        }
    }
}*/


private struct WorkflowActions: View {
    let title: LocalizedStringKey
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isEnabled)
        .padding()
    }
}

#Preview {
    Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            CreateHouseholdView(userId: UUID())
                .modelContainer(for: TrackerSchema.models,
                                inMemory: true)
        }
}
