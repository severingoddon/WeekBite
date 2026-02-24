import SwiftUI

struct ShoppingListView: View {
    @Environment(APIClient.self) private var api
    @Environment(TourManager.self) private var tourManager
    @Environment(UserContextViewModel.self) private var userContext

    @State private var viewModel: ShoppingListViewModel?
    @State private var toast: ToastMessage?
    @State private var showClearConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    GradientText(text: "Einkaufsliste")
                    Spacer()
                    if let vm = viewModel, !vm.items.isEmpty {
                        Button {
                            showClearConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red.opacity(0.7))
                        }
                    }
                }

                if let vm = viewModel {
                    // Add form
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            TextField("Menge", text: Binding(
                                get: { vm.newQuantity },
                                set: { vm.newQuantity = $0 }
                            ))
                            .textFieldStyle(WBTextFieldStyle())
                            .frame(width: 80)

                            TextField("Artikel", text: Binding(
                                get: { vm.newName },
                                set: { vm.newName = $0 }
                            ))
                            .textFieldStyle(WBTextFieldStyle())
                            .onSubmit {
                                Task { _ = await vm.addItem() }
                            }

                            GradientButton(
                                title: "Hinzufügen",
                                action: { Task { _ = await vm.addItem() } },
                                disabled: vm.newName.trimmingCharacters(in: .whitespaces).isEmpty
                            )
                        }
                    }
                    .padding(14)
                    .cardStyle()
                    .tourAnchor("shopping-form")

                    // Items list
                    VStack(spacing: 0) {
                        if vm.items.isEmpty {
                            Text("Keine Artikel auf der Einkaufsliste.")
                                .font(.system(size: 14))
                                .foregroundStyle(WBColor.textMuted)
                                .frame(maxWidth: .infinity)
                                .padding(20)
                        }

                        ForEach(vm.items) { item in
                            if vm.editingId == item.id {
                                editRow(vm, item: item)
                            } else {
                                ShoppingItemRowView(
                                    item: item,
                                    onToggle: { Task { await vm.toggleItem(item) } },
                                    onEdit: { vm.startEdit(item) },
                                    onDelete: { Task { await vm.deleteItem(item.id) } }
                                )
                            }

                            if item.id != vm.items.last?.id {
                                Divider().background(WBColor.borderSubtle)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .cardStyle()
                    .tourAnchor("shopping-items")
                }
            }
            .padding()
        }
        .background(WBColor.bgDeepest)
        .toast($toast)
        .onAppear {
            if viewModel == nil { resetVM() } else { Task { await viewModel?.loadItems() } }
        }
        .onChange(of: userContext.contextVersion) { resetVM() }
        .onChange(of: userContext.refreshVersion) { Task { await viewModel?.loadItems() } }
        .confirmationDialog("Liste leeren?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Alle Artikel löschen", role: .destructive) {
                Task {
                    await viewModel?.clearList()
                    toast = ToastMessage(text: "Einkaufsliste geleert", actionLabel: nil, action: nil)
                }
            }
        }
    }

    private func editRow(_ vm: ShoppingListViewModel, item: ShoppingItem) -> some View {
        HStack(spacing: 8) {
            TextField("Menge", text: Binding(
                get: { vm.editQuantity },
                set: { vm.editQuantity = $0 }
            ))
            .textFieldStyle(WBTextFieldStyle())
            .frame(width: 70)

            TextField("Name", text: Binding(
                get: { vm.editName },
                set: { vm.editName = $0 }
            ))
            .textFieldStyle(WBTextFieldStyle())
            .onSubmit { Task { await vm.saveEdit(item.id) } }

            Button { Task { await vm.saveEdit(item.id) } } label: {
                Image(systemName: "checkmark")
                    .foregroundStyle(WBColor.accentCyan)
            }
            Button { vm.cancelEdit() } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(WBColor.textMuted)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func ensureVM() {
        if viewModel == nil {
            resetVM()
        }
    }

    private func resetVM() {
        let vm = ShoppingListViewModel(api: api)
        viewModel = vm
        Task {
            await vm.loadItems()
            tryStartTour()
        }
    }

    private func tryStartTour() {
        guard !tourManager.hasSeenTour("shopping-list") else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            tourManager.startTour("shopping-list", steps: TourDefinitions.shoppingList)
        }
    }
}
