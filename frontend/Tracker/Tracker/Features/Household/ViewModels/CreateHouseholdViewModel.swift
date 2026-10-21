import Foundation
import Observation

@MainActor
@Observable
final class CreateHouseholdViewModel {
    var name: String
    var description: String
    var firstRoleName: String
    var roles: Dictionary<String, Set<HouseholdPermission>>
    private var preparedFirstRoleName: String?
    var creatorRoleId: UUID
    private(set) var errorMessage: String?
    private(set) var didSave = false
    
    init() {
        self.name = ""
        self.description = ""
        self.firstRoleName = ""
        self.roles = [:]
        self.creatorRoleId = UUID()
        self.errorMessage = nil
        self.didSave = false
    }
    
    var canContinueWithName: Bool {
        HouseholdConstraints.isValidName(name)
    }

    var canContinueWithFirstRole: Bool {
        HouseholdConstraints.isValidRoleName(firstRoleName)
    }

    var canCreate: Bool {
        canContinueWithName && canContinueWithFirstRole && !didSave
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

    func create(userId: UUID, using repository: any HouseholdRepositoryProtocol) {
        guard !didSave else { return }
        errorMessage = nil
        guard canContinueWithName,
              HouseholdConstraints.normalizedName(description).utf16.count <= HouseholdConstraints.descriptionMaxLength else {
            errorMessage = String(localized: "household.error.details")
            return
        }
        guard canContinueWithFirstRole else {
            errorMessage = String(localized: "household.error.roles")
            return
        }
        prepareFirstRole()

        do {
            try repository.create(HouseholdCreation(
                name: name, description: description,
                roleName: firstRoleName, permissions: firstRolePermissions,
                creatorUserId: userId, creatorRoleId: creatorRoleId
            ))
            didSave = true
        } catch LocalHouseholdStoreError.invalidDetails {
            errorMessage = String(localized: "household.error.details")
        } catch LocalHouseholdStoreError.invalidRole {
            errorMessage = String(localized: "household.error.roles")
        } catch {
            errorMessage = String(localized: "household.error.save")
        }
    }
    
}
