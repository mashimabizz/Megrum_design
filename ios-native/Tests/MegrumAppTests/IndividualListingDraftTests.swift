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
            交換手段: 現地交換・郵送OK / 都道府県: 東京都 / 場所メモ: 相談 / 日程: 相談して決める / 送料: 要相談 / 発送目安: 2〜4日以内 / 条件外打診: 可
            """
        )
    }

    func testCreateDraftUsesConfiguredDefaultExchangeSummary() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let have = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "譲るアクスタ",
            quantity: 1
        )
        let wish = WishItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "ほしいアクスタ"
        )
        let defaultSummary = IndividualListingExchangeSummary(
            handoffMethod: .local,
            localPrefecture: "大阪府",
            localPlaceMemo: "京セラ周辺",
            localSchedule: "7/1",
            shippingFee: .owner,
            shippingDays: .oneDay
        )

        var draft = IndividualListingDraft(
            mode: .create(preselectedWishID: wish.id),
            defaultExchangeSummary: defaultSummary
        )
        draft.toggleHave(have.id, maxQuantity: have.quantity)

        let input = try XCTUnwrap(draft.createInput(inventory: [have], wishes: [wish]))

        XCTAssertEqual(draft.localPrefecture, "大阪府")
        XCTAssertEqual(
            input.note,
            "交換手段: 現地交換 / 都道府県: 大阪府 / 場所メモ: 京セラ周辺 / 日程: 7/1 / 条件外打診: 可"
        )
    }

    func testCreateDraftAllowsMixedGroupsAndGoodsTypes() throws {
        let firstGroupID = UUID()
        let secondGroupID = UUID()
        let firstGoodsTypeID = UUID()
        let secondGoodsTypeID = UUID()
        let inventory = [
            GoodsItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: firstGroupID,
                goodsTypeID: firstGoodsTypeID,
                title: "譲るトレカ",
                quantity: 2,
                marketAvailableQuantity: 2
            ),
            GoodsItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: secondGroupID,
                goodsTypeID: secondGoodsTypeID,
                title: "譲るアクスタ",
                quantity: 1,
                marketAvailableQuantity: 1
            )
        ]
        let wishes = [
            WishItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: secondGroupID,
                goodsTypeID: firstGoodsTypeID,
                title: "求める缶バッジ"
            ),
            WishItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: firstGroupID,
                goodsTypeID: secondGoodsTypeID,
                title: "求めるフォトカード"
            )
        ]

        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
        inventory.forEach { draft.toggleHave($0.id, maxQuantity: $0.quantity) }
        wishes.forEach { draft.toggleWish($0.id) }

        let input = try XCTUnwrap(draft.createInput(inventory: inventory, wishes: wishes))

        XCTAssertEqual(input.haveItems.map(\.itemID), inventory.map(\.id))
        XCTAssertEqual(input.wishItems.map(\.itemID), wishes.map(\.id))
        XCTAssertNil(draft.validationMessage(inventory: inventory, wishes: wishes))
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

    func testListingNotePresentationReturnsOnlyUserMemo() {
        let note = """
        異種は写真を見て相談したいです
        譲る金額: ¥2,000
        交換手段: 現地交換 / 都道府県: 大阪府 / 場所メモ: 京セラ周辺 / 日程: 6/28 / 条件外打診: 可
        """

        XCTAssertEqual(
            IndividualListingNotePresentation.userMemo(from: note),
            "異種は写真を見て相談したいです"
        )
    }

    func testDraftStoresMultipleLocalScheduleCandidates() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let have = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "譲るトレカ",
            quantity: 2
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
        draft.localSchedule = "6/28 18:00、6/29 13:00"

        let input = try XCTUnwrap(draft.createInput(inventory: [have], wishes: [wish]))

        XCTAssertTrue(input.note?.contains("日程: 6/28 18:00、6/29 13:00") == true)
    }

    func testShippingFeeSelectableCasesKeepOnlyOwnerAndNegotiation() {
        XCTAssertEqual(
            IndividualListingShippingFeeDraft.selectableCases.map(\.title),
            ["自己負担", "要相談"]
        )
        XCTAssertEqual(IndividualListingShippingFeeDraft.partner.title, "相手負担")
    }

    func testIndividualListingListPresentationUsesListSpecificLabels() {
        XCTAssertEqual(IndividualListingListPresentation.optionTitle(index: 1), "選択肢1")
        XCTAssertEqual(IndividualListingListPresentation.handoffMethodTitle(for: .local), "現地交換")
        XCTAssertEqual(IndividualListingListPresentation.handoffMethodTitle(for: .mail), "郵送交換")
        XCTAssertEqual(IndividualListingListPresentation.handoffMethodTitle(for: .both), "現地交換・郵送OK")
        XCTAssertFalse(IndividualListingListPresentation.usesCollapsedOptionSummary(optionCount: 2))
        XCTAssertTrue(IndividualListingListPresentation.usesCollapsedOptionSummary(optionCount: 3))

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
        let atLeastGoodsOption = IndividualListingWishOption(
            id: UUID(),
            listingID: listingID,
            position: 4,
            wishes: [
                ListingItemQuantity(itemID: UUID(), quantity: 1),
                ListingItemQuantity(itemID: UUID(), quantity: 1),
                ListingItemQuantity(itemID: UUID(), quantity: 1)
            ],
            logic: .atLeast,
            minimumCount: 3
        )
        let cashOption = IndividualListingWishOption(
            id: UUID(),
            listingID: listingID,
            position: 5,
            wishes: [],
            logic: .one,
            isCashOffer: true,
            cashAmount: 1_500
        )

        XCTAssertNil(IndividualListingListPresentation.optionLogicTitle(for: singleGoodsOption))
        XCTAssertEqual(IndividualListingListPresentation.optionLogicTitle(for: multipleGoodsOption), "どれか1つだけ")
        XCTAssertEqual(IndividualListingListPresentation.optionLogicTitle(for: allGoodsOption), "全部ほしい")
        XCTAssertEqual(IndividualListingListPresentation.optionLogicTitle(for: atLeastGoodsOption), "3個以上")
        XCTAssertNil(IndividualListingListPresentation.optionLogicTitle(for: cashOption))
    }

    func testIndividualListingsPresentationStateDisplaysLocalEditsAndDeleteTarget() {
        let originalID = UUID()
        let ownerID = UUID()
        let original = IndividualListing(
            id: originalID,
            ownerID: ownerID,
            haves: [],
            note: "変更前",
            options: []
        )
        let updated = IndividualListing(
            id: originalID,
            ownerID: ownerID,
            haves: [],
            note: "変更後",
            options: []
        )
        var state = IndividualListingsPresentationState()

        state.recordEdited(updated)
        state.requestDelete(original)

        XCTAssertEqual(state.displayedListings([original]).first?.note, "変更後")
        XCTAssertEqual(state.pendingDeleteListing?.id, originalID)

        state.clearPendingDelete()
        state.removeLocalEdit(for: originalID)

        XCTAssertNil(state.pendingDeleteListing)
        XCTAssertEqual(state.displayedListings([original]).first?.note, "変更前")
    }

    func testIndividualListingsPresentationStateConsumesInitialEditorAndGatesFreeLimit() {
        var state = IndividualListingsPresentationState()

        XCTAssertFalse(
            state.shouldPresentInitialEditor(
                initiallyPresentsEditor: false,
                initialEditorOptionKind: nil,
                initialEditorStep: .haves
            )
        )

        XCTAssertTrue(
            state.shouldPresentInitialEditor(
                initiallyPresentsEditor: true,
                initialEditorOptionKind: nil,
                initialEditorStep: .haves
            )
        )
        XCTAssertFalse(
            state.shouldPresentInitialEditor(
                initiallyPresentsEditor: true,
                initialEditorOptionKind: nil,
                initialEditorStep: .haves
            )
        )

        state.openCreateEditor(optionKind: nil, listings: [], subscriptionState: .free)
        XCTAssertEqual(state.editorRoute?.id, "create-default")

        state.closeEditor()
        state.openCreateEditor(
            optionKind: nil,
            listings: [
                IndividualListing(id: UUID(), ownerID: UUID(), haves: [], status: .active),
                IndividualListing(id: UUID(), ownerID: UUID(), haves: [], status: .paused),
                IndividualListing(id: UUID(), ownerID: UUID(), haves: [], status: .matched)
            ],
            subscriptionState: .free
        )

        XCTAssertNil(state.editorRoute)
        XCTAssertTrue(state.showsMegrumPlusUpsell)
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

        XCTAssertTrue(normalized.hasOfferCondition)
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

    func testDraftBuildsAtLeastLogicWithSeparateMinimumCount() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let inventory = (1...3).map { index in
            GoodsItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: groupID,
                goodsTypeID: goodsTypeID,
                title: "譲る\(index)",
                quantity: 1,
                marketAvailableQuantity: 1
            )
        }
        let wishes = (1...4).map { index in
            WishItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: groupID,
                goodsTypeID: goodsTypeID,
                title: "求める\(index)"
            )
        }

        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
        inventory.forEach { draft.toggleHave($0.id, maxQuantity: 1) }
        wishes.forEach { draft.toggleWish($0.id) }
        draft.setHaveLogic(.atLeast)
        draft.setHaveMinimumCount(2)
        draft.setWishLogic(.atLeast)
        draft.setWishMinimumCount(3)

        let input = try XCTUnwrap(draft.createInput(inventory: inventory, wishes: wishes))

        XCTAssertEqual(input.haveLogic, .atLeast)
        XCTAssertEqual(input.haveMinimumCount, 2)
        XCTAssertEqual(input.haveItems.map(\.quantity), [1, 1, 1])
        XCTAssertEqual(input.wishLogic, .atLeast)
        XCTAssertEqual(input.wishMinimumCount, 3)
        XCTAssertEqual(input.wishItems.map(\.quantity), [1, 1, 1, 1])
    }

    func testAtLeastLogicAllowsTwoItemsAndResetsWhenSelectionDropsBelowTwo() {
        let first = UUID()
        let second = UUID()
        let third = UUID()
        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
        [first, second, third].forEach { draft.toggleWish($0) }
        draft.setWishLogic(.atLeast)
        draft.setWishMinimumCount(3)

        draft.toggleWish(third)

        XCTAssertEqual(draft.wishLogic, .atLeast)
        XCTAssertEqual(draft.resolvedWishMinimumCount, 2)

        draft.setWishMinimumCount(1)

        XCTAssertEqual(draft.resolvedWishMinimumCount, 1)

        draft.toggleWish(second)

        XCTAssertEqual(draft.wishLogic, .one)
        XCTAssertEqual(draft.resolvedWishMinimumCount, 1)
    }

    func testDraftSelectsAllVisibleHavesAndWishes() {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let visibleHaves = (1...2).map { index in
            GoodsItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: groupID,
                goodsTypeID: goodsTypeID,
                title: "譲る\(index)",
                quantity: index + 1
            )
        }
        let hiddenHave = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "非表示の譲る",
            quantity: 1
        )
        let visibleWishes = (1...2).map { index in
            WishItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: groupID,
                goodsTypeID: goodsTypeID,
                title: "求める\(index)"
            )
        }
        let hiddenWish = WishItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "非表示のWish"
        )
        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))

        draft.selectAllHaves(visibleHaves)
        draft.selectAllWishes(visibleWishes)

        XCTAssertEqual(draft.selectedHaveIDs, Set(visibleHaves.map(\.id)))
        XCTAssertFalse(draft.selectedHaveIDs.contains(hiddenHave.id))
        XCTAssertEqual(draft.selectedWishIDs, Set(visibleWishes.map(\.id)))
        XCTAssertFalse(draft.selectedWishIDs.contains(hiddenWish.id))
        XCTAssertEqual(draft.haveQuantity(for: visibleHaves[1].id), 1)
        XCTAssertEqual(draft.wishQuantity(for: visibleWishes[0].id), 1)
        XCTAssertEqual(draft.haveLogic, .atLeast)
        XCTAssertEqual(draft.resolvedHaveMinimumCount, 1)
        XCTAssertEqual(draft.wishLogic, .atLeast)
        XCTAssertEqual(draft.resolvedWishMinimumCount, 1)
    }

    func testDraftDeselectsOnlyVisibleHavesAndWishes() {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let visibleHave = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "表示中の譲る",
            quantity: 1
        )
        let hiddenHave = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "非表示の譲る",
            quantity: 1
        )
        let visibleWish = WishItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "表示中のWish"
        )
        let hiddenWish = WishItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "非表示のWish"
        )
        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
        draft.selectAllHaves([visibleHave, hiddenHave])
        draft.selectAllWishes([visibleWish, hiddenWish])

        draft.deselectHaves([visibleHave])
        draft.deselectWishes([visibleWish])

        XCTAssertEqual(draft.selectedHaveIDs, Set([hiddenHave.id]))
        XCTAssertEqual(draft.selectedWishIDs, Set([hiddenWish.id]))
        XCTAssertEqual(draft.haveLogic, .all)
        XCTAssertEqual(draft.wishLogic, .one)
    }

    func testAtLeastLogicCanUseOneMinimumWithTwoItems() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let inventory = (1...2).map { index in
            GoodsItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: groupID,
                goodsTypeID: goodsTypeID,
                title: "譲る\(index)",
                quantity: 1
            )
        }
        let wishes = (1...2).map { index in
            WishItem(
                id: UUID(),
                ownerID: UUID(),
                groupID: groupID,
                goodsTypeID: goodsTypeID,
                title: "求める\(index)"
            )
        }

        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
        draft.selectAllHaves(inventory)
        draft.selectAllWishes(wishes)
        draft.setHaveMinimumCount(1)
        draft.setWishMinimumCount(1)

        let input = try XCTUnwrap(draft.createInput(inventory: inventory, wishes: wishes))

        XCTAssertEqual(input.haveLogic, .atLeast)
        XCTAssertEqual(input.haveMinimumCount, 1)
        XCTAssertEqual(input.wishLogic, .atLeast)
        XCTAssertEqual(input.wishMinimumCount, 1)
    }

    func testSecondSelectionDefaultsToOneOrMoreLogic() {
        let firstHave = UUID()
        let secondHave = UUID()
        let firstWish = UUID()
        let secondWish = UUID()
        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))

        draft.toggleHave(firstHave)
        XCTAssertEqual(draft.haveLogic, .all)

        draft.toggleHave(secondHave)
        XCTAssertEqual(draft.haveLogic, .atLeast)
        XCTAssertEqual(draft.resolvedHaveMinimumCount, 1)

        draft.toggleWish(firstWish)
        XCTAssertEqual(draft.wishLogic, .one)

        draft.toggleWish(secondWish)
        XCTAssertEqual(draft.wishLogic, .atLeast)
        XCTAssertEqual(draft.resolvedWishMinimumCount, 1)
    }

    func testHavesStepValidationClearsAfterSelectingHave() {
        let have = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: UUID(),
            goodsTypeID: UUID(),
            title: "譲るトレカ",
            quantity: 2
        )

        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))

        XCTAssertEqual(
            IndividualListingEditorStepValidationPolicy.message(
                for: .haves,
                draft: draft,
                inventory: [have],
                wishes: []
            ),
            "譲るものを選択してください"
        )

        draft.toggleHave(have.id, maxQuantity: have.quantity)

        XCTAssertNil(
            IndividualListingEditorStepValidationPolicy.message(
                for: .haves,
                draft: draft,
                inventory: [have],
                wishes: []
            )
        )
    }

    func testCashOptionDoesNotBypassHaveStepValidation() {
        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
        draft.setOptionKind(.cash)
        draft.cashAmount = 1_500

        XCTAssertEqual(
            IndividualListingEditorStepValidationPolicy.message(
                for: .haves,
                draft: draft,
                inventory: [],
                wishes: []
            ),
            "譲るものを選択してください"
        )
    }

    func testCashOptionBuildsInputAfterSelectingHave() throws {
        let have = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: UUID(),
            goodsTypeID: UUID(),
            title: "譲るトレカ",
            quantity: 2
        )

        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
        draft.toggleHave(have.id, maxQuantity: have.quantity)
        draft.setOptionKind(.cash)
        draft.cashPricingMode = .specifiedAmount
        draft.cashAmount = 1_500

        let input = try XCTUnwrap(draft.createInput(inventory: [have], wishes: []))

        XCTAssertEqual(input.haveItems, [ListingItemQuantity(itemID: have.id, quantity: 1)])
        XCTAssertTrue(input.isCashOffer)
        XCTAssertEqual(input.cashAmount, 1_500)
        XCTAssertTrue(input.wishItems.isEmpty)
    }

    func testCashOptionCanUseListPriceWithoutAmount() throws {
        let have = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: UUID(),
            goodsTypeID: UUID(),
            title: "譲るトレカ",
            quantity: 2
        )

        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
        draft.toggleHave(have.id, maxQuantity: have.quantity)
        draft.setOptionKind(.cash)
        draft.cashPricingMode = .listPrice
        draft.cashAmount = 0

        let input = try XCTUnwrap(draft.createInput(inventory: [have], wishes: []))

        XCTAssertTrue(input.isCashOffer)
        XCTAssertNil(input.cashAmount)
        XCTAssertNil(
            IndividualListingEditorStepValidationPolicy.message(
                for: .options,
                draft: draft,
                inventory: [have],
                wishes: []
            )
        )
    }

    func testHaveCashOfferCanProceedWithoutGoodsAndStoresSummary() throws {
        let wish = WishItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: UUID(),
            goodsTypeID: UUID(),
            title: "ほしいトレカ"
        )

        var draft = IndividualListingDraft(mode: .create(preselectedWishID: wish.id))
        draft.setHaveOfferKind(.cash)
        draft.haveCashPricingMode = .specifiedAmount
        draft.haveCashAmount = 1_500

        XCTAssertNil(
            IndividualListingEditorStepValidationPolicy.message(
                for: .haves,
                draft: draft,
                inventory: [],
                wishes: [wish]
            )
        )

        let input = try XCTUnwrap(draft.createInput(inventory: [], wishes: [wish]))
        XCTAssertTrue(input.hasOfferCondition)
        XCTAssertTrue(input.haveIsCashOffer)
        XCTAssertEqual(input.haveCashAmount, 1_500)
        XCTAssertTrue(input.haveItems.isEmpty)
        XCTAssertEqual(input.wishItems, [ListingItemQuantity(itemID: wish.id, quantity: 1)])
        XCTAssertTrue(input.note?.contains("譲る金額: ¥1500") == true)
    }

    func testHaveCashOfferRestoresFromNoteWhenEditing() throws {
        let listing = IndividualListing(
            id: UUID(),
            ownerID: UUID(),
            haves: [],
            note: """
            メモ本文
            譲る金額: ¥2,000
            交換手段: 現地交換 / 都道府県: 大阪府 / 場所メモ: 京セラ周辺 / 日程: 6/28 / 条件外打診: 可
            """,
            options: []
        )

        let draft = IndividualListingDraft(mode: .edit(listing))

        XCTAssertEqual(draft.note, "メモ本文")
        XCTAssertEqual(draft.haveOfferKind, .cash)
        XCTAssertEqual(draft.haveCashPricingMode, .specifiedAmount)
        XCTAssertEqual(draft.haveCashAmount, 2_000)
        XCTAssertEqual(draft.handoffMethod, .local)
        XCTAssertEqual(draft.localPrefecture, "大阪府")
    }

    func testCashOptionRequiresAmountOnlyWhenSpecifiedAmount() {
        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
        draft.setOptionKind(.cash)
        draft.cashPricingMode = .specifiedAmount
        draft.cashAmount = 0

        XCTAssertEqual(
            IndividualListingEditorStepValidationPolicy.message(
                for: .options,
                draft: draft,
                inventory: [],
                wishes: []
            ),
            "金額を入力してください"
        )

        draft.cashPricingMode = .listPrice

        XCTAssertNil(
            IndividualListingEditorStepValidationPolicy.message(
                for: .options,
                draft: draft,
                inventory: [],
                wishes: []
            )
        )
    }

    func testPreviewListingEditKeepsSelectedHaveStepValid() throws {
        let listing = try XCTUnwrap(NativePreviewData.listings.first)

        let draft = IndividualListingDraft(mode: .edit(listing))

        XCTAssertNil(
            IndividualListingEditorStepValidationPolicy.message(
                for: .haves,
                draft: draft,
                inventory: NativePreviewData.inventory,
                wishes: NativePreviewData.wishes
            )
        )
        XCTAssertEqual(draft.selectedHaveIDs, Set(listing.haves.map(\.itemID)))
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

    func testResetCurrentOptionSelectionClearsOnlyCurrentOptionFields() {
        let wishID = UUID()
        let groupID = UUID()
        let goodsTypeID = UUID()
        let memberID = UUID()
        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))

        draft.setOptionKind(.wish)
        draft.toggleWish(wishID)
        draft.setWishQuantity(wishID, quantity: 3)
        draft.resetCurrentOptionSelection()

        XCTAssertTrue(draft.selectedWishIDs.isEmpty)
        XCTAssertTrue(draft.wishQuantities.isEmpty)

        draft.setOptionKind(.condition)
        draft.setConditionGroupID(groupID)
        draft.conditionGoodsTypeID = goodsTypeID
        draft.toggleConditionMember(memberID)
        draft.setExcludesSelectedConditionMembers(true)
        draft.toggleConditionTag("会場限定")
        draft.setConditionQuantity(4)
        draft.resetCurrentOptionSelection()

        XCTAssertNil(draft.conditionGroupID)
        XCTAssertNil(draft.conditionGoodsTypeID)
        XCTAssertTrue(draft.conditionMemberIDs.isEmpty)
        XCTAssertFalse(draft.excludesSelectedConditionMembers)
        XCTAssertTrue(draft.conditionTagNames.isEmpty)
        XCTAssertEqual(draft.conditionQuantity, 1)

        draft.setOptionKind(.cash)
        draft.cashPricingMode = .specifiedAmount
        draft.cashAmount = 1_800
        draft.resetCurrentOptionSelection()

        XCTAssertEqual(draft.cashPricingMode, .listPrice)
        XCTAssertEqual(draft.cashAmount, 1_100)
    }

    func testEditorStepOrderMatchesTappableProgressDots() {
        XCTAssertEqual(
            IndividualListingEditorStep.allCases.map(\.title),
            ["譲るものを選ぶ", "欲しいものを登録", "交換条件を設定する"]
        )
        XCTAssertEqual(IndividualListingEditorStep.allCases.map(\.rawValue), [1, 2, 3])
    }

    func testOptionReviewReducerDeletesAndRetitlesStagedOptions() {
        let first = IndividualListingOptionReviewItem(title: "選択肢1", kind: "Wish", detail: "サナ")
        let secondID = UUID()
        let second = IndividualListingOptionReviewItem(id: secondID, title: "選択肢2", kind: "定価", detail: "¥1,500")
        let third = IndividualListingOptionReviewItem(title: "選択肢3", kind: "条件", detail: "TWICE")

        let reduced = IndividualListingOptionReviewReducer.deleting(
            itemID: secondID,
            from: [first, second, third]
        )

        XCTAssertEqual(reduced.map(\.title), ["選択肢1", "選択肢2"])
        XCTAssertEqual(reduced.map(\.kind), ["Wish", "条件"])
        XCTAssertEqual(reduced.map(\.source), [.staged, .staged])
    }

    func testOptionReviewToastMessageIncludesAddedOptionDetail() {
        let item = IndividualListingOptionReviewItem(
            title: "選択肢1",
            kind: "定価",
            detail: "¥1,500"
        )

        XCTAssertEqual(item.addedToastMessage, "選択肢1（定価：¥1,500）を追加しました")
    }

    func testIndividualListingEditorPresentationStateSeedsStepAndHavesTab() {
        var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
        draft.setHaveOfferKind(.cash)

        let state = IndividualListingEditorPresentationState(initialStep: .options, draft: draft)

        XCTAssertEqual(state.step, .options)
        XCTAssertEqual(state.havesTab, .cash)
    }

    func testIndividualListingEditorPresentationStateStagesAndDeletesOptions() {
        var state = IndividualListingEditorPresentationState(step: .options)
        let first = IndividualListingOptionReviewItem(title: "選択肢1", kind: "Wish", detail: "サナ")
        let secondID = UUID()
        let second = IndividualListingOptionReviewItem(id: secondID, title: "選択肢2", kind: "条件", detail: "TWICE")
        let third = IndividualListingOptionReviewItem(title: "選択肢3", kind: "定価", detail: "¥1,500")

        state.appendStagedOption(first)
        state.appendStagedOption(second)
        state.appendStagedOption(third)
        XCTAssertEqual(state.nextOptionTitle, "選択肢4")

        state.deleteStagedOption(id: secondID)

        XCTAssertEqual(state.stagedOptionSummaries.map(\.title), ["選択肢1", "選択肢2"])
        XCTAssertEqual(state.stagedOptionSummaries.map(\.kind), ["Wish", "定価"])
    }

    func testIndividualListingEditorPresentationStateTracksSaveErrorAndToast() {
        var state = IndividualListingEditorPresentationState(step: .haves)
        let staleToastID = UUID()
        let currentToastID = UUID()
        let item = IndividualListingOptionReviewItem(title: "選択肢1", kind: "定価", detail: "¥1,500")

        state.setSaveError("保存できませんでした")
        XCTAssertEqual(state.saveErrorMessage, "保存できませんでした")
        state.clearSaveError()
        XCTAssertNil(state.saveErrorMessage)

        state.showOptionReview()
        XCTAssertTrue(state.showsOptionReview)
        state.showOptionAddedToast(for: item, toastID: currentToastID)
        XCTAssertEqual(state.optionToastMessage, item.addedToastMessage)
        state.clearOptionToast(ifMatching: staleToastID)
        XCTAssertEqual(state.optionToastMessage, item.addedToastMessage)
        state.clearOptionToast(ifMatching: currentToastID)
        XCTAssertNil(state.optionToastMessage)
    }

    func testBottomBarPresentationKeepsAddOptionTitleStable() {
        XCTAssertEqual(IndividualListingEditorBottomBarPresentation.addOptionTitle, "選択肢に追加")
        XCTAssertEqual(IndividualListingEditorBottomBarPresentation.selectAllVisibleTitle, "すべて登録")
        XCTAssertEqual(IndividualListingEditorBottomBarPresentation.deselectAllVisibleTitle, "すべて解除")
        XCTAssertEqual(IndividualListingEditorBottomBarPresentation.selectedCountTitle(12), "選択中12件")
        XCTAssertEqual(ListingLogic.minimumCountTitle(1), "1個以上")
    }

    func testFooterLogicPresentationStateShowsMinimumPickerOnlyForAtLeastLogic() {
        var state = IndividualListingFooterLogicPresentationState()

        XCTAssertEqual(state.minimumChoices(selectedCount: 1), [])
        XCTAssertEqual(state.minimumChoices(selectedCount: 3), [1, 2, 3])

        XCTAssertEqual(state.selectLogic(.all), .all)
        XCTAssertFalse(state.isShowingMinimumPicker)

        XCTAssertEqual(state.selectLogic(.atLeast), .atLeast)
        XCTAssertTrue(state.isShowingMinimumPicker)

        state.dismissMinimumPicker()
        XCTAssertFalse(state.isShowingMinimumPicker)
    }

    func testConditionPresentationStateTracksPickerAndTagSheetVisibility() {
        var state = IndividualListingConditionPresentationState()

        XCTAssertFalse(state.isShowingMemberPicker)
        XCTAssertFalse(state.isShowingTagSheet)

        state.showMemberPicker()
        XCTAssertTrue(state.isShowingMemberPicker)

        state.dismissMemberPicker()
        XCTAssertFalse(state.isShowingMemberPicker)

        state.showTagSheet()
        XCTAssertTrue(state.isShowingTagSheet)
    }

    func testReceivePanelPresentationStateTracksOptionBreakdownSheet() {
        var state = IndividualListingReceivePanelPresentationState()

        XCTAssertFalse(state.isShowingOptionBreakdown)

        state.showOptionBreakdown()
        XCTAssertTrue(state.isShowingOptionBreakdown)

        state.dismissOptionBreakdown()
        XCTAssertFalse(state.isShowingOptionBreakdown)
    }

    func testIndividualListingEditorSaveFailureCopyIsVisible() {
        XCTAssertEqual(
            IndividualListingEditorSaveFailurePresentation.title,
            "個別募集を保存できませんでした"
        )
        XCTAssertEqual(
            IndividualListingEditorSaveFailurePresentation.fallbackMessage,
            "通信状況を確認してからもう一度お試しください。"
        )
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
            tags: [GoodsTag(id: UUID(), name: "別シリーズ")]
        )

        let builder = IndividualListingConditionTagBuilder(
            inventory: [targetGoods, otherGoods],
            wishes: [targetWish],
            selectedGroupID: targetGroupID
        )

        XCTAssertEqual(builder.candidateNames(), ["会場限定", "終演後OK", "ファンミ"])
        XCTAssertEqual(builder.previewItemsByTag()["会場限定"]?.count, 2)
        XCTAssertNil(builder.previewItemsByTag()["別シリーズ"])
    }

    func testIndividualListingSelectionFilterMatchesGoodsAndWishes() {
        let groupID = UUID()
        let otherGroupID = UUID()
        let goodsTypeID = UUID()
        let otherGoodsTypeID = UUID()
        let filter = IndividualListingSelectionFilter(
            searchText: "会場",
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            tagNames: ["ファンミ"]
        )
        let matchingGoods = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "トレカ",
            tags: [
                GoodsTag(id: UUID(), name: "会場限定"),
                GoodsTag(id: UUID(), name: "ファンミ")
            ]
        )
        let mismatchedGoods = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: otherGroupID,
            goodsTypeID: goodsTypeID,
            title: "会場 トレカ",
            tags: [GoodsTag(id: UUID(), name: "ファンミ")]
        )
        let matchingWish = WishItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "会場 トレカ",
            tags: [GoodsTag(id: UUID(), name: "ファンミ")]
        )
        let mismatchedWish = WishItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            goodsTypeID: otherGoodsTypeID,
            title: "会場 トレカ",
            tags: [GoodsTag(id: UUID(), name: "ファンミ")]
        )

        XCTAssertTrue(filter.matches(matchingGoods))
        XCTAssertFalse(filter.matches(mismatchedGoods))
        XCTAssertTrue(filter.matches(matchingWish))
        XCTAssertFalse(filter.matches(mismatchedWish))
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
            "交換手段: 現地交換・郵送OK / 都道府県: 東京都 / 場所メモ: 相談 / 日程: 相談して決める / 送料: 要相談 / 発送目安: 2〜4日以内 / 条件外打診: 可"
        )
        XCTAssertEqual(updated.options.first?.id, optionID)
        XCTAssertEqual(updated.options.first?.wishes, [ListingItemQuantity(itemID: wish.id, quantity: 3)])
        XCTAssertEqual(updated.options.first?.exchangeType, .sameKind)
    }
}
