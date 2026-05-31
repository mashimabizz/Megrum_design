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
    @State private var showsDrawer = false
    @State private var drawerDestination: AppDrawerDestination?
    @State private var publicProfileRoute: PublicProfileRoute?
    @Binding private var notificationDestinationTab: MegrumTab?

    public init(
        appState: MegrumAppState = MegrumAppState(),
        authState: MegrumAuthState = MegrumAuthState(
            repository: PreviewMegrumAuthRepository(),
            initialSession: PreviewMegrumAuthRepository.previewSession()
        ),
        notificationDestinationTab: Binding<MegrumTab?> = .constant(nil)
    ) {
        _appState = StateObject(wrappedValue: appState)
        _authState = StateObject(wrappedValue: authState)
        _notificationDestinationTab = notificationDestinationTab
    }

    public var body: some View {
        Group {
            if authState.isAuthenticated {
                authenticatedRoot
            } else {
                AuthScreen(authState: authState)
            }
        }
        .onOpenURL { url in
            Task {
                await authState.handleOpenURL(url)
            }
        }
        .onChange(of: notificationDestinationTab) { _, destination in
            guard let destination else {
                return
            }
            selectedTab = destination
            notificationDestinationTab = nil
        }
    }

    private var authenticatedRoot: some View {
        Group {
            if appState.viewer == nil {
                if let errorMessage = appState.errorMessage {
                    NativeLoadingFailureScreen(
                        title: "Megrumを読み込めませんでした",
                        message: errorMessage,
                        onRetry: {
                            await syncRepositoryWithAuthSession()
                        },
                        onSignOut: {
                            await authState.signOut()
                            Task {
                                await appState.revokeRegisteredNativePushDeviceToken()
                            }
                        }
                    )
                } else {
                    NativeLoadingScreen(title: "Megrumを読み込んでいます")
                }
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
                SearchScreen(appState: appState)
            }
        }
        .sheet(item: $drawerDestination) { destination in
            drawerDestinationView(destination)
        }
        .sheet(item: $publicProfileRoute) { route in
            NavigationStack {
                PublicUserProfileScreen(appState: appState, userID: route.userID)
            }
        }
    }

    private var authenticatedTabs: some View {
        ZStack(alignment: .leading) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeScreen(
                        viewer: appState.viewer,
                        matchedItems: appState.homeMatchedItems,
                        possibleItems: appState.homePossibleItems,
                        isLoading: appState.isLoading,
                        showsSearch: $showsSearch,
                        onRefresh: appState.refresh,
                        appState: appState,
                        onOpenSettings: {
                            showsDrawer = true
                        },
                        onOpenOwnerProfile: { userID in
                            publicProfileRoute = PublicProfileRoute(userID: userID)
                        },
                        onOpenMeguri: {
                            selectedTab = .meguri
                        },
                        onOpenTrades: {
                            selectedTab = .trades
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
                        items: appState.inventory,
                        showsAddButton: true,
                        appState: appState,
                        entryKind: .inventory
                    )
                }
                .tag(MegrumTab.inventory)
                .tabItem {
                    Label(MegrumTab.inventory.title, systemImage: MegrumTab.inventory.symbolName)
                }

                NavigationStack {
                    WishCollectionScreen(items: appState.wishes, appState: appState)
                }
                .tag(MegrumTab.wish)
                .tabItem {
                    Label(MegrumTab.wish.title, systemImage: MegrumTab.wish.symbolName)
                }

                NavigationStack {
                    TradesScreen(appState: appState)
                }
                .tag(MegrumTab.trades)
                .tabItem {
                    Label(MegrumTab.trades.title, systemImage: MegrumTab.trades.symbolName)
                }

                NavigationStack {
                    MeguriScreen(appState: appState)
                }
                .tag(MegrumTab.meguri)
                .tabItem {
                    Label(MegrumTab.meguri.title, systemImage: MegrumTab.meguri.symbolName)
                }
            }
            .tint(MegrumTheme.lavender)
            .disabled(showsDrawer)
            .scaleEffect(showsDrawer ? 0.93 : 1, anchor: .trailing)
            .offset(x: showsDrawer ? 248 : 0)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: showsDrawer ? 40 : 0,
                    bottomLeadingRadius: showsDrawer ? 40 : 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0,
                    style: .continuous
                )
            )
            .shadow(color: showsDrawer ? Color.black.opacity(0.20) : .clear, radius: 28, x: -8, y: 0)
            .overlay {
                if showsDrawer {
                    Color.white.opacity(0.62)
                        .ignoresSafeArea()
                }
            }

            if showsDrawer {
                AppDrawerOverlay(
                    isPresented: $showsDrawer,
                    appState: appState,
                    onSelectDestination: { destination in
                        drawerDestination = nil
                        DispatchQueue.main.async {
                            drawerDestination = destination
                        }
                    },
                    onSignOut: {
                        await authState.signOut()
                        Task {
                            await appState.revokeRegisteredNativePushDeviceToken()
                        }
                        drawerDestination = nil
                        publicProfileRoute = nil
                        showsDrawer = false
                    }
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
                .zIndex(10)
            } else {
                DrawerEdgeSwipeActivator {
                    showsDrawer = true
                }
                .zIndex(9)
            }
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    private func syncRepositoryWithAuthSession() async {
        await appState.replaceRepository(
            MegrumAppStateFactory.repository(authSession: authState.session)
        )
    }

    @ViewBuilder
    private func drawerDestinationView(_ destination: AppDrawerDestination) -> some View {
        NavigationStack {
            switch destination {
            case .profile:
                OwnProfileScreen(appState: appState)
            case .notifications:
                NotificationCenterScreen(appState: appState) { tab in
                    selectedTab = tab
                    drawerDestination = nil
                } onOpenRouteIntent: { intent in
                    openNotificationRouteIntent(intent)
                }
            case .oshiSettings:
                OshiSettingsScreen(appState: appState)
            case .address:
                AddressSettingsScreen(appState: appState)
            case .blockedUsers:
                BlockedUsersScreen(appState: appState)
            case .settings:
                SettingsScreen(
                    appState: appState,
                    onOpenNotificationDestination: { tab in
                        selectedTab = tab
                        drawerDestination = nil
                    },
                    onOpenNotificationRouteIntent: { intent in
                        openNotificationRouteIntent(intent)
                    },
                    securityAuthState: authState,
                    onSignOut: {
                        await authState.signOut()
                        Task {
                            await appState.revokeRegisteredNativePushDeviceToken()
                        }
                        drawerDestination = nil
                    }
                )
            }
        }
    }

    @discardableResult
    private func openNotificationRouteIntent(_ intent: NotificationRouteIntent) -> Bool {
        selectedTab = intent.fallbackTab
        drawerDestination = nil

        switch intent {
        case .userProfile(let id), .userEvaluations(let id):
            guard let userID = UUID(uuidString: id) else {
                return true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                publicProfileRoute = PublicProfileRoute(userID: userID)
            }
        case .tab, .tradeDetail, .tradeEvidenceCapture, .tradeEvidenceApproval,
             .tradeEvaluation, .tradeAssistance, .disputeDetail,
             .meguriBoardThread, .meguriMessages, .unknown:
            break
        }
        return true
    }
}

