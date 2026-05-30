import MegrumCore
import MegrumDesign
import SwiftUI

public enum MegrumTab: String, CaseIterable, Identifiable, Sendable {
    case home
    case inventory
    case wish
    case trades
    case meguri

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            "ホーム"
        case .inventory:
            "在庫"
        case .wish:
            "Wish"
        case .trades:
            "やりとり"
        case .meguri:
            "めぐり"
        }
    }

    var symbolName: String {
        switch self {
        case .home:
            "house"
        case .inventory:
            "shippingbox"
        case .wish:
            "heart"
        case .trades:
            "arrow.left.arrow.right"
        case .meguri:
            "dot.radiowaves.left.and.right"
        }
    }
}

@MainActor
public struct MegrumRootView: View {
    @StateObject private var appState: MegrumAppState
    @StateObject private var authState: MegrumAuthState
    @State private var selectedTab: MegrumTab = .home
    @State private var showsSearch = false
    @State private var showsSettings = false

    public init(
        appState: MegrumAppState = MegrumAppState(),
        authState: MegrumAuthState = MegrumAuthState(
            repository: PreviewMegrumAuthRepository(),
            initialSession: PreviewMegrumAuthRepository.previewSession()
        )
    ) {
        _appState = StateObject(wrappedValue: appState)
        _authState = StateObject(wrappedValue: authState)
    }

    public var body: some View {
        Group {
            if authState.isAuthenticated {
                authenticatedRoot
            } else {
                AuthScreen(authState: authState)
            }
        }
    }

    private var authenticatedRoot: some View {
        Group {
            if appState.viewer == nil {
                NativeLoadingScreen(title: "Megrumを読み込んでいます")
            } else if appState.viewer?.accountStatus.requiresSetup == true {
                NavigationStack {
                    AccountSetupScreen(appState: appState)
                }
            } else {
                authenticatedTabs
            }
        }
        .task {
            await syncRepositoryWithAuthSession()
        }
        .onChange(of: authState.session?.user.id) { _, userID in
            guard userID != nil else {
                return
            }
            Task {
                await syncRepositoryWithAuthSession()
            }
        }
        .sheet(isPresented: $showsSearch) {
            NavigationStack {
                SearchScreen(items: appState.inventory)
            }
        }
        .sheet(isPresented: $showsSettings) {
            NavigationStack {
                SettingsScreen(appState: appState)
            }
        }
    }

    private var authenticatedTabs: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeScreen(
                    viewer: appState.viewer,
                    matchedItems: appState.inventory,
                    possibleItems: Array(appState.inventory.reversed()),
                    isLoading: appState.isLoading,
                    showsSearch: $showsSearch,
                    onRefresh: appState.refresh,
                    onOpenSettings: {
                        showsSettings = true
                    }
                )
            }
            .tag(MegrumTab.home)
            .tabItem {
                Label(MegrumTab.home.title, systemImage: MegrumTab.home.symbolName)
            }

            NavigationStack {
                GoodsCollectionScreen(
                    title: "在庫",
                    subtitle: "交換に出せるグッズ",
                    items: appState.inventory
                )
            }
            .tag(MegrumTab.inventory)
            .tabItem {
                Label(MegrumTab.inventory.title, systemImage: MegrumTab.inventory.symbolName)
            }

            NavigationStack {
                WishCollectionScreen(items: appState.wishes)
            }
            .tag(MegrumTab.wish)
            .tabItem {
                Label(MegrumTab.wish.title, systemImage: MegrumTab.wish.symbolName)
            }

            NavigationStack {
                TradesScreen(proposals: appState.proposals)
            }
            .tag(MegrumTab.trades)
            .tabItem {
                Label(MegrumTab.trades.title, systemImage: MegrumTab.trades.symbolName)
            }

            NavigationStack {
                MeguriScreen(grooms: appState.grooms, threads: appState.threads)
            }
            .tag(MegrumTab.meguri)
            .tabItem {
                Label(MegrumTab.meguri.title, systemImage: MegrumTab.meguri.symbolName)
            }
        }
        .tint(MegrumTheme.lavender)
    }

    private func syncRepositoryWithAuthSession() async {
        await appState.replaceRepository(
            MegrumAppStateFactory.repository(authSession: authState.session)
        )
    }
}

private struct NativeLoadingScreen: View {
    var title: String

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }
}
