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
    var adPlacement: AdPlacement?
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
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

    static let inventoryStatuses = GoodsCollectionInventoryStatusPolicy.displayedStatuses
}
