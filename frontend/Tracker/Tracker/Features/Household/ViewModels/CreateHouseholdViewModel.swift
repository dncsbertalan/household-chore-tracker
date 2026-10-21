import Foundation
import Observation

@MainActor
@Observable
final class CreateHouseholdViewModel {
    var name = ""
    var description = ""
    //var roles: [HouseholdRoleDraft]
    var roles: Dictionary<String, Set<HouseholdPermission>>
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
    
}
