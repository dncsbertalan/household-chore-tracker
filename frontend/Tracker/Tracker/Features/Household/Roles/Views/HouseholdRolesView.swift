import SwiftUI

struct HouseholdRolesView: View {
    let householdId: UUID
    let userId: UUID
    @Environment(HouseholdStore.self) private var store
    @State private var model = HouseholdRolesViewModel()
    @State private var sheet: RoleSheet?
    @Environment(HouseholdRouter.self) private var router
    @State private var removing: HouseholdResponse.Member?
    @State private var deleting: HouseholdResponse.Role?

    private enum RoleSheet: Identifiable {
        case create
        case role(UUID)
        case member(UUID)
        var id: String {
            switch self {
            case .create: "create"
            case .role(let id): "role-\(id)"
            case .member(let id): "member-\(id)"
            }
        }
    }

    var body: some View {
        Group {
            if model.isLoading {
                ProgressView()
            } else if let error = model.errorMessage {
                ContentUnavailableView {
                    Label("roles.title", systemImage: "person.badge.key")
                } description: { Text(error) } actions: {
                    Button("household.retry") { Task { await reload() } }
                }
            } else if let data = model.data, data.actions.canView {
                roleList(data)
            } else {
                ContentUnavailableView("roles.unavailable", systemImage: "lock", description: Text("roles.error.permission"))
            }
        }
        .navigationTitle("roles.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if model.errorMessage == nil, model.data?.actions.canCreate == true {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { sheet = .create } label: { Label("roles.create", systemImage: "plus") }
                        .disabled(model.isBusy || model.needsReload)
                        .accessibilityIdentifier("createHouseholdRole")
                }
            }
        }
        .onChange(of: model.hasLeftHousehold) { _, left in
            if left { router.popToRoot() }
        }
        .task { await reload() }
        .refreshable { await reload() }
        .sheet(item: $sheet) { selection in
            if let data = model.data {
                switch selection {
                case .create:
                    HouseholdRoleEditorView(data: data, role: nil, userId: userId, onSaved: model.apply, onReload: { Task { await reload() } })
                case .role(let id):
                    if let role = data.household.roles.first(where: { $0.householdRoleId == id }) {
                        HouseholdRoleEditorView(data: data, role: role, userId: userId, onSaved: model.apply, onReload: { Task { await reload() } })
                    }
                case .member(let id):
                    if let member = data.household.members.first(where: { $0.householdMemberId == id }) {
                        HouseholdRoleAssignmentView(data: data, member: member, userId: userId, onSaved: model.apply, onReload: { Task { await reload() } })
                    }
                }
            }
        }
        .confirmationDialog("roles.deleteConfirm", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
            if let role = deleting {
                Button("roles.delete", role: .destructive) {
                    deleting = nil
                    Task { await model.delete(role, accountId: userId, using: store) }
                }
            }
            Button("common.cancel", role: .cancel) { deleting = nil }
        } message: { Text("roles.deleteHelp") }
        .confirmationDialog("members.removeConfirm", isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } }), titleVisibility: .visible) {
            if let member = removing {
                Button("members.remove", role: .destructive) {
                    removing = nil
                    Task { await model.remove(member, accountId: userId, using: store) }
                }
            }
            Button("common.cancel", role: .cancel) { removing = nil }
        } message: {
            if let member = removing {
                Text(String(format: AppLocalization.string("members.removeHelp"), removalName(member)))
            }
        }
    }

    private func roleList(_ data: HouseholdRolesResponse) -> some View {
        List {
            if let error = model.actionError {
                Section {
                    Text(error).foregroundStyle(.red).accessibilityIdentifier("roleManagementError")
                    Button("roles.reload") { Task { await reload() } }
                }
            }
            Section("household.roles") {
                ForEach(data.household.roles, id: \.householdRoleId) { role in
                    Button { sheet = .role(role.householdRoleId) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(role.name).foregroundStyle(.primary)
                                if role.isSystemRole { Text("roles.systemRole").font(.caption).foregroundStyle(.secondary) }
                                else { Text("roles.viewPermissions").font(.caption).foregroundStyle(.secondary) }
                            }
                            Spacer()
                            if model.busyRoleId == role.householdRoleId { ProgressView() }
                            else { Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary) }
                        }
                    }
                    .accessibilityIdentifier("householdRole-\(role.householdRoleId.uuidString)")
                    .disabled(model.isBusy || model.needsReload)
                    .swipeActions {
                        if data.actions.canDelete && !role.isSystemRole {
                            Button("roles.delete", role: .destructive) { deleting = role }
                                .disabled(model.isBusy || model.needsReload)
                        }
                    }
                }
            }
            if data.actions.canAssignRoles || data.actions.canRemoveMembers {
                Section {
                    ForEach(Array(data.household.members.enumerated()), id: \.element.householdMemberId) { index, member in
                        VStack(alignment: .leading) {
                            if data.actions.canAssignRoles {
                                Button { sheet = .member(member.householdMemberId) } label: {
                                    LabeledContent(memberName(member, index: index), value: member.householdRole.name)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityIdentifier("assignMemberRole-\(member.householdMemberId.uuidString)")
                            } else {
                                LabeledContent(memberName(member, index: index), value: member.householdRole.name)
                            }
                            if data.actions.canRemoveMembers {
                                Button(role: .destructive) { removing = member } label: {
                                    if model.busyMemberId == member.householdMemberId { ProgressView() }
                                    else { Label("members.remove", systemImage: "person.badge.minus") }
                                }
                                .buttonStyle(.borderless)
                                .accessibilityIdentifier("removeHouseholdMember-\(member.householdMemberId.uuidString)")
                            }
                        }
                        .disabled(model.isBusy || model.needsReload)
                    }
                } header: { Text("roles.memberRoles") } footer: {
                    if data.actions.canAssignRoles { Text("roles.assignmentHelp") }
                    if data.actions.canRemoveMembers { Text("members.removalHelp") }
                }
            }
        }
    }

    private func removalName(_ member: HouseholdResponse.Member) -> String {
        let index = model.data?.household.members.firstIndex { $0.householdMemberId == member.householdMemberId } ?? 0
        return memberName(member, index: index)
    }
    private func memberName(_ member: HouseholdResponse.Member, index: Int) -> String {
        if let nickname = member.nickname, !nickname.isEmpty { return nickname }
        if member.userId == userId { return AppLocalization.string("chores.assignees.you") }
        return String(format: AppLocalization.string("chores.assignees.memberFormat"), index + 1)
    }
    private func reload() async { await model.load(householdId: householdId, accountId: userId, using: store) }
}
