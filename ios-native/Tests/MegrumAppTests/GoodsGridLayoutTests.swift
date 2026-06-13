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

    func testGoodsGridUsesReactNativeCardSpacingAndRatio() {
        XCTAssertEqual(GoodsGridLayout.columnSpacing, 10)
        XCTAssertEqual(GoodsGridLayout.rowSpacing, 10)
        XCTAssertEqual(GoodsGridLayout.tileCornerRadius, 13)
        XCTAssertEqual(GoodsGridLayout.tileAspectRatio, 1 / 1.34, accuracy: 0.0001)
        XCTAssertEqual(GoodsTileCollectionCardMetrics.tagMaxWidthRatio, 0.78)
        XCTAssertEqual(GoodsTileCollectionCardMetrics.glyphFontSize, 32)
    }

    func testInventoryQuickActionsMatchOwnerMenuOrder() {
        XCTAssertEqual(GoodsQuickActionKind.inventoryActions, [.edit, .moveToKeep, .tag, .delete])
        XCTAssertEqual(GoodsQuickActionKind.edit.title, "編集する")
        XCTAssertEqual(GoodsQuickActionKind.moveToKeep.title, "自分用キープへ")
        XCTAssertEqual(GoodsQuickActionKind.tag.title, "タグをつける")
        XCTAssertEqual(GoodsQuickActionKind.delete.title, "削除する")
        XCTAssertNil(GoodsQuickActionKind.edit.role)
        XCTAssertNotNil(GoodsQuickActionKind.delete.role)
    }

    func testSelectionFooterUsesFixedGlassActionMetrics() {
        XCTAssertEqual(GoodsSelectionFooterMetrics.bottomPadding, 12)
        XCTAssertEqual(GoodsSelectionFooterMetrics.horizontalPadding, 18)
        XCTAssertEqual(GoodsSelectionFooterMetrics.cornerRadius, 28)
        XCTAssertEqual(GoodsSelectionFooterMetrics.actionHeight, 52)
        XCTAssertEqual(GoodsSelectionFooterMetrics.actionSpacing, 10)
    }

    func testGridContextLabelsFollowEntryKind() {
        XCTAssertEqual(GoodsGridContext(entryKind: .inventory).statusLabel, "譲る候補")
        XCTAssertEqual(GoodsGridContext(entryKind: .inventory).quantityLabel, "マイグッズ数")
        XCTAssertEqual(GoodsGridContext(entryKind: .wish).statusLabel, "探し中")
        XCTAssertEqual(GoodsGridContext(entryKind: .wish).quantityLabel, "希望数")
    }

    func testInventoryAndWishUseImageOnlyCardsLikeReactNative() {
        XCTAssertTrue(GoodsTileCardPolicy.usesImageOnlyCard(for: .inventory))
        XCTAssertTrue(GoodsTileCardPolicy.usesImageOnlyCard(for: .wish))
        XCTAssertFalse(GoodsTileCardPolicy.usesImageOnlyCard(for: .tradeCandidate))
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

    func testCollectionCardStyleUsesStableGlyphAndTagLine() {
        let item = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            title: "カリナ 春ver.",
            tags: [
                GoodsTag(id: UUID(), name: "aespa"),
                GoodsTag(id: UUID(), name: "トレカ")
            ]
        )
        let untagged = GoodsItem(id: UUID(), ownerID: UUID(), title: "ジョンウ ラキドロ")

        XCTAssertEqual(GoodsTileCollectionCardStyle.glyph(for: item), "K")
        XCTAssertEqual(GoodsTileCollectionCardStyle.tagLine(for: item), "# aespa # トレカ")
        XCTAssertEqual(GoodsTileCollectionCardStyle.glyph(for: untagged), "J")
        XCTAssertEqual(GoodsTileCollectionCardStyle.tagLine(for: untagged), "タグ未設定")
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

    func testCollectionFilterUsesCompactChipMetrics() {
        XCTAssertEqual(CollectionScreenLayoutMetrics.mainStackSpacing, 12)
        XCTAssertEqual(CollectionScreenLayoutMetrics.topPadding, 14)
        XCTAssertEqual(CollectionScreenLayoutMetrics.headerAccessoryVerticalPadding, 2)
        XCTAssertEqual(CollectionScreenLayoutMetrics.filterBarSpacing, 6)
        XCTAssertEqual(CollectionScreenLayoutMetrics.filterRowLabelWidth, 64)
        XCTAssertEqual(CollectionScreenLayoutMetrics.filterRowChipSpacing, 7)
        XCTAssertEqual(CollectionScreenLayoutMetrics.filterChipHeight, 32)
        XCTAssertEqual(CollectionScreenLayoutMetrics.filterChipHorizontalPadding, 12)
        XCTAssertEqual(CollectionScreenLayoutMetrics.filterChipFontSize, 12.5)
        XCTAssertEqual(CollectionScreenLayoutMetrics.filterChipGlassSelectedOpacity, 0.22)
        XCTAssertEqual(CollectionScreenLayoutMetrics.filterChipGlassIdleOpacity, 0.10)
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
