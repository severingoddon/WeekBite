import SwiftUI

struct MenuPopupView: View {
    @Environment(APIClient.self) private var api
    @Environment(\.dismiss) private var dismiss

    let dayName: String
    let onSelect: (Int) -> Void

    @State private var viewModel: MenuPopupViewModel?
    @State private var toast: ToastMessage?

    var body: some View {
        NavigationStack {
            ZStack {
                WBColor.bgDeepest.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        if let vm = viewModel {
                            // Search
                            HStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(WBColor.textMuted)
                                    TextField("Menu suchen...", text: Binding(
                                        get: { vm.searchQuery },
                                        set: { vm.searchQuery = $0 }
                                    ))
                                    .foregroundStyle(WBColor.textPrimary)
                                }
                                .padding(10)
                                .background(WBColor.bgCard)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(WBColor.borderSubtle, lineWidth: 1)
                                )

                                Button { vm.toggleSort() } label: {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .foregroundStyle(vm.sortByEffort ? WBColor.accentCyan : WBColor.textMuted)
                                }
                            }
                            .padding(.horizontal)

                            // No menus hint
                            if vm.showNoMenusHint {
                                noMenusHintView(vm)
                            }

                            if vm.menus.isEmpty && !vm.showNoMenusHint {
                                emptyState
                            }

                            ForEach(vm.filteredMenus) { menu in
                                MenuPopupCardView(
                                    menu: menu,
                                    isExpanded: vm.expandedMenuId == menu.id,
                                    onSelect: {
                                        onSelect(menu.id)
                                        dismiss()
                                    },
                                    onToggleDetails: { vm.toggleDetails(menu.id) },
                                    onAddToShopping: { ingredient in
                                        Task {
                                            let result = await vm.addToShoppingList(ingredient)
                                            if result.success {
                                                let itemId = result.itemId
                                                toast = ToastMessage(
                                                    text: "Zur Einkaufsliste hinzugefügt",
                                                    actionLabel: "Rückgängig",
                                                    action: {
                                                        if let id = itemId {
                                                            Task { await vm.undoShoppingAdd(id) }
                                                        }
                                                    }
                                                )
                                            }
                                        }
                                    }
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                }
                .toast($toast)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left")
                            .foregroundStyle(WBColor.textPrimary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Menu wählen für \(dayName)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(WBColor.textPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            let vm = MenuPopupViewModel(api: api)
            viewModel = vm
            Task { await vm.loadMenus() }
        }
    }

    private func noMenusHintView(_ vm: MenuPopupViewModel) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "menucard")
                .font(.system(size: 36))
                .foregroundStyle(WBColor.textMuted)
            Text("Keine Menus vorhanden")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(WBColor.textPrimary)
            Text("Erstelle zuerst ein paar Menus, damit du sie deinen Wochentagen zuweisen kannst.")
                .font(.system(size: 14))
                .foregroundStyle(WBColor.textSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button("Später") { vm.dismissHint() }
                    .foregroundStyle(WBColor.textMuted)
                GradientButton(title: "Menus erstellen") {
                    vm.dismissHint()
                    dismiss()
                }
            }
        }
        .padding(24)
        .glassBackground()
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 36))
                .foregroundStyle(WBColor.textMuted)
            Text("Noch keine Menus vorhanden.")
                .foregroundStyle(WBColor.textSecondary)
            Text("Erstelle zuerst Menus unter \"Menus verwalten\".")
                .foregroundStyle(WBColor.textMuted)
                .font(.system(size: 13))
        }
        .padding(40)
    }
}
