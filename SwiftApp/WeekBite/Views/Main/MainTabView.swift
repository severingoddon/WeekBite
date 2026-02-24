import SwiftUI

struct MainTabView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(APIClient.self) private var api
    @Environment(TourManager.self) private var tourManager

    @State private var userContext: UserContextViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0

    init() {
        _userContext = State(initialValue: UserContextViewModel(api: APIClient()))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                WeekPlanView()
                    .toolbar { toolbarContent }
            }
            .tabItem {
                Label("Wochenplan", systemImage: "calendar")
            }
            .tag(0)

            NavigationStack {
                MenuManagementView()
                    .toolbar { toolbarContent }
            }
            .tabItem {
                Label("Menus", systemImage: "menucard")
            }
            .tag(1)

            NavigationStack {
                ShoppingListView()
                    .toolbar { toolbarContent }
            }
            .tabItem {
                Label("Einkaufen", systemImage: "cart")
            }
            .tag(2)

            NavigationStack {
                FamilyManagementView()
                    .toolbar { toolbarContent }
            }
            .tabItem {
                Label("Familien", systemImage: "person.3")
            }
            .tag(3)
            .badge(userContext.user?.pending_invites.count ?? 0)
        }
        .tint(WBColor.accentCyan)
        .environment(userContext)
        .onAppear {
            userContext = UserContextViewModel(api: api)
            Task { await userContext.loadUser() }
            configureTabBarAppearance()
            tourManager.tryShowWelcome()
        }
        .onChange(of: userContext.contextVersion) {
            selectedTab = selectedTab
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                userContext.refreshVersion += 1
                Task { await userContext.loadUser() }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            ContextSwitcherMenu()
        }
        ToolbarItem(placement: .topBarTrailing) {
            UserAvatarMenu()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(WBColor.bgCard)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
