@testable import MegrumApp
import MegrumCore
import XCTest

final class IndividualListingDraftTests: XCTestCase {
    func testCreateDraftPreselectsWishAndBuildsBoundedInput() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let have = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "譲るトレカ",
            quantity: 3
        )
        let wish = WishItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "ほしいトレカ"
        )

        var draft = IndividualListingDraft(mode: .create(preselectedWishID: wish.id))
        draft.toggleHave(have.id, maxQuantity: have.quantity)
        draft.setHaveQuantity(have.id, quantity: 10, maxQuantity: have.quantity)
        draft.setWishQuantity(wish.id, quantity: 120)
        draft.note = "  会場で相談  "

        let input = try XCTUnwrap(draft.createInput(inventory: [have], wishes: [wish]))

        XCTAssertEqual(input.haveItems, [ListingItemQuantity(itemID: have.id, quantity: 3)])
        XCTAssertEqual(input.wishItems, [ListingItemQuantity(itemID: wish.id, quantity: 99)])
        XCTAssertEqual(input.haveLogic, .all)
        XCTAssertEqual(input.wishLogic, .one)
        XCTAssertEqual(input.exchangeType, .any)
        XCTAssertEqual(
            input.note,
            """
            会場で相談
            交換手段: どちらもOK / 都道府県: 東京都 / 場所メモ: 相談 / 日程: 相談して決める / 送料: 要相談 / 発送目安: 2〜4日以内 / 条件外打診: 可
            """
        )
    }

    func testDraftRestoresExchangeSummaryWhenEditing() throws {
        let listingID = UUID()
        let original = IndividualListing(
            id: listingID,
            ownerID: UUID(),
            haves: [],
            note: """
            メモ本文
            交換手段: 現地交換 / 都道府県: 大阪府 / 場所メモ: 京セラ周辺 / 日程: 終演後 / 条件外打診: 不可
            """,
            options: []
        )

        let draft = IndividualListingDraft(mode: .edit(original))

        XCTAssertEqual(draft.note, "メモ本文")
        XCTAssertEqual(draft.handoffMethod, .local)
        XCTAssertEqual(draft.localPrefecture, "大阪府")
        XCTAssertEqual(draft.localPlaceMemo, "京セラ周辺")
        XCTAssertFalse(draft.acceptsOutsideCondition)
    }

    func testIndividualListingListPresentationUsesListSpecificLabels() {
        XCTAssertEqual(IndividualListingListPresentation.optionTitle(index: 1), "選択肢1")
        XCTAssertEqual(IndividualListingListPresentation.handoffMethodTitle(for: .local), "現地交換")
        XCTAssertEqual(IndividualListingListPresentation.handoffMethodTitle(for: .mail), "郵送交換")
        XCTAssertEqual(IndividualListingListPresentation.handoffMethodTitle(for: .both), "現地交換・郵送交換のどちらもOK")

        let listingID = UUID()
        let singleGoodsOption = IndividualListingWishOption(
            id: UUID(),
            listingID: listingID,
            position: 1,
            wishes: [ListingItemQuantity(itemID: UUID(), quantity: 1)],
            logic: .one
        )
        let multipleGoodsOption = IndividualListingWishOption(
            id: UUID(),
            listingID: listingID,
            position: 2,
            wishes: [
                ListingItemQuantity(itemID: UUID(), quantity: 1),
                ListingItemQuantity(itemID: UUID(), quantity: 1)
            ],
            logic: .one
        )
        let allGoodsOption = IndividualListingWishOption(
            id: UUID(),
            listingID: listingID,
            position: 3,
            wishes: [
                ListingItemQuantity(itemID: UUID(), quantity: 1),
                ListingItemQuantity(itemID: UUID(), quantity: 1)
            ],
            logic: .all
        )
        let cashOption = IndividualListingWishOption(
            id: UUID(),
            listingID: listingID,
            position: 4,
            wishes: [],
            logic: .one,
            isCashOffer: true,
            cashAmount: 1_500
        )

        XCTAssertNil(IndividualListingListPresentation.optionLogicTitle(for: singleGoodsOption))
        XCTAssertEqual(IndividualListingListPresentation.optionLogicTitle(for: multipleGoodsOption), "どれか1つだけ")
        XCTAssertEqual(IndividualListingListPresentation.optionLogicTitle(for: allGoodsOption), "全部ほしい")
        XCTAssertNil(IndividualListingListPresentation.optionLogicTitle(for: cashOption))
    }

    func testIndividualListingInputNormalizerClampsQuantitiesAndTrimsNote() {
        let haveID = UUID()
        let wishID = UUID()
        let input = IndividualListingCreateInput(
            haveItems: [ListingItemQuantity(itemID: haveID, quantity: 0)],
            wishItems: [ListingItemQuantity(itemID: wishID, quantity: 120)],
            note: "  会場で相談  "
        )

        let normalized = IndividualListingInputNormalizer.normalized(input)

        XCTAssertTrue(normalized.hasReceivableCondition)
        XCTAssertEqual(normalized.haveItems, [ListingItemQuantity(itemID: haveID, quantity: 1)])
        XCTAssertEqual(normalized.wishItems, [ListingItemQuantity(itemID: wishID, quantity: 99)])
        XCTAssertEqual(normalized.note, "会場で相談")
    }

    func testIndividualListingInputNormalizerDropsBlankNoteAndKeepsConditionOnlyWishes() {
        let input = IndividualListingCreateInput(
            haveItems: [ListingItemQuantity(itemID: UUID(), quantity: 1)],
            wishItems: [],
            wishGroupID: UUID(),
            note: "   "
        )

        let normalized = IndividualListingInputNormalizer.normalized(input)

        XCTAssertTrue(normalized.hasReceivableCondition)
        XCTAssertNil(normalized.note)
    }

    func testPreviewListingExchangeSummaryUsesStoredSchedule() throws {
        let listing = try XCTUnwrap(NativePreviewData.listings.first)
        let summary = try XCTUnwrap(IndividualListingExchangeSummary.extract(from: listing.note).summary)

        XCTAssertEqual(summary.localSchedule, IndividualListingExchangeSummary.defaultLocalSchedule)
        XCTAssertEqual(summary.localDetailText, "東京都 / 東京ドーム周辺 / 相談して決める")
    }

    func testDraftRejectsDoubleOrMatrix() {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let inventory = [
            GoodsItem(id: UUID(), ownerID: UUID(), groupID: groupID, goodsTypeID: goodsTypeID, title: "譲るA"),
            GoodsItem(id: UUID(), ownerID: UUID(), groupID: groupID, goodsTypeID: goodsTypeID, title: "譲るB")
        ]
        let wishes = [
            WishItem(id: UUID(), ownerID: UUID(), groupID: groupID, goodsTypeID: goodsTypeID, title: "求めるA"),
            WishItem(id: UUID(), ownerID: UUID(), groupID: groupID, goodsTypeID: goodsTypeID, title: "求めるB")
        ]

        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
        inventory.forEach { draft.toggleHave($0.id) }
        wishes.forEach { draft.toggleWish($0.id) }
        draft.haveLogic = .one
        draft.wishLogic = .one

        XCTAssertEqual(
            draft.validationMessage(inventory: inventory, wishes: wishes),
            "両方を「どれか1つだけ」にする場合は、片方を1件にしてください"
        )
    }

    func testDraftUsesMarketAvailableQuantityForHaveLimit() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let have = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "一部ロック済みの譲るトレカ",
            quantity: 3,
            lockedQuantity: 2
        )
        let wish = WishItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "ほしいトレカ"
        )

        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
        draft.toggleHave(have.id, maxQuantity: have.marketAvailableQuantity)
        draft.setHaveQuantity(have.id, quantity: 3, maxQuantity: have.marketAvailableQuantity)
        draft.toggleWish(wish.id)

        let input = try XCTUnwrap(draft.createInput(inventory: [have], wishes: [wish]))

        XCTAssertEqual(have.marketAvailableQuantity, 1)
        XCTAssertEqual(input.haveItems, [ListingItemQuantity(itemID: have.id, quantity: 1)])
    }

    func testEditDraftAllowsOriginalLockedHaveQuantity() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let have = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "編集中の譲るトレカ",
            quantity: 2,
            lockedQuantity: 2
        )
        let wish = WishItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "ほしいトレカ"
        )
        let listingID = UUID()
        let original = IndividualListing(
            id: listingID,
            ownerID: UUID(),
            haves: [ListingItemQuantity(itemID: have.id, quantity: 2)],
            options: [
                IndividualListingWishOption(
                    id: UUID(),
                    listingID: listingID,
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: wish.id, quantity: 1)]
                )
            ]
        )

        let draft = IndividualListingDraft(mode: .edit(original))
        let input = try XCTUnwrap(draft.createInput(inventory: [have], wishes: [wish]))

        XCTAssertEqual(have.marketAvailableQuantity, 0)
        XCTAssertNil(draft.validationMessage(inventory: [have], wishes: [wish]))
        XCTAssertEqual(draft.maxHaveQuantity(for: have), 2)
        XCTAssertEqual(input.haveItems, [ListingItemQuantity(itemID: have.id, quantity: 2)])
    }

    func testConditionDraftTracksMemberTagAndQuantityState() {
        let firstGroupID = UUID()
        let secondGroupID = UUID()
        let memberAID = UUID()
        let memberBID = UUID()

        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
        draft.setConditionGroupID(firstGroupID)
        draft.toggleConditionMember(memberAID)
        draft.toggleConditionMember(memberBID)
        draft.setExcludesSelectedConditionMembers(true)
        draft.toggleConditionTag("会場限定")
        draft.setConditionQuantity(4)

        XCTAssertEqual(draft.conditionGroupID, firstGroupID)
        XCTAssertEqual(draft.conditionMemberIDs, Set([memberAID, memberBID]))
        XCTAssertTrue(draft.excludesSelectedConditionMembers)
        XCTAssertEqual(draft.conditionTagNames, ["会場限定"])
        XCTAssertEqual(draft.conditionQuantity, 4)
        XCTAssertTrue(draft.usesConditionLogicChoice)

        draft.setConditionGroupID(secondGroupID)

        XCTAssertEqual(draft.conditionGroupID, secondGroupID)
        XCTAssertTrue(draft.conditionMemberIDs.isEmpty)
        XCTAssertFalse(draft.excludesSelectedConditionMembers)
        XCTAssertTrue(draft.conditionTagNames.isEmpty)
        XCTAssertEqual(draft.conditionQuantity, 4)
    }

    func testConditionTagBuilderDeduplicatesAndFiltersByGroup() {
        let targetGroupID = UUID()
        let otherGroupID = UUID()
        let sharedID = UUID()
        let targetGoods = GoodsItem(
            id: sharedID,
            ownerID: UUID(),
            groupID: targetGroupID,
            title: "譲るトレカ",
            tags: [
                GoodsTag(id: UUID(), name: " 会場限定 "),
                GoodsTag(id: UUID(), name: "会場限定"),
                GoodsTag(id: UUID(), name: "終演後OK")
            ]
        )
        let targetWish = WishItem(
            id: sharedID,
            ownerID: UUID(),
            groupID: targetGroupID,
            title: "ほしいトレカ",
            tags: [
                GoodsTag(id: UUID(), name: "会場限定"),
                GoodsTag(id: UUID(), name: "ファンミ")
            ]
        )
        let otherGoods = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: otherGroupID,
            title: "別グループ",
            tags: [GoodsTag(id: UUID(), name: "別タグ")]
        )

        let builder = IndividualListingConditionTagBuilder(
            inventory: [targetGoods, otherGoods],
            wishes: [targetWish],
            selectedGroupID: targetGroupID
        )

        XCTAssertEqual(builder.candidateNames(), ["会場限定", "終演後OK", "ファンミ"])
        XCTAssertEqual(builder.previewItemsByTag()["会場限定"]?.count, 2)
        XCTAssertNil(builder.previewItemsByTag()["別タグ"])
    }

    func testEditDraftBuildsLocalUpdatedListing() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let have = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "譲るトレカ",
            quantity: 4
        )
        let wish = WishItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "ほしいトレカ"
        )
        let listingID = UUID()
        let optionID = UUID()
        let original = IndividualListing(
            id: listingID,
            ownerID: UUID(),
            haves: [ListingItemQuantity(itemID: have.id, quantity: 2)],
            haveLogic: .all,
            status: .paused,
            note: "旧メモ",
            options: [
                IndividualListingWishOption(
                    id: optionID,
                    listingID: listingID,
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: wish.id, quantity: 1)],
                    logic: .one,
                    exchangeType: .crossKind
                )
            ]
        )

        var draft = IndividualListingDraft(mode: .edit(original))
        XCTAssertEqual(draft.haveQuantity(for: have.id), 2)
        XCTAssertEqual(draft.status, .paused)

        draft.setHaveQuantity(have.id, quantity: 1, maxQuantity: have.quantity)
        draft.setWishQuantity(wish.id, quantity: 3)
        draft.status = .active
        draft.exchangeType = .sameKind
        draft.note = "   "

        let updated = try XCTUnwrap(draft.updatedListing(from: original, inventory: [have], wishes: [wish]))

        XCTAssertEqual(updated.id, listingID)
        XCTAssertEqual(updated.haves, [ListingItemQuantity(itemID: have.id, quantity: 1)])
        XCTAssertEqual(updated.status, .active)
        XCTAssertEqual(
            updated.note,
            "交換手段: どちらもOK / 都道府県: 東京都 / 場所メモ: 相談 / 日程: 相談して決める / 送料: 要相談 / 発送目安: 2〜4日以内 / 条件外打診: 可"
        )
        XCTAssertEqual(updated.options.first?.id, optionID)
        XCTAssertEqual(updated.options.first?.wishes, [ListingItemQuantity(itemID: wish.id, quantity: 3)])
        XCTAssertEqual(updated.options.first?.exchangeType, .sameKind)
    }
}
