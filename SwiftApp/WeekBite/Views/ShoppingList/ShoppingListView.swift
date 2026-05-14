import SwiftUI

struct ShoppingListView: View {
    @Environment(APIClient.self) private var api
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
                                vm.addItem()
                            }

                            GradientButton(
                                title: "Hinzufügen",
                                action: { vm.addItem() },
                                disabled: vm.newName.trimmingCharacters(in: .whitespaces).isEmpty
                            )
                        }
                    }
                    .padding(14)
                    .cardStyle()

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
                                    onToggle: { vm.toggleItem(item) },
                                    onEdit: { vm.startEdit(item) },
                                    onDelete: { vm.deleteItem(item.id) }
                                )
                            }

                            if item.id != vm.items.last?.id {
                                Divider().background(WBColor.borderSubtle)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .cardStyle()
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                viewModel?.clearList()
                toast = ToastMessage(text: "Einkaufsliste geleert", actionLabel: nil, action: nil)
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
            .onSubmit { vm.saveEdit(item.id) }

            Button { vm.saveEdit(item.id) } label: {
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

    private func resetVM() {
        let vm = ShoppingListViewModel(api: api)
        viewModel = vm
        Task { await vm.loadItems() }
    }
}
