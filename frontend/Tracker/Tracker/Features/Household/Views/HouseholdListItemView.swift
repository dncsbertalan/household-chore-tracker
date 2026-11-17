//
//  HouseholdListItemView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

import SwiftUI

struct HouseholdListItemView: View {
    let household: HouseholdSummaryResponse
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(household.name)
                        .font(.title2.bold())
                    
                    Spacer()
                }
                
                Text("\(household.members.count) members")
                
                ForEach(household.members) { member in
                    AvatarView(firstName: member.firstName, lastName: member.lastName, size: 32)
                }
            }
            
            Image(systemName: "chevron.right")

        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.xl))
    }
}

#Preview {
    HouseholdListItemView(household: PreviewHouseholdRepository.mockedData[0])
}
