import SwiftUI

struct MenuManagementView: View {
    @Environment(APIClient.self) private var api
    @Environment(UserContextViewModel.self) private var userContext

    @State private var viewModel: MenuManagementViewModel?
    @State private var toast: ToastMessage?
    @State private var showFormSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    GradientText(text: "Menus verwalten")
                    Spacer()
                    Button {
                        viewModel?.resetForm()
                        showFormSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(WBColor.accentCyan)
                    }
                }

                if let vm = viewModel {
                    if vm.menus.isEmpty {
                        Text("Noch keine Menus vorhanden.")
                            .font(.system(size: 14))
                            .foregroundStyle(WBColor.textMuted)
                            .padding(.vertical, 20)
                    }

                    ForEach(vm.menus) { menu in
                        MenuCardView(menu: menu, onEdit: {
                            vm.editMenu(menu)
                            showFormSheet = true
                        }, onDelete: {
                            if let msg = vm.deleteMenu(menu) {
                                toast = ToastMessage(text: msg, actionLabel: nil, action: nil)
                            }
                        })
                    }
                }
            }
            .padding()
        }
        .background(WBColor.bgDeepest)
        .toast($toast)
        .sheet(isPresented: $showFormSheet) {
            if let vm = viewModel {
                MenuFormSheet(viewModel: vm, toast: $toast, isPresented: $showFormSheet)
            }
        }
        .onAppear {
            if viewModel == nil { resetVM() } else { Task { await viewModel?.loadMenus() } }
        }
        .onChange(of: userContext.contextVersion) { resetVM() }
        .onChange(of: userContext.refreshVersion) { Task { await viewModel?.loadMenus() } }
    }

    private func resetVM() {
        let vm = MenuManagementViewModel(api: api)
        viewModel = vm
        Task { await vm.loadMenus() }
    }
}

struct MenuFormSheet: View {
    @Bindable var viewModel: MenuManagementViewModel
    @Binding var toast: ToastMessage?
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                MenuFormView(viewModel: viewModel, toast: $toast, onDone: {
                    isPresented = false
                })
                .padding()
            }
            .background(WBColor.bgDeepest)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        viewModel.resetForm()
                        isPresented = false
                    }
                    .foregroundStyle(WBColor.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text(viewModel.editingMenu != nil ? "Menu bearbeiten" : "Neues Menu")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(WBColor.textPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
