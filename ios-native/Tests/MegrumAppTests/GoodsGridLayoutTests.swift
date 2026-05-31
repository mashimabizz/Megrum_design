@testable import MegrumApp
import MegrumCore
import XCTest

final class GoodsGridLayoutTests: XCTestCase {
    func testLayoutNormalizesColumnsToSupportedRange() {
        XCTAssertEqual(GoodsGridLayout(columns: 2).columns, 3)
        XCTAssertEqual(GoodsGridLayout(columns: 3).columns, 3)
        XCTAssertEqual(GoodsGridLayout(columns: 5).columns, 5)
        XCTAssertEqual(GoodsGridLayout(columns: 6).columns, 5)
    }

    func testLayoutCyclesThroughThreeFourFiveColumns() {
        XCTAssertEqual(GoodsGridLayout(columns: 3).nextColumns, 4)
        XCTAssertEqual(GoodsGridLayout(columns: 4).nextColumns, 5)
        XCTAssertEqual(GoodsGridLayout(columns: 5).nextColumns, 3)
    }

    func testSkeletonTileCountTracksTwoRowsOfCurrentColumns() {
        XCTAssertEqual(GoodsGridLayout(columns: 3).skeletonTileCount, 6)
        XCTAssertEqual(GoodsGridLayout(columns: 4).skeletonTileCount, 8)
        XCTAssertEqual(GoodsGridLayout(columns: 5).skeletonTileCount, 10)
    }

    func testGridContextLabelsFollowEntryKind() {
        XCTAssertEqual(GoodsGridContext(entryKind: .inventory).statusLabel, "譲る候補")
        XCTAssertEqual(GoodsGridContext(entryKind: .inventory).quantityLabel, "在庫数")
        XCTAssertEqual(GoodsGridContext(entryKind: .wish).statusLabel, "探し中")
        XCTAssertEqual(GoodsGridContext(entryKind: .wish).quantityLabel, "希望数")
    }

    func testTilePresentationSummarizesStatusQuantityAndTags() {
        let item = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            title: "ランダムトレカ",
            tags: [
                GoodsTag(id: UUID(), name: "会場限定"),
                GoodsTag(id: UUID(), name: "未開封")
            ],
            quantity: 3
        )

        let presentation = GoodsTilePresentation(item: item, context: .inventory, isBusy: true)

        XCTAssertEqual(presentation.statusLabel, "譲る候補")
        XCTAssertEqual(presentation.quantityText, "3点")
        XCTAssertEqual(presentation.tagSummary, "#会場限定 +1")
        XCTAssertEqual(presentation.tileMetadataText, "譲る候補 ・ 3点 ・ #会場限定 +1")
        XCTAssertEqual(presentation.accessibilityValue, "譲る候補、3点、#会場限定 +1、処理中")
    }

    func testCollectionMetricsCountsVisibleItemsQuantityAndTaggedItems() {
        let items = [
            GoodsItem(
                id: UUID(),
                ownerID: UUID(),
                title: "トレカ A",
                tags: [GoodsTag(id: UUID(), name: "未開封")],
                quantity: 2
            ),
            GoodsItem(
                id: UUID(),
                ownerID: UUID(),
                title: "トレカ B",
                quantity: 0
            )
        ]

        let metrics = GoodsCollectionMetrics(items: items)

        XCTAssertEqual(metrics.itemCount, 2)
        XCTAssertEqual(metrics.totalQuantity, 3)
        XCTAssertEqual(metrics.taggedItemCount, 1)
        XCTAssertEqual(metrics.visibleSummary, "2件 / 3点")
        XCTAssertEqual(metrics.filterSummary(totalCount: 5), "全5件中")
        XCTAssertNil(metrics.filterSummary(totalCount: 2))
    }

    func testCollectionFilterMatchesGroupGoodsTypeAndTags() {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let matching = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "トレカ A",
            tags: [
                GoodsTag(id: UUID(), name: "会場限定"),
                GoodsTag(id: UUID(), name: "未開封")
            ]
        )
        let wrongTag = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "トレカ B",
            tags: [GoodsTag(id: UUID(), name: "開封済み")]
        )
        let wrongGroup = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: UUID(),
            goodsTypeID: goodsTypeID,
            title: "トレカ C",
            tags: [GoodsTag(id: UUID(), name: "会場限定")]
        )
        let filter = GoodsCollectionFilter(
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            tagNames: ["会場限定", "未開封"]
        )

        XCTAssertTrue(filter.matches(matching))
        XCTAssertFalse(filter.matches(wrongTag))
        XCTAssertFalse(filter.matches(wrongGroup))
        XCTAssertTrue(filter.isActive)
        XCTAssertEqual(filter.activeCount, 4)
    }

    func testTileActionPolicySeparatesOwnerAndRemoteActions() {
        let viewerID = UUID()
        let ownedPolicy = GoodsTileActionPolicy(
            viewerID: viewerID,
            itemOwnerID: viewerID,
            canAddToExchangeList: true,
            canCreateIndividualListing: true,
            canEdit: true,
            canHide: true,
            canDelete: true,
            canReport: true
        )
        let remotePolicy = GoodsTileActionPolicy(
            viewerID: viewerID,
            itemOwnerID: UUID(),
            canAddToExchangeList: true,
            canCreateIndividualListing: true,
            canEdit: true,
            canHide: true,
            canDelete: true,
            canReport: true
        )
        let signedOutPolicy = GoodsTileActionPolicy(
            viewerID: nil,
            itemOwnerID: UUID(),
            canAddToExchangeList: true,
            canCreateIndividualListing: true,
            canEdit: true,
            canHide: true,
            canDelete: true,
            canReport: true
        )

        XCTAssertEqual(ownedPolicy.actions, [.detail, .edit, .createIndividualListing, .hide, .delete])
        XCTAssertEqual(remotePolicy.actions, [.detail, .addToExchangeList, .report])
        XCTAssertEqual(signedOutPolicy.actions, [.detail])
    }
}
