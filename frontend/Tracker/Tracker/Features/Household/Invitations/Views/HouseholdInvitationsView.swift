import SwiftUI

struct HouseholdInvitationsView: View {
    let isSentList: Bool
    @State private var model: InvitationInboxViewModel

    init(accountId: UUID, householdId: UUID? = nil, repository: HouseholdInvitationRepository) {
        isSentList = householdId != nil
        _model = State(initialValue: InvitationInboxViewModel(accountId: accountId, householdId: householdId, repository: repository))
    }

    var body: some View {
        List {
            if let error = model.errorMessage {
                Section {
                    Text(error).foregroundStyle(.red)
                    Button("household.retry") { Task { await model.load(refresh: true) } }
                        .disabled(model.isLoading || model.activeInvitationId != nil)
                }
            }
            if model.isLoading && model.invitations.isEmpty {
                ProgressView().frame(maxWidth: .infinity)
            } else if model.invitations.isEmpty {
                ContentUnavailableView("invitation.list.empty", systemImage: "envelope")
            }
            ForEach(model.invitations) { invitation in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isSentList ? invitation.email : invitation.householdName).font(.headline)
                        Text(invitation.householdRoleName).foregroundStyle(.secondary)
                        TimelineView(.periodic(from: .now, by: 30)) { timeline in
                            if invitation.status == .pending && !invitation.isPending(at: timeline.date) {
                                Text("invitation.status.expired").foregroundStyle(.secondary)
                            } else {
                                Text(LocalizedStringKey("invitation.status.\(invitation.status.rawValue.lowercased())"))
                                    .foregroundStyle(.secondary)
                            }
                            if invitation.isPending(at: timeline.date) || model.canRespond(to: invitation, action: isSentList ? "revoke" : "accept", at: timeline.date) {
                                HStack(spacing: 20) {
                                    if model.activeInvitationId == invitation.id {
                                        ProgressView()
                                    } else if isSentList {
                                        actionButton("invitation.action.revoke", action: "revoke", invitation: invitation, date: timeline.date, destructive: true)
                                    } else {
                                        actionButton("invitation.action.accept", action: "accept", invitation: invitation, date: timeline.date)
                                        actionButton("invitation.action.decline", action: "decline", invitation: invitation, date: timeline.date, destructive: true)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            if let fetchedAt = model.fetchedAt {
                Section {
                    LabeledContent("invitation.list.updated", value: fetchedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(Text(isSentList ? LocalizedStringKey("invitation.list.sent") : LocalizedStringKey("invitation.list.inbox")))
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .refreshable { await model.load(refresh: true) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await model.load(refresh: true) }
                } label: {
                    Label("invitation.list.refresh", systemImage: "arrow.clockwise")
                }
                .disabled(model.isLoading || model.activeInvitationId != nil)
            }
        }
        .interactiveDismissDisabled(model.activeInvitationId != nil)
    }

    private func actionButton(_ title: LocalizedStringKey, action: String, invitation: HouseholdInvitationResponse,
                              date: Date, destructive: Bool = false) -> some View {
        Button(title, role: destructive ? .destructive : nil) {
            Task { await model.respond(to: invitation, action: action) }
        }
        .buttonStyle(.bordered)
        .disabled(!model.canRespond(to: invitation, action: action, at: date))
    }
}
