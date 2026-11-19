//
//  HouseholdMemberNameView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 19..
//

import SwiftUI

struct HouseholdMemberNameView: View {
    let member: HouseholdMemberResponse
    let isCurrentUser: Bool
    var font: Font = .headline
    var alignment: HorizontalAlignment = .leading
    
    private var fullName: String {
        var name = PersonNameComponents()
        name.givenName = member.firstName
        name.familyName = member.lastName
        return PersonNameComponentsFormatter.localizedString(from: name, style: .medium)
    }
    
    private var nickname: String? {
        guard let value = member.nickname?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }
        return value
    }
    
    var line1: String {nickname ?? fullName}
    var line2: String {"\(nickname != nil ? fullName : "") \(isCurrentUser ? "(You)" : "")".trimmingCharacters(in: .whitespaces)}
    
    var body: some View {
        VStack(alignment: alignment, spacing: Theme.Spacing.xs) {
            Group {
                Text(nickname ?? fullName)
            }
            .font(font)
            
            if !line2.isEmpty {
                Text("\(line2)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    HouseholdMemberNameView(member: HouseholdMemberResponse.mockData, isCurrentUser: true)
    HouseholdMemberNameView(member: HouseholdMemberResponse.mockData2, isCurrentUser: true)
}
