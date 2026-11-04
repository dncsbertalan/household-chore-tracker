import SwiftUI

struct SendHouseholdInvitationView: View {
    let userId: UUID
    let repository: any HouseholdInvitationRepositoryProtocol
    let onSent: () -> Void
    @Environment(\.dismiss) private var dismiss
    let householdId: UUID
    @Environment(HouseholdStore.self) private var store
    @State private var model = SendHouseholdInvitationViewModel()
    @FocusState private var isEmailFocused: Bool

    init(householdId: UUID, userId: UUID, repository: any HouseholdInvitationRepositoryProtocol, onSent: @escaping () -> Void) {
        self.userId = userId
        self.repository = repository
        self.onSent = onSent
        self.householdId = householdId
    }

    private var household: HouseholdResponse? { store.household(id: householdId) }
    private var canInvite: Bool {
        household.map { HouseholdAuthorizationService().hasPermission(.memberInvite, in: $0, userId: userId) } ?? false
    }
    private var roles: [HouseholdResponse.Role] {
        (household?.roles ?? [])
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    private var roleIds: [UUID] { roles.map(\.householdRoleId) }
    private var selectedRole: HouseholdResponse.Role? { roles.first { $0.householdRoleId == model.selectedRoleId } }

    var body: some View {
        NavigationStack {
            Group {
                if let household, canInvite {
                    invitationForm(household)
                } else {
                    ContentUnavailableView("invitation.send.unavailable", systemImage: "person.crop.circle.badge.exclamationmark",
                                           description: Text("invitation.send.unavailableHelp"))
                }
            }
            .navigationTitle("invitation.send.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    DismissButton()
                        .disabled(model.isSending)
                        .accessibilityIdentifier("closeSendInvitation")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: send) {
                        if model.isSending {
                            ProgressView().accessibilityLabel("invitation.send.sending")
                        } else {
                            Text("invitation.send.action")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canInvite || !model.canSend)
                    .accessibilityIdentifier("sendHouseholdInvitation")
                }
            }
        }
        .interactiveDismissDisabled(model.isSending)
        .onChange(of: roleIds) { _, ids in
            if let selected = model.selectedRoleId, !ids.contains(selected), !model.isSending {
                model.selectedRoleId = nil
            }
        }
    }

    private func invitationForm(_ household: HouseholdResponse) -> some View {
        Form {
            if model.isSending {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("invitation.send.sending")
                    }
                    .accessibilityIdentifier("invitationSending")
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(household.name).font(.title2.bold())
                    Text("invitation.send.intro").foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            Section {
                HStack {
                    TextField("invitation.send.emailPlaceholder", text: $model.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($isEmailFocused)
                        .onSubmit { isEmailFocused = false }
                        .accessibilityLabel("invitation.send.email")
                        .accessibilityIdentifier("invitationEmail")
                    if !model.email.isEmpty {
                        Button { model.email = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("common.clearText")
                        .accessibilityIdentifier("clearInvitationEmail")
                    }
                }
                if !model.email.isEmpty && !InviteHouseholdMemberRequest.isValidEmail(model.email) {
                    Text("invitation.error.email").font(.footnote).foregroundStyle(.red)
                        .accessibilityIdentifier("invitationEmailError")
                }
            } header: {
                Text("invitation.send.email")
            } footer: {
                Text("invitation.send.recipientHelp")
            }

            Section {
                Picker("invitation.send.role", selection: $model.selectedRoleId) {
                    Text("invitation.send.chooseRole").tag(Optional<UUID>.none)
                    ForEach(roles, id: \.householdRoleId) { role in
                        Text(role.name).tag(Optional(role.householdRoleId))
                    }
                }
                .pickerStyle(.navigationLink)
                .disabled(roles.isEmpty)
                .accessibilityIdentifier("invitationRole")

                if let selectedRole {
                    DisclosureGroup("invitation.send.permissions") {
                        if selectedRole.permissions.isEmpty {
                            Text("invitation.send.noPermissions").foregroundStyle(.secondary)
                        } else {
                            ForEach(HouseholdPermission.allCases.filter { permission in selectedRole.permissions.contains { $0.name == permission } }) { permission in
                                Text(permission.title)
                            }
                        }
                    }
                }
                if roles.isEmpty {
                    Text("invitation.send.noRoles").foregroundStyle(.secondary)
                }
            } header: {
                Text("invitation.send.role")
            } footer: {
                Text("invitation.send.roleHelp")
            }

            if let error = model.errorMessage {
                Section {
                    Text(error).foregroundStyle(.red).accessibilityIdentifier("sendInvitationError")
                }
            }
        }
        .disabled(model.isSending)
        .scrollDismissesKeyboard(.interactively)
    }

    private func send() {
        guard let household, canInvite else { return }
        isEmailFocused = false
        Task {
            if await model.send(householdId: household.householdId, accountId: userId, using: repository) {
                onSent()
                dismiss()
            }
        }
    }
}
