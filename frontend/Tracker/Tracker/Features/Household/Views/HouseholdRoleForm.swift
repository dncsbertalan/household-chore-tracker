import SwiftUI

struct HouseholdRoleForm: View {
    @Binding var name: String
    @Binding var permissions: Set<HouseholdPermission>
    var isSystemRole = false

    private let groups: [(String, [HouseholdPermission])] = [
        ("Household", [.update, .delete]),
        ("Members", [.memberView, .memberInvite, .memberRemove, .memberAssignRole]),
        ("Roles", [.roleView, .roleCreate, .roleUpdate, .roleDelete]),
        ("Chores", [.choreCreate, .choreUpdate, .choreDelete, .choreAssignMember]),
        ("Completion and approval", [.choreComplete, .choreReopen, .choreApproveCompletion, .choreSelfApproveCompletion])
    ]


    var body: some View {
        Form {
            Section {
                TextField("Role name", text: $name)
            } header: { Text("Name") } footer: {
                if isSystemRole {
                    Text("System roles cannot be edited.")
                }
            }
            
            ForEach(groups, id: \.0) { group in
                Section(group.0) {
                    ForEach(group.1) { permission in
                        Toggle(isOn: Binding(
                            get: { permissions.contains(permission) },
                            set: { if $0 { permissions.insert(permission) } else { permissions.remove(permission) } }
                        )) { Text(permission.title) }
                    }
                }
            }
        }
    }
}
