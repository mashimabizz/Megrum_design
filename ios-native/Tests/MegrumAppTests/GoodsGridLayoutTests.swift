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

    func testGridColumnPreferenceStorePersistsColumnsPerUserAndEntryKind() throws {
        let suiteName = "megrum.grid-columns.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let viewerID = UUID()
        let inventoryContext = GoodsGridColumnPreferenceContext(entryKind: .inventory, viewerID: viewerID)
        let wishContext = GoodsGridColumnPreferenceContext(entryKind: .wish, viewerID: viewerID)

        XCTAssertEqual(GoodsGridColumnPreferenceStore.load(context: inventoryContext, defaults: defaults), 3)

        GoodsGridColumnPreferenceStore.save(columns: 5, context: inventoryContext, defaults: defaults)
        GoodsGridColumnPreferenceStore.save(columns: 4, context: wishContext, defaults: defaults)

        XCTAssertEqual(GoodsGridColumnPreferenceStore.load(context: inventoryContext, defaults: defaults), 5)
        XCTAssertEqual(GoodsGridColumnPreferenceStore.load(context: wishContext, defaults: defaults), 4)
    }

    func testGridColumnPreferenceStoreClampsUnsupportedColumnsAndSeparatesUsers() throws {
        let suiteName = "megrum.grid-columns.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let firstUserContext = GoodsGridColumnPreferenceContext(entryKind: .inventory, viewerID: UUID())
        let secondUserContext = GoodsGridColumnPreferenceContext(entryKind: .inventory, viewerID: UUID())

        GoodsGridColumnPreferenceStore.save(columns: 9, context: firstUserContext, defaults: defaults)

        XCTAssertEqual(GoodsGridColumnPreferenceStore.load(context: firstUserContext, defaults: defaults), 5)
        XCTAssertEqual(GoodsGridColumnPreferenceStore.load(context: secondUserContext, defaults: defaults), 3)
    }

    func testRemoteGoodsImageLoadingRetriesBeforeFallback() {
        XCTAssertEqual(GoodsRemoteImageLoadingPolicy.maximumAttempts, 4)
        XCTAssertEqual(GoodsRemoteImageLoadingPolicy.retryDelaysNanoseconds.first, 0)
        XCTAssertGreaterThanOrEqual(GoodsRemoteImageLoadingPolicy.requestTimeout, 10)
        XCTAssertEqual(GoodsRemoteImageLoadingPolicy.preloadMaxConcurrentRequests, 4)
    }

    func testGoodsImageSkeletonPresentationStateTracksPulsingOpacity() {
        var state = GoodsImageSkeletonPresentationState()

        XCTAssertFalse(state.isPulsing)
        XCTAssertEqual(state.opacity, 1)

        state.startPulsing()

        XCTAssertTrue(state.isPulsing)
        XCTAssertEqual(state.opacity, 0.72)
    }

    func testRemoteGoodsImageDataLoaderCachesFileData() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("megrum-goods-image-\(UUID().uuidString).bin")
        let data = Data("megrum-image".utf8)
        try data.write(to: url)

        let firstLoad = try await GoodsRemoteImageDataLoader.loadData(from: url)
        try FileManager.default.removeItem(at: url)
        let cachedLoad = try await GoodsRemoteImageDataLoader.loadData(from: url)

        XCTAssertEqual(firstLoad, data)
        XCTAssertEqual(cachedLoad, data)
    }

    func testRemoteGoodsImageDataLoaderPreloadsFileData() async throws {
        await GoodsRemoteImageDataCache.shared.removeAll()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("megrum-goods-preload-\(UUID().uuidString).bin")
        let data = Data("megrum-preload-image".utf8)
        try data.write(to: url)
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        await GoodsRemoteImageDataLoader.preload(urls: [url, url], maxConcurrentRequests: 2)

        let cached = await GoodsRemoteImageDataCache.shared.data(for: url)
        XCTAssertEqual(cached, data)
    }

    func testOwnedGoodsImagePreloadPolicyUsesInventoryAndWishURLsWithoutDuplicates() throws {
        let sharedURL = try XCTUnwrap(URL(string: "https://example.com/shared.jpg"))
        let inventoryOnlyURL = try XCTUnwrap(URL(string: "https://example.com/inventory.jpg"))
        let wishOnlyURL = try XCTUnwrap(URL(string: "https://example.com/wish.jpg"))
        let ownerID = UUID()

        let urls = OwnedGoodsImagePreloadPolicy.urls(
            inventory: [
                GoodsItem(id: UUID(), ownerID: ownerID, title: "マイグッズ1", imageURL: sharedURL),
                GoodsItem(id: UUID(), ownerID: ownerID, title: "マイグッズ2", imageURL: inventoryOnlyURL)
            ],
            wishes: [
                WishItem(id: UUID(), ownerID: ownerID, title: "ほしいもの1", imageURL: sharedURL),
                WishItem(id: UUID(), ownerID: ownerID, title: "ほしいもの2", imageURL: wishOnlyURL)
            ],
            limitPerCollection: 2
        )

        XCTAssertEqual(urls, [sharedURL, inventoryOnlyURL, wishOnlyURL])
    }

    func testRemoteGoodsImageDataLoaderRejectsEmptyFileData() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("megrum-empty-goods-image-\(UUID().uuidString).bin")
        try Data().write(to: url)
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        do {
            _ = try await GoodsRemoteImageDataLoader.loadData(from: url)
            XCTFail("Expected empty image data to fail.")
        } catch GoodsRemoteImageLoadError.emptyData {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGoodsGridUsesReactNativeCardSpacingAndRatio() {
        XCTAssertEqual(GoodsGridLayout.columnSpacing, 10)
        XCTAssertEqual(GoodsGridLayout.rowSpacing, 10)
        XCTAssertEqual(GoodsGridLayout.tileCornerRadius, 13)
        XCTAssertEqual(GoodsGridLayout.tileAspectRatio, 1 / 1.34, accuracy: 0.0001)
        XCTAssertEqual(GoodsTileCollectionCardMetrics.tagMaxWidthRatio, 0.78)
        XCTAssertEqual(GoodsTileCollectionCardMetrics.glyphFontSize, 32)
    }

    func testGoodsGridPresentationStateTracksDetailReportAndActionMessage() {
        let item = GoodsItem(id: UUID(), ownerID: UUID(), title: "サナ トレカ")
        var state = GoodsGridPresentationState()

        state.showDetail(item)
        state.showReport(item)
        state.showActionMessage("未接続です")

        XCTAssertEqual(state.detailItem?.id, item.id)
        XCTAssertEqual(state.reportItem?.id, item.id)
        XCTAssertEqual(state.actionMessage, "未接続です")
        XCTAssertTrue(state.hasActionMessage)

        state.clearReport()
        state.clearActionMessage()

        XCTAssertNil(state.reportItem)
        XCTAssertNil(state.actionMessage)
        XCTAssertFalse(state.hasActionMessage)
    }

    func testGoodsGridPrimaryTapPolicyKeepsExistingDestinationPriority() {
        let viewerID = UUID()
        let ownerID = UUID()

        XCTAssertEqual(
            GoodsGridPrimaryTapPolicy(
                isSelectionMode: true,
                canToggleSelection: true,
                canOpenItem: true,
                canOpenOwnerProfile: true,
                viewerID: viewerID,
                itemOwnerID: ownerID
            ).destination,
            .toggleSelection
        )

        XCTAssertEqual(
            GoodsGridPrimaryTapPolicy(
                isSelectionMode: true,
                canToggleSelection: false,
                canOpenItem: true,
                canOpenOwnerProfile: true,
                viewerID: viewerID,
                itemOwnerID: ownerID
            ).destination,
            .openItem
        )

        XCTAssertEqual(
            GoodsGridPrimaryTapPolicy(
                isSelectionMode: false,
                canToggleSelection: false,
                canOpenItem: false,
                canOpenOwnerProfile: true,
                viewerID: viewerID,
                itemOwnerID: ownerID
            ).destination,
            .openOwnerProfile(ownerID)
        )

        XCTAssertEqual(
            GoodsGridPrimaryTapPolicy(
                isSelectionMode: false,
                canToggleSelection: false,
                canOpenItem: false,
                canOpenOwnerProfile: true,
                viewerID: ownerID,
                itemOwnerID: ownerID
            ).destination,
            .showDetail
        )

        XCTAssertEqual(
            GoodsGridPrimaryTapPolicy(
                isSelectionMode: false,
                canToggleSelection: false,
                canOpenItem: false,
                canOpenOwnerProfile: true,
                viewerID: nil,
                itemOwnerID: ownerID
            ).destination,
            .openOwnerProfile(ownerID)
        )
    }

    func testGoodsGridTileActionPolicyKeepsOwnerRemoteAndFallbackDestinations() {
        let viewerID = UUID()
        let ownerID = UUID()
        let title = "サナ トレカ"
        let ownerPolicy = GoodsGridTileActionPolicy(
            viewerID: viewerID,
            itemOwnerID: viewerID,
            itemTitle: title,
            canAddToExchangeList: false,
            canCreateIndividualListing: true,
            canEdit: true,
            canHide: true,
            canDelete: true,
            canReport: true
        )
        let remotePolicy = GoodsGridTileActionPolicy(
            viewerID: viewerID,
            itemOwnerID: ownerID,
            itemTitle: title,
            canAddToExchangeList: true,
            canCreateIndividualListing: false,
            canEdit: true,
            canHide: true,
            canDelete: true,
            canReport: true
        )
        let unavailablePolicy = GoodsGridTileActionPolicy(
            viewerID: viewerID,
            itemOwnerID: ownerID,
            itemTitle: title,
            canAddToExchangeList: false,
            canCreateIndividualListing: false,
            canEdit: false,
            canHide: false,
            canDelete: false,
            canReport: false
        )

        XCTAssertEqual(ownerPolicy.destination(for: .detail), .showDetail)
        XCTAssertEqual(ownerPolicy.destination(for: .edit), .edit)
        XCTAssertEqual(ownerPolicy.destination(for: .createIndividualListing), .createIndividualListing)
        XCTAssertEqual(ownerPolicy.destination(for: .delete), .delete)
        XCTAssertEqual(remotePolicy.destination(for: .addToExchangeList), .addToExchangeList)
        XCTAssertEqual(remotePolicy.destination(for: .report), .showReport)
        XCTAssertEqual(
            unavailablePolicy.destination(for: .edit),
            .showActionMessage("「サナ トレカ」の編集は、自分のマイグッズ/ほしいものでのみ使えます。")
        )
        XCTAssertEqual(
            unavailablePolicy.destination(for: .delete),
            .showActionMessage("「サナ トレカ」を削除する処理は、自分のマイグッズ/ほしいものでのみ使えます。")
        )
    }

    func testInventoryQuickActionsMatchOwnerMenuOrder() {
        XCTAssertEqual(GoodsQuickActionKind.inventoryActions, [.edit, .tag, .share, .delete])
        XCTAssertEqual(GoodsQuickActionKind.wishActions, [.edit, .tag, .share, .delete])
        XCTAssertEqual(GoodsQuickActionKind.tag.title, "シリーズ設定")
        XCTAssertEqual(GoodsQuickActionKind.share.title, "Xで投稿")
        XCTAssertEqual(GoodsQuickActionKind.delete.title, "削除")
        XCTAssertNil(GoodsQuickActionKind.tag.role)
        XCTAssertNil(GoodsQuickActionKind.share.role)
        XCTAssertNotNil(GoodsQuickActionKind.delete.role)
    }

    func testBulkSelectionPolicyAllowsWishAndEditableInventory() {
        XCTAssertTrue(GoodsCollectionBulkActionPolicy.allowsOwnedSelection(
            entryKind: .wish,
            inventoryStatus: nil,
            hasAppState: true
        ))
        XCTAssertTrue(GoodsCollectionBulkActionPolicy.allowsOwnedSelection(
            entryKind: .inventory,
            inventoryStatus: .active,
            hasAppState: true
        ))
        XCTAssertTrue(GoodsCollectionBulkActionPolicy.allowsOwnedSelection(
            entryKind: .inventory,
            inventoryStatus: .keep,
            hasAppState: true
        ))
        XCTAssertFalse(GoodsCollectionBulkActionPolicy.allowsOwnedSelection(
            entryKind: .inventory,
            inventoryStatus: .traded,
            hasAppState: true
        ))
        XCTAssertFalse(GoodsCollectionBulkActionPolicy.allowsOwnedSelection(
            entryKind: .wish,
            inventoryStatus: nil,
            hasAppState: false
        ))
    }

    func testSelectionFooterUsesFixedGlassActionMetrics() {
        XCTAssertEqual(GoodsSelectionFooterMetrics.bottomPadding, 106)
        XCTAssertEqual(GoodsSelectionFooterMetrics.horizontalPadding, 18)
        XCTAssertEqual(GoodsSelectionFooterMetrics.cornerRadius, 28)
        XCTAssertEqual(GoodsSelectionFooterMetrics.actionHeight, 52)
        XCTAssertEqual(GoodsSelectionFooterMetrics.actionSpacing, 10)
    }

    func testQuickActionPresentationUsesSharedSoftPopupMetrics() {
        XCTAssertEqual(GoodsQuickActionPresentationMetrics.backdropOpacity, 0.12)
        XCTAssertEqual(GoodsQuickActionPresentationMetrics.panelTransitionScale, 0.96)
        XCTAssertEqual(GoodsQuickActionPresentationMetrics.panelAnimationResponse, 0.34)
        XCTAssertEqual(GoodsQuickActionPresentationMetrics.panelAnimationDampingFraction, 0.86)
    }

    func testQuickActionPreviewUsesStableImagePreviewMetrics() {
        XCTAssertEqual(GoodsQuickActionPreviewMetrics.width, 50)
        XCTAssertEqual(GoodsQuickActionPreviewMetrics.height, 64)
        XCTAssertEqual(GoodsQuickActionPreviewMetrics.cornerRadius, 14)
        XCTAssertEqual(GoodsQuickActionPreviewMetrics.fallbackGlyphFontSize, 24)
        XCTAssertEqual(TagCandidatePreviewMetrics.width, 232)
    }

    func testQuickActionHeaderUsesMasterNamesAndTags() {
        let item = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            title: "サナ トレカ",
            tags: [
                GoodsTag(id: UUID(), name: "会場限定"),
                GoodsTag(id: UUID(), name: "未開封"),
                GoodsTag(id: UUID(), name: "サイン入り"),
                GoodsTag(id: UUID(), name: " 予備 ")
            ]
        )

        let header = GoodsQuickActionHeaderPresentation(
            item: item,
            l1Name: "TWICE",
            l2Name: "サナ"
        )

        XCTAssertEqual(header.masterLine, "TWICE　サナ")
        XCTAssertEqual(header.tagLine, "#会場限定 #未開封 #サイン入り +1")
    }

    func testQuickActionHeaderFallsBackWhenMasterOrTagsAreMissing() {
        let item = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            title: "グループ未設定トレカ"
        )

        let header = GoodsQuickActionHeaderPresentation(item: item)

        XCTAssertEqual(header.masterLine, "グループ未設定トレカ")
        XCTAssertEqual(header.tagLine, "未設定")
    }

    func testDeleteConfirmationPresentationMatchesOshiDeleteCalloutCopy() {
        let item = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            title: "サナ トレカ"
        )

        XCTAssertEqual(GoodsCollectionDeleteConfirmationPresentation.title, OshiSettingsPresentationText.removeGroupConfirmationTitle)
        XCTAssertEqual(GoodsCollectionDeleteConfirmationPresentation.destructiveTitle, OshiSettingsPresentationText.removeGroupConfirmationAction)
        XCTAssertEqual(GoodsCollectionDeleteConfirmationPresentation.message(for: item), "「サナ トレカ」を削除します。")
        XCTAssertEqual(GoodsCollectionDeleteConfirmationPresentation.message(selectedCount: 3), "3件のグッズを削除します。")
    }

    func testCollectionChromePolicyPinsWishHeaderWhenShown() {
        XCTAssertTrue(GoodsCollectionChromePolicy.usesPinnedTopChrome(entryKind: .inventory, showsHeader: true))
        XCTAssertTrue(GoodsCollectionChromePolicy.usesPinnedTopChrome(entryKind: .inventory, showsHeader: false))
        XCTAssertTrue(GoodsCollectionChromePolicy.usesPinnedTopChrome(entryKind: .wish, showsHeader: true))
        XCTAssertFalse(GoodsCollectionChromePolicy.usesPinnedTopChrome(entryKind: .wish, showsHeader: false))
    }

    func testWishCollectionUsesSwipePagingWithSharedPinnedHeader() {
        XCTAssertFalse(WishCollectionPresentationPolicy.usesDirectSectionRendering)
        XCTAssertTrue(WishCollectionPresentationPolicy.usesSwipePaging)
    }

    func testWishCollectionPresentationStateConsumesRequestedSection() {
        var state = WishCollectionPresentationState()

        XCTAssertFalse(state.applyRequestedSection(nil))
        XCTAssertEqual(state.selectedSection, .wishes)

        XCTAssertTrue(state.applyRequestedSection(.listings))
        XCTAssertEqual(state.selectedSection, .listings)
        XCTAssertTrue(state.applyRequestedSection(.wishes))
        XCTAssertEqual(state.selectedSection.navigationTitle, "ほしいもの")
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

    func testTilePresentationUsesTradedInventoryStatus() {
        let item = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            status: .traded,
            title: "譲渡済みトレカ"
        )

        let presentation = GoodsTilePresentation(item: item, context: .inventory, isBusy: false)

        XCTAssertEqual(presentation.statusLabel, "過去に譲った")
        XCTAssertEqual(presentation.tileMetadataText, "過去に譲った ・ 1点")
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
        XCTAssertEqual(GoodsTileCollectionCardStyle.tagLine(for: untagged), "未設定")
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
            groupIDs: [groupID],
            goodsTypeIDs: [goodsTypeID],
            tagNames: ["会場限定", "未開封"]
        )

        XCTAssertTrue(filter.matches(matching))
        // シリーズは OR 条件（どれか1つ合致すればOK）
        XCTAssertFalse(filter.matches(wrongTag))
        XCTAssertFalse(filter.matches(wrongGroup))
        XCTAssertTrue(filter.isActive)
        XCTAssertEqual(filter.activeCount, 4)

        // グループ複数選択は OR：どちらかのグループなら合致
        let orFilter = GoodsCollectionFilter(groupIDs: [groupID, wrongGroup.groupID!])
        XCTAssertTrue(orFilter.matches(matching))
        XCTAssertTrue(orFilter.matches(wrongGroup))
    }

    func testCollectionFilterChoicesOnlyIncludeValuesUsedByItems() {
        let groupA = OshiGroup(id: UUID(), name: "TWICE")
        let groupB = OshiGroup(id: UUID(), name: "aespa")
        let unusedGroup = OshiGroup(id: UUID(), name: "NCT")
        let cardType = GoodsType(id: UUID(), name: "トレカ")
        let acrylicType = GoodsType(id: UUID(), name: "アクスタ")
        let unusedType = GoodsType(id: UUID(), name: "生写真")
        let items = [
            GoodsItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: groupB.id,
                goodsTypeID: acrylicType.id,
                title: "アクスタ A"
            ),
            GoodsItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: groupA.id,
                goodsTypeID: cardType.id,
                title: "トレカ A"
            )
        ]

        let groups = GoodsCollectionFilterChoices.groups(
            items: items,
            allGroups: [groupA, groupB, unusedGroup]
        )
        let goodsTypes = GoodsCollectionFilterChoices.goodsTypes(
            items: items,
            allGoodsTypes: [cardType, acrylicType, unusedType]
        )

        XCTAssertEqual(groups.map(\.name), ["TWICE", "aespa"])
        XCTAssertEqual(goodsTypes.map(\.name), ["トレカ", "アクスタ"])
    }

    func testCollectionTagChoicesFollowSelectedGroupAndGoodsType() {
        let groupA = UUID()
        let groupB = UUID()
        let cardType = UUID()
        let acrylicType = UUID()
        let items = [
            GoodsItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: groupA,
                goodsTypeID: cardType,
                title: "トレカ A",
                tags: [
                    GoodsTag(id: UUID(), name: "2026 LIVE"),
                    GoodsTag(id: UUID(), name: " aespa ")
                ]
            ),
            GoodsItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: groupA,
                goodsTypeID: acrylicType,
                title: "アクスタ A",
                tags: [GoodsTag(id: UUID(), name: "アクスタ")]
            ),
            GoodsItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: groupB,
                goodsTypeID: cardType,
                title: "トレカ B",
                tags: [GoodsTag(id: UUID(), name: "NCT")]
            )
        ]

        let tagNames = GoodsCollectionFilterChoices.tagNames(
            items: items,
            selectedGroupIDs: [groupA],
            selectedGoodsTypeIDs: [cardType]
        )

        XCTAssertEqual(tagNames, ["2026 LIVE", "aespa"])
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

    func testContextMenuPolicyHidesReadOnlyDetailOnlyCards() {
        XCTAssertFalse(GoodsTileContextMenuPolicy.isEnabled(actions: [.detail], hasLongPressSelection: false))
        XCTAssertFalse(GoodsTileContextMenuPolicy.isEnabled(actions: [.detail, .edit], hasLongPressSelection: true))
        XCTAssertTrue(GoodsTileContextMenuPolicy.isEnabled(actions: [.detail, .report], hasLongPressSelection: false))
    }
}
