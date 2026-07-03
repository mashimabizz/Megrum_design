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
    @State var columns = GoodsGridLayout.minimumColumns
    @State var editorRoute: GoodsEditorRoute?
    @State var isShowingUnavailableAlert = false
    @State var listingSeedWish: GoodsItem?
    @State var selectedGroupID: UUID?
    @State var selectedGoodsTypeID: UUID?
    @State var selectedTagNames: Set<String> = []
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
