//
//  HouseholdInvitationDto.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

import Foundation

nonisolated struct HouseholdInvitationDto: Decodable, Identifiable, Sendable {
    let householdInvitationId: UUID
    let householdId: UUID
    let householdName: String
    let invitedByLastName: String
    let invitedByFirstName: String
    let status: HouseholdInvitationStatus
    let expiresAt: Date
    let createdAt: Date
    
    var id: UUID { householdInvitationId }
}

nonisolated extension HouseholdInvitationDto {
    static var mockData: HouseholdInvitationDto {
        HouseholdInvitationDto(householdInvitationId: UUID(), householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                               householdName: "Home", invitedByLastName: "Dancs", invitedByFirstName: "Bertalan",
                               status: .pending, expiresAt: .distantPast, createdAt: .now)
    }
    
    static var mockData2: [HouseholdInvitationDto] {
        [
            HouseholdInvitationDto(
                householdInvitationId: UUID(),
                householdId: UUID(),
                householdName: "Sunny Home",
                invitedByLastName: "Smith",
                invitedByFirstName: "Anna",
                status: .pending,
                expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 3),
                createdAt: Date()
            ),
            HouseholdInvitationDto(
                householdInvitationId: UUID(),
                householdId: UUID(),
                householdName: "Cozy Apartment",
                invitedByLastName: "Johnson",
                invitedByFirstName: "Mark",
                status: .accepted,
                expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 5),
                createdAt: Date().addingTimeInterval(-60 * 60 * 24)
            )
        ]
    }
}
