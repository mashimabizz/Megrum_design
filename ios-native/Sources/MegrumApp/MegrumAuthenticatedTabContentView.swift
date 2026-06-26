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
    @State private var homeRelationRoute: HomeRelationRoute?
    @State private var homeProposalRoute: HomeProposalRoute?
    @State private var tradeDetailRoute: TradeDetailRoute?

    var body: some View {
        ZStack {
            tabs

            MegrumSlideItemPresentationOverlay(item: $homeRelationRoute) { route, dismiss in
                NavigationStack {
                    MatchRelationScreen(
                        appState: appState,
                        targetItem: route.item,
                        matchType: route.matchType,
                        visualQAInitialScreen: visualQAInitialScreen,
                        onCompletionAction: { action in
                            dismiss()
                            if action == .openTrades {
                                openTradesFromHomePresentation()
                            }
                        }
                    )
                }
            }
            .zIndex(88)

            MegrumSlideItemPresentationOverlay(item: $homeProposalRoute) { route, dismiss in
                NavigationStack {
                    ProposalCreateFlow(
                        appState: appState,
                        targetItem: route.item,
                        receiverGoodsIDs: route.receiverGoodsIDs,
                        initialSenderGoodsIDs: route.senderGoodsIDs,
                        matchType: route.matchType,
                        initialExchangeMethod: route.initialExchangeMethod,
                        initialCashAmount: route.initialCashAmount,
                        initialShippingFee: route.initialShippingFee,
                        initialShippingDays: route.initialShippingDays,
                        initialStep: route.initialStep,
                        visualQAInitialScreen: visualQAInitialScreen,
                        onCompletionAction: { action in
                            dismiss()
                            if action == .openTrades {
                                openTradesFromHomePresentation()
                            }
                        }
                    )
                }
            }
            .zIndex(89)

            MegrumSlideBoolPresentationOverlay(isPresented: $showsSearch) { dismiss in
                NavigationStack {
                    SearchScreen(
                        appState: appState,
                        initialCriteria: homeSearchInitialCriteria,
                        adDisplayContext: adDisplayContext,
                        onRequestInterstitial: onRequestInterstitial,
                        onDismissRequest: dismiss
                    )
                }
            }
            .zIndex(90)

            TradeDetailSlidePresentationOverlay(
                detailRoute: $tradeDetailRoute,
                appState: appState,
                proposals: appState.proposals
            )
            .zIndex(100)
        }
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            homeTab
            inventoryTab
            wishTab
            tradesTab
            meguriTab
        }
        .tint(MegrumTheme.lavender)
        .onChange(of: selectedTab) { _, selectedTab in
            requestInterstitialIfPrepared(for: selectedTab)
        }
    }

    private var homeTab: some View {
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
                onOpenRelationRoute: { route in
                    homeRelationRoute = route
                },
                onOpenProposalRoute: { route in
                    homeProposalRoute = route
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
        }
        .tag(MegrumTab.home)
        .tabItem {
            Label(MegrumTab.home.title, systemImage: MegrumTab.home.symbolName)
        }
    }

    private var inventoryTab: some View {
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
    }

    private var wishTab: some View {
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
    }

    private var tradesTab: some View {
        NavigationStack {
            TradesScreen(
                appState: appState,
                requestedStage: $requestedTradesStage,
                detailRoute: $tradeDetailRoute,
                adDisplayContext: adDisplayContext
            )
        }
        .tag(MegrumTab.trades)
        .tabItem {
            Label(MegrumTab.trades.title, systemImage: MegrumTab.trades.symbolName)
        }
    }

    private var meguriTab: some View {
        NavigationStack {
            MeguriScreen(appState: appState)
        }
        .tag(MegrumTab.meguri)
        .tabItem {
            Label(MegrumTab.meguri.title, systemImage: MegrumTab.meguri.symbolName)
        }
    }

    private func openWishSection(_ section: WishCollectionSection) {
        requestedWishSection = section
        requestedTradesStage = nil
        selectedTab = .wish
    }

    private func openTradesFromHomePresentation() {
        requestedTradesStage = nil
        selectedTab = .trades
    }

    private func requestInterstitialIfPrepared(for tab: MegrumTab) {
        guard let placement = AdInterstitialPlacementResolver.placement(for: tab) else {
            return
        }
        onRequestInterstitial(placement)
    }
}
