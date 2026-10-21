import Foundation
import Observation

@MainActor
@Observable
final class CreateHouseholdViewModel {
    var name = ""
    var description = ""
    var firstRoleName = ""
    var roles: Dictionary<String, Set<HouseholdPermission>>
    private var preparedFirstRoleName: String?
    var creatorRoleId: UUID
    private(set) var errorMessage: String?
    private(set) var didSave = false
    
    init(name: String = "",
         description: String = "",
         roles: Dictionary<String, Set<HouseholdPermission>> = [:],
         creatorRoleId: UUID = UUID(),
         errorMessage: String? = nil,
         didSave: Bool = false
    ) {
        self.name = name
        self.description = description
        self.roles = roles
        self.creatorRoleId = creatorRoleId
        self.errorMessage = errorMessage
        self.didSave = didSave
    }
    
    var canContinueWithName: Bool {
        HouseholdConstraints.isValidName(name)
    }

    var canContinueWithFirstRole: Bool {
        HouseholdConstraints.isValidRoleName(firstRoleName)
    }

    var firstRolePermissions: Set<HouseholdPermission> {
        get {
            roles[preparedFirstRoleName ?? HouseholdConstraints.normalizedName(firstRoleName)]
                ?? Set(HouseholdPermission.allCases)
        }
        set {
            roles[preparedFirstRoleName ?? HouseholdConstraints.normalizedName(firstRoleName)] = newValue
        }
    }

    func prepareFirstRole() {
        guard canContinueWithFirstRole else { return }
        let roleName = HouseholdConstraints.normalizedName(firstRoleName)
        let permissions = firstRolePermissions
        if let previousName = preparedFirstRoleName, previousName != roleName {
            roles.removeValue(forKey: previousName)
        }
        roles[roleName] = permissions
        preparedFirstRoleName = roleName
    }
    
}