private struct DrawerEdgeSwipeActivator: View {
    var onOpen: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragWidth: CGFloat = 0

    private let edgeWidth: CGFloat = 18
    private let openThreshold: CGFloat = 74

    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: edgeWidth)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .overlay(alignment: .leading) {
                if dragWidth > 0 {
                    Capsule()
                        .fill(MegrumTheme.lavender.opacity(0.18))
                        .frame(width: min(5 + dragWidth / 16, 14), height: 76)
                        .padding(.leading, 2)
                        .transition(.opacity)
                        .accessibilityHidden(true)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 14, coordinateSpace: .local)
                    .onChanged { value in
                        guard value.translation.width > 0,
                              abs(value.translation.height) < 54
                        else {
                            dragWidth = 0
                            return
                        }
                        dragWidth = min(value.translation.width, 120)
                    }
                    .onEnded { value in
                        defer {
                            withAnimation(reduceMotion ? .easeOut(duration: 0.10) : .smooth(duration: 0.16)) {
                                dragWidth = 0
                            }
                        }
                        guard value.translation.width > openThreshold,
                              abs(value.translation.height) < 64
                        else {
                            return
                        }
                        onOpen()
                    }
            )
            .ignoresSafeArea(edges: .leading)
            .accessibilityHidden(true)
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

private struct NativeLoadingFailureScreen: View {
    var title: String
    var message: String
    var onRetry: () async -> Void
    var onSignOut: () async -> Void

    @State private var isRetrying = false
    @State private var isSigningOut = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.orange)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                Button {
                    Task {
                        isRetrying = true
                        await onRetry()
                        isRetrying = false
                    }
                } label: {
                    Label(isRetrying ? "再読み込み中" : "再読み込み", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(MegrumTheme.lavender)
                .disabled(isRetrying || isSigningOut)

                Button(role: .destructive) {
                    Task {
                        isSigningOut = true
                        await onSignOut()
                        isSigningOut = false
                    }
                } label: {
                    Label(isSigningOut ? "ログアウト中" : "ログアウトしてやり直す", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isRetrying || isSigningOut)
            }
            .controlSize(.large)
            .padding(.top, 6)
        }
        .padding(28)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }
}
