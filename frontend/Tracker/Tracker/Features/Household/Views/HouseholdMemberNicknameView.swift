import SwiftUI

struct HouseholdMemberNicknameView: View {
    @Bindable var viewModel: HouseholdMemberDetailViewModel
    @State private var nickname: String
    @Environment(\.dismiss) private var dismiss

    init(viewModel: HouseholdMemberDetailViewModel) {
        self.viewModel = viewModel
        _nickname = State(initialValue: viewModel.member.nickname ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nickname", text: $nickname)
                        .textInputAutocapitalization(.words)
                } footer: {
                    Text("Give nicknames to household members to make your space feel more like home.")
                }
            }
            .disabled(viewModel.isSaving)
            .navigationTitle("Edit nickname")
            .navigationBarTitleDisplayMode(.inline)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Label("Cancel", systemImage: "xmark") }
                        .disabled(viewModel.isSaving)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving { ProgressView() }
                    else {
                        Button {
                            Task { if await viewModel.saveNickname(nickname) { dismiss() } }
                        } label: { Label("Save nickname", systemImage: "checkmark") }
                        .disabled(!viewModel.canSaveNickname(nickname))
                    }
                }
            }
            .alert("Unable to save nickname", isPresented: Binding(
                get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("Refresh") { Task {
                    await viewModel.load()
                    nickname = viewModel.member.nickname ?? ""
                } }
                Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
            } message: { Text(viewModel.errorMessage ?? "") }
        }
        .interactiveDismissDisabled(viewModel.isSaving)
    }
}

#Preview {
    HouseholdMemberNicknameView(viewModel: HouseholdMemberDetailViewModel(
        member: PreviewHouseholdRepository.mockedData[0].members[0], repository: PreviewHouseholdRepository()
    ))
}
