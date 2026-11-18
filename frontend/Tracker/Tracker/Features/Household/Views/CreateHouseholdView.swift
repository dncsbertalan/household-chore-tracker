import SwiftUI

struct CreateHouseholdView: View {
    @State private var viewModel: CreateHouseholdViewModel
    @State private var path: [CreateHouseholdViewModel.Step] = []
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedStep: CreateHouseholdViewModel.Step?
    
    init(viewModel: CreateHouseholdViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            stepScreen(.name)
                .navigationDestination(for: CreateHouseholdViewModel.Step.self) { step in
                    stepScreen(step)
                }
        }
        .disabled(viewModel.isCreating)
        .interactiveDismissDisabled(viewModel.isCreating)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .onChange(of: path) { _, path in
            viewModel.step = path.last ?? .name
        }
        .alert("Unable to create household", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private func stepScreen(_ step: CreateHouseholdViewModel.Step) -> some View {
        Group {
            if step == .name {
                VStack(spacing: 24) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    
                    NameTextfieldView("household.name", text: $viewModel.name)
                        .focused($focusedStep, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { next() }
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("household.name")
                    
                    Spacer()
                }
            } else {
                VStack(spacing: 24) {
                    TextField("Description (optional)", text: $viewModel.description, axis: .vertical)
                        .lineLimit(4...8)
                        .focused($focusedStep, equals: .description)
                        .padding(Theme.Spacing.lg)
                        .background {
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        }
                        .accessibilityIdentifier("householdDescription")
                    
                    Spacer()
                }
                .navigationTitle("household.create.description")
            }
        }
        .padding()
        .disabled(viewModel.isCreating)
        .navigationTitle("household.create")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(viewModel.isCreating)
        .toolbar {
            if step == .name {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Label("common.cancel", systemImage: "xmark")
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isCreating {
                    ProgressView().accessibilityLabel("Creating household")
                } else if step == .name {
                    Button(action: next) {
                        Label("Next", systemImage: "chevron.right")
                    }
                    .disabled(!viewModel.canContinue)
                } else {
                    Button {
                        focusedStep = nil
                        Task {
                            await viewModel.create()
                            if viewModel.creationSucceeded {
                                dismiss()
                            }
                        }
                    } label: {
                        Label("household.create", systemImage: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(!viewModel.canCreate)
                    .accessibilityIdentifier("createHousehold")
                }
            }
        }
        .task { focusedStep = step }
    }
    
    private func next() {
        guard path.isEmpty, viewModel.canContinue else { return }
        viewModel.step = .description
        focusedStep = nil
        path.append(.description)
    }
    
}

#Preview {
    Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            CreateHouseholdView(viewModel: CreateHouseholdViewModel(householdRepository: PreviewHouseholdRepository()))
        }
        .environment(HouseholdRouter())
}
