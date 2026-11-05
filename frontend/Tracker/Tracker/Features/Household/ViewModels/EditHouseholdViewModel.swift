import Foundation
import Observation

@MainActor
@Observable
final class EditHouseholdViewModel {
    let household: HouseholdResponse
    let accountId: UUID
    var name: String
    var description: String
    private(set) var isSaving = false
    private(set) var errorMessage: String?
    private(set) var needsReload = false
    private var attempt: (request: UpdateHouseholdRequest, id: UUID)?

    init(household: HouseholdResponse, accountId: UUID) {
        self.household = household; self.accountId = accountId
        name = household.name; description = household.description ?? ""
    }
    var isEditable: Bool { HouseholdAuthorizationService().hasPermission(.update, in: household, userId: accountId) }
    var hasValidDetails: Bool { HouseholdConstraints.isValidName(name)
        && HouseholdConstraints.trimmedText(description).utf16.count <= HouseholdConstraints.descriptionMaxLength }
    var request: UpdateHouseholdRequest {
        let description = HouseholdConstraints.trimmedText(description)
        return .init(name: HouseholdConstraints.trimmedText(name), description: description.isEmpty ? nil : description, version: household.version)
    }
    var hasChanges: Bool { request.name != household.name || request.description != household.description }
    var canSave: Bool { isEditable && hasValidDetails && hasChanges && !isSaving && !needsReload }

    func save(using store: HouseholdStore) async -> HouseholdResponse? {
        guard canSave else { return nil }
        guard let current = store.household(id: household.id),
              HouseholdAuthorizationService().hasPermission(.update, in: current, userId: accountId) else {
            needsReload = true; errorMessage = AppLocalization.string("household.edit.error.permission")
            return nil
        }
        let request = request
        if attempt?.request != request { attempt = (request, UUID()) }
        guard let attempt else { return nil }
        isSaving = true; errorMessage = nil
        defer { isSaving = false }
        do {
            return try await store.updateHousehold(id: household.id, accountId: accountId, request: request, requestId: attempt.id)
        } catch is CancellationError { return nil }
        catch {
            if case APIError.http(let status, _) = error {
                needsReload = [403, 404, 409, 410].contains(status)
                if status == 403 { errorMessage = AppLocalization.string("household.edit.error.permission") }
                else if [404, 409, 410].contains(status) { errorMessage = AppLocalization.string("household.edit.error.changed") }
                else if status == 400 { errorMessage = AppLocalization.string("household.error.details") }
                else { errorMessage = error.localizedDescription }
            } else { errorMessage = error.localizedDescription }
            return nil
        }
    }
}
