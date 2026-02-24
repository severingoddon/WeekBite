import SwiftUI
import UniformTypeIdentifiers

struct MenuManagementView: View {
    @Environment(APIClient.self) private var api
    @Environment(TourManager.self) private var tourManager
    @Environment(UserContextViewModel.self) private var userContext

    @State private var viewModel: MenuManagementViewModel?
    @State private var toast: ToastMessage?
    @State private var showFileImporter = false

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GradientText(text: "Menus verwalten")
                        .id("menu-form-top")

                    if let vm = viewModel {
                        MenuFormView(viewModel: vm, toast: $toast)
                            .tourAnchor("menu-form")

                        Divider().background(WBColor.borderSubtle)

                        // List header with CSV buttons
                        HStack {
                            Text("Bestehende Menus (\(vm.menus.count))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(WBColor.textPrimary)
                            Spacer()
                            if !vm.menus.isEmpty {
                                ShareLink(item: vm.exportCSV()) {
                                    Label("CSV", systemImage: "arrow.down.doc")
                                        .font(.system(size: 12))
                                        .foregroundStyle(WBColor.textSecondary)
                                }
                            }
                            Button {
                                showFileImporter = true
                            } label: {
                                Label("CSV", systemImage: "arrow.up.doc")
                                    .font(.system(size: 12))
                                    .foregroundStyle(WBColor.textSecondary)
                            }
                        }

                        if vm.menus.isEmpty {
                            Text("Noch keine Menus vorhanden.")
                                .font(.system(size: 14))
                                .foregroundStyle(WBColor.textMuted)
                                .padding(.vertical, 20)
                        }

                        ForEach(vm.menus) { menu in
                            MenuCardView(menu: menu, onEdit: {
                                vm.editMenu(menu)
                                withAnimation {
                                    scrollProxy.scrollTo("menu-form-top", anchor: .top)
                                }
                            }, onDelete: {
                                Task {
                                    if let msg = await vm.deleteMenu(menu) {
                                        toast = ToastMessage(text: msg, actionLabel: nil, action: nil)
                                    }
                                }
                            })
                        }
                    }
                }
                .padding()
            }
        }
        .background(WBColor.bgDeepest)
        .toast($toast)
        .onAppear {
            if viewModel == nil { resetVM() } else { Task { await viewModel?.loadMenus() } }
        }
        .onChange(of: userContext.contextVersion) { resetVM() }
        .onChange(of: userContext.refreshVersion) { Task { await viewModel?.loadMenus() } }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText]) { result in
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) {
                    Task {
                        if let vm = viewModel {
                            let msg = await vm.importCSV(from: text)
                            toast = ToastMessage(text: msg, actionLabel: nil, action: nil)
                        }
                    }
                }
            case .failure:
                break
            }
        }
    }

    private func ensureVM() {
        if viewModel == nil {
            resetVM()
        }
    }

    private func resetVM() {
        let vm = MenuManagementViewModel(api: api)
        viewModel = vm
        Task {
            await vm.loadMenus()
            tryStartTour()
        }
    }

    private func tryStartTour() {
        guard !tourManager.hasSeenTour("menu-management") else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            tourManager.startTour("menu-management", steps: TourDefinitions.menuManagement)
        }
    }
}
