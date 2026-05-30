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
    @State private var selectedTab: MegrumTab = .home
    @State private var showsSearch = false

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeScreen(showsSearch: $showsSearch)
            }
            .tag(MegrumTab.home)
            .tabItem {
                Label(MegrumTab.home.title, systemImage: MegrumTab.home.symbolName)
            }

            NavigationStack {
                GoodsCollectionScreen(
                    title: "在庫",
                    subtitle: "交換に出せるグッズ",
                    items: NativePreviewData.inventory
                )
            }
            .tag(MegrumTab.inventory)
            .tabItem {
                Label(MegrumTab.inventory.title, systemImage: MegrumTab.inventory.symbolName)
            }

            NavigationStack {
                WishCollectionScreen(items: NativePreviewData.wishes)
            }
            .tag(MegrumTab.wish)
            .tabItem {
                Label(MegrumTab.wish.title, systemImage: MegrumTab.wish.symbolName)
            }

            NavigationStack {
                TradesScreen(proposals: NativePreviewData.proposals)
            }
            .tag(MegrumTab.trades)
            .tabItem {
                Label(MegrumTab.trades.title, systemImage: MegrumTab.trades.symbolName)
            }

            NavigationStack {
                MeguriScreen(grooms: NativePreviewData.grooms, threads: NativePreviewData.threads)
            }
            .tag(MegrumTab.meguri)
            .tabItem {
                Label(MegrumTab.meguri.title, systemImage: MegrumTab.meguri.symbolName)
            }
        }
        .tint(MegrumTheme.lavender)
        .sheet(isPresented: $showsSearch) {
            NavigationStack {
                SearchScreen(items: NativePreviewData.inventory)
            }
        }
    }
}
