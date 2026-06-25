import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct MegrumAuthenticatedTabContentView: View {
    @ObservedObject var appState: MegrumAppState
    @Binding var selectedTab: MegrumTab
    @Binding var showsSearch: Bool
    @Binding var requestedTradesStage: TradeStage?
    @Binding var publicProfileRoute: PublicProfileRoute?
    @Binding var homeSettingsRoute: HomeSettingsRoute?
    @Binding var requestedWishSection: WishCollectionSection?
    var adDisplayContext: AdDisplayContext
    var visualQAInitialScreen: VisualQAInitialScreen?
    var onOpenDrawer: () -> Void
    var onRequestInterstitial: (AdPlacement) -> Void
    @State private var homeSearchInitialCriteria: SearchInitialCriteria?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeScreen(
                    viewer: appState.viewer,
                    matchedItems: appState.homeMatchedItems,
                    possibleItems: appState.homePossibleItems,
                    isLoading: appState.isLoading,
                    adDisplayContext: adDisplayContext,
                    showsSearch: $showsSearch,
                    onRefresh: appState.refresh,
                    appState: appState,
                    onOpenSettings: onOpenDrawer,
                    onOpenSearchRequested: {
                        homeSearchInitialCriteria = nil
                        showsSearch = true
                    },
                    onOpenSearchWithCriteria: { criteria in
                        homeSearchInitialCriteria = criteria
                        showsSearch = true
                    },
                    onOpenWish: {
                        openWishSection(.wishes)
                    },
                    onOpenIndividualListings: {
                        openWishSection(.listings)
                    },
                    onOpenExchangeSettings: {
                        homeSettingsRoute = .exchange
                    },
                    onOpenPaymentSettings: {
                        homeSettingsRoute = .payment
                    },
                    onOpenOwnerProfile: { userID in
                        publicProfileRoute = PublicProfileRoute(userID: userID)
                    },
                    onOpenMeguri: {
                        requestedTradesStage = nil
                        selectedTab = .meguri
                    },
                    onOpenTrades: {
                        requestedTradesStage = nil
                        selectedTab = .trades
                    },
                    visualQAInitialScreen: visualQAInitialScreen
                )
                .navigationDestination(isPresented: $showsSearch) {
                    SearchScreen(
                        appState: appState,
                        initialCriteria: homeSearchInitialCriteria,
                        adDisplayContext: adDisplayContext,
                        onRequestInterstitial: onRequestInterstitial
                    )
                }
            }
            .tag(MegrumTab.home)
            .tabItem {
                Label(MegrumTab.home.title, systemImage: MegrumTab.home.symbolName)
            }

            NavigationStack {
                GoodsCollectionScreen(
                    title: "マイグッズ",
                    subtitle: "",
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
                WishCollectionScreen(
                    items: appState.wishes,
                    appState: appState,
                    requestedSection: $requestedWishSection,
                    adDisplayContext: adDisplayContext
                )
            }
            .tag(MegrumTab.wish)
            .tabItem {
                Label(MegrumTab.wish.title, systemImage: MegrumTab.wish.symbolName)
            }

            NavigationStack {
                TradesScreen(
                    appState: appState,
                    requestedStage: $requestedTradesStage,
                    adDisplayContext: adDisplayContext
                )
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
        .onChange(of: selectedTab) { _, selectedTab in
            requestInterstitialIfPrepared(for: selectedTab)
        }
    }

    private func openWishSection(_ section: WishCollectionSection) {
        requestedWishSection = section
        requestedTradesStage = nil
        selectedTab = .wish
    }

    private func requestInterstitialIfPrepared(for tab: MegrumTab) {
        guard let placement = AdInterstitialPlacementResolver.placement(for: tab) else {
            return
        }
        onRequestInterstitial(placement)
    }
}
