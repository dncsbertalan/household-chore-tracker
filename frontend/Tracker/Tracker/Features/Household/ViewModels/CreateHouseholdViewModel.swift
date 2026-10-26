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
            roles[preparedFirstRoleName ?? HouseholdConstraints.trimmedText(firstRoleName)]
                ?? Set(HouseholdPermission.allCases)
        }
        set {
            roles[preparedFirstRoleName ?? HouseholdConstraints.trimmedText(firstRoleName)] = newValue
        }
    }

    func prepareFirstRole() {
        guard canContinueWithFirstRole else { return }
        let roleName = HouseholdConstraints.trimmedText(firstRoleName)
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
              HouseholdConstraints.trimmedText(description).utf16.count <= HouseholdConstraints.descriptionMaxLength else {
            errorMessage = AppLocalization.string("household.error.details")
            return
        }
        guard canContinueWithFirstRole else {
            errorMessage = AppLocalization.string("household.error.roles")
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
        } catch LocalHouseholdRepositoryError.invalidDetails {
            errorMessage = AppLocalization.string("household.error.details")
        } catch LocalHouseholdRepositoryError.invalidRole {
            errorMessage = AppLocalization.string("household.error.roles")
        } catch {
            errorMessage = AppLocalization.string("household.error.save")
        }
    }
    
}
