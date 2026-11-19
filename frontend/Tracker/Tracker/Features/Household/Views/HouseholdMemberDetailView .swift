//
//  HouseholdMemberDetailView 2.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 19..
//


import SwiftUI

struct HouseholdMemberDetailView: View {
    let member: HouseholdMemberResponse
    let isCurrentUser: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: 16) {
                    AvatarView(firstName: member.firstName, lastName: member.lastName, size: 104)
                    HouseholdMemberNameView(member: member, isCurrentUser: isCurrentUser,
                                            font: .title.bold(), alignment: .center)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)

                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Role").font(.subheadline).foregroundStyle(.secondary)
                        Text(member.householdRole.name).font(.headline)
                    }
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Joined").font(.subheadline).foregroundStyle(.secondary)
                        Text(member.joinedAt, format: .dateTime.year().month(.wide).day())
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.xl))
            }
            .padding()
        }
        .navigationTitle("Member")
        .navigationBarTitleDisplayMode(.inline)
        .scrollEdgeEffectStyle(.soft, for: .top)
    }
}