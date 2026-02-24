import SwiftUI

struct FamilyManagementView: View {
    @Environment(APIClient.self) private var api
    @Environment(TourManager.self) private var tourManager
    @Environment(UserContextViewModel.self) private var userContext

    @State private var viewModel: FamilyManagementViewModel?
    @State private var toast: ToastMessage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GradientText(text: "Meine Familien")
                    .tourAnchor("context-info")

                if let vm = viewModel {
                    // Pending invites
                    if !vm.pendingInvites.isEmpty {
                        Text("Offene Einladungen")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(WBColor.textPrimary)

                        ForEach(vm.pendingInvites) { invite in
                            PendingInviteCardView(
                                invite: invite,
                                onAccept: {
                                    Task {
                                        if let msg = await vm.acceptInvite(invite) {
                                            toast = ToastMessage(text: msg, actionLabel: nil, action: nil)
                                        }
                                        await userContext.loadUser()
                                    }
                                },
                                onDecline: {
                                    Task {
                                        if let msg = await vm.declineInvite(invite) {
                                            toast = ToastMessage(text: msg, actionLabel: nil, action: nil)
                                        }
                                    }
                                }
                            )
                        }
                    }

                    // Create family form
                    HStack(spacing: 8) {
                        TextField("Familienname", text: Binding(
                            get: { vm.newFamilyName },
                            set: { vm.newFamilyName = $0 }
                        ))
                        .textFieldStyle(WBTextFieldStyle())
                        .onSubmit { createFamily(vm) }

                        GradientButton(
                            title: "Erstellen",
                            action: { createFamily(vm) },
                            disabled: vm.newFamilyName.trimmingCharacters(in: .whitespaces).isEmpty
                        )
                    }
                    .padding(14)
                    .cardStyle()
                    .tourAnchor("family-create")

                    // Families
                    ForEach(vm.families) { family in
                        FamilyCardView(
                            family: family,
                            viewModel: vm,
                            activeId: userContext.user?.active_family_id,
                            toast: $toast,
                            onContextChange: {
                                Task { await userContext.loadUser() }
                            }
                        )
                    }

                    if vm.families.isEmpty {
                        Text("Noch keine Familien erstellt. Erstelle eine Familie, um Wochenpläne und Einkaufslisten zu teilen.")
                            .font(.system(size: 14))
                            .foregroundStyle(WBColor.textMuted)
                            .padding(.vertical, 20)
                    }
                }
            }
            .padding()
        }
        .background(WBColor.bgDeepest)
        .toast($toast)
        .onAppear { initVM() }
        .onChange(of: userContext.contextVersion) { initVM() }
    }

    private func createFamily(_ vm: FamilyManagementViewModel) {
        Task {
            if let msg = await vm.createFamily() {
                toast = ToastMessage(text: msg, actionLabel: nil, action: nil)
            }
            await userContext.loadUser()
        }
    }

    private func initVM() {
        let vm = FamilyManagementViewModel(api: api)
        viewModel = vm
        Task {
            await vm.loadData()
            tryStartTour()
        }
    }

    private func tryStartTour() {
        guard !tourManager.hasSeenTour("family-management") else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            tourManager.startTour("family-management", steps: TourDefinitions.familyManagement)
        }
    }
}
