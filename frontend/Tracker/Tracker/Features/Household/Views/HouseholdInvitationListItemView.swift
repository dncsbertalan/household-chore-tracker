//
//  HouseholdInvitationListItemView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

import SwiftUI

struct HouseholdInvitationListItemView: View {
    let invitation: HouseholdInvitationDto
    var isProcessing = false
    let onAccept: (() -> Void)?
    let onDecline: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            header
            details
            
            if isPending {
                actions
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerShape(.rect(cornerRadius: Theme.CornerRadius.xxxl))
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xxl)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Subviews
private extension HouseholdInvitationListItemView {
    var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                ConcentricRectangle(corners: .concentric(minimum: 14), isUniform: true)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.18),
                                Color.purple.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: .infinity)

                Image(systemName: "house.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(invitation.householdName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                statusCapsule
            }

            Spacer()

            if !isProcessing {
                ProgressView().accessibilityLabel("household.invitation.isProcessingAction")
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    var details: some View {
        VStack(alignment: .leading, spacing: 10) {
            infoRow(
                icon: "person.crop.circle.fill",
                text: "Invited by \(invitation.invitedByFirstName) \(invitation.invitedByLastName)"
            )

            infoRow(
                icon: "calendar",
                text: "Sent \(invitation.createdAt.formatted(date: .abbreviated, time: .omitted))"
            )

            infoRow(
                icon: "clock",
                text: "Expires \(invitation.expiresAt.formatted(date: .abbreviated, time: .shortened))"
            )
        }
    }

    var actions: some View {
        HStack(spacing: 12) {
            Button {
                onDecline?()
            } label: {
                Text("Decline")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glass)
            .disabled(!isPending || isProcessing)
            
            Button {
                onAccept?()
            } label: {
                Text("Accept")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glassProminent)
            .disabled(!isPending || isProcessing)
        }
        .padding(.top, 4)
    }

    var statusCapsule: some View {
        Text(statusText)
            .font(.caption.weight(.semibold))
            .foregroundStyle(statusForegroundColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(statusBackgroundColor)
            )
    }

    var isPending: Bool {
        invitation.status == .pending
    }

    var statusText: LocalizedStringKey {
        invitation.status.label
    }

    var statusBackgroundColor: Color {
        switch invitation.status {
        case .pending:
            return .orange.opacity(0.15)
        case .accepted:
            return .green.opacity(0.15)
        case .declined:
            return .red.opacity(0.15)
        case .expired:
            return .gray.opacity(0.15)
        case .revoked:
            return .gray.opacity(0.15)
        }
    }

    var statusForegroundColor: Color {
        switch invitation.status {
        case .pending:
            return .orange
        case .accepted:
            return .green
        case .declined:
            return .red
        case .expired:
            return .secondary
        case .revoked:
            return .secondary
        }
    }

    func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HouseholdInvitationListItemView(invitation: HouseholdInvitationDto.mockData, onAccept: nil, onDecline: nil)
}
