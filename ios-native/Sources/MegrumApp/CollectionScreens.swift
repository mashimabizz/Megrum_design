import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsCollectionScreen: View {
    var title: String
    var subtitle: String
    var items: [GoodsItem]
    var showsAddButton: Bool = false
    var appState: MegrumAppState?
    var entryKind: GoodsEntryKind = .inventory
    var headerAccessory: AnyView?
    var showsHeader = true
    var showsColumnToggle = true
    var displayColumnsOverride: Int?
    var adPlacement: AdPlacement?
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    var onScrollContentTopChange: ((CGFloat) -> Void)? = nil
    /// 値が変わるとページ先頭までスクロールを戻す（タブ切替時のリセット用）。
    var scrollToTopToken: Int = 0
    /// 作成/編集シートを閉じた時のスクロール復元用（シート上のキーボードで
    /// 背後の一覧のスクロール位置が壊れることがあるため、先頭へ戻して復元する）。
    @State var internalScrollResetToken = 0
    @State var columns = GoodsGridLayout.minimumColumns
    @State var editorRoute: GoodsEditorRoute?
    @State var isShowingUnavailableAlert = false
    @State var listingSeedWish: GoodsItem?
    @State var selectedGroupIDs: Set<UUID> = []
    @State var selectedMemberIDs: Set<UUID> = []
    @State var selectedGoodsTypeIDs: Set<UUID> = []
    @State var selectedTagNames: Set<String> = []
    @State var isShowingFilterSheet = false
    @State var selectedInventoryStatus: GoodsEntryStatus = .active
    @State var quickActionItem: GoodsItem?
    @State var selectedItemIDs: Set<UUID> = []
    @State var bulkTagRoute: GoodsBulkTagRoute?
    @State var pendingSingleDeleteItem: GoodsItem?
    @State var isConfirmingBulkDelete = false
    @State var canConfirmDelete = false
    @State var oshiCharactersByGroupID: [UUID: [OshiCharacter]] = [:]
    @State var sharePromptContext: GoodsSharePostContext?
    @State var isPreparingSharePost = false
    @State var sharePostErrorMessage: String?
    @State var bulkTagGoogleLensErrorMessage: String?
    @State var bulkTagLensBrowserRoute: MegrumInAppBrowserRoute?
    #if os(iOS)
    @State var shareActivityPayload: GoodsSharePostPayload?
    #endif
    @State var topChromeHeight: CGFloat = CollectionScreenLayoutMetrics.estimatedPinnedChromeBottomEdge
    @State var isTopChromeCollapsed = false
    @State var topChromeCollapseTracker = MegrumTopChromeCollapseTracker()
    @Environment(\.openURL) var openURL
    @Environment(\.megrumPinnedTopChromeInset) var pinnedTopChromeInset

    static let inventoryStatuses = GoodsCollectionInventoryStatusPolicy.displayedStatuses
}

extension GoodsCollectionScreen {
    var displayColumns: Int {
        GoodsGridLayout(columns: displayColumnsOverride ?? columns).columns
    }

    var columnPreferenceContext: GoodsGridColumnPreferenceContext {
        GoodsGridColumnPreferenceContext(
            entryKind: entryKind,
            viewerID: appState?.viewer?.id
        )
    }

    func loadStoredColumnsIfNeeded() {
        guard displayColumnsOverride == nil else {
            return
        }

        columns = GoodsGridColumnPreferenceStore.load(context: columnPreferenceContext)
    }

    func saveColumnsIfNeeded(_ newColumns: Int) {
        guard displayColumnsOverride == nil else {
            return
        }

        let normalizedColumns = GoodsGridLayout(columns: newColumns).columns
        if columns != normalizedColumns {
            columns = normalizedColumns
            return
        }

        GoodsGridColumnPreferenceStore.save(
            columns: normalizedColumns,
            context: columnPreferenceContext
        )
    }
}
