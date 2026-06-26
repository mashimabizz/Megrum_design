import MegrumApp
import MegrumCore
import XCTest

final class GoodsLocalStateReducerTests: XCTestCase {
    func testUpsertingInventoryItemMovesItToInventoryAndRefreshesDependentItems() {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000001101")!
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000001102")!
        let goodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000001103")!
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000001104")!
        let oldItem = makeGoodsItem(
            id: targetID,
            ownerID: ownerID,
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "古いグッズ"
        )
        let updatedItem = makeGoodsItem(
            id: targetID,
            ownerID: ownerID,
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "新しいグッズ"
        )
        let otherItem = makeGoodsItem(idSuffix: "105", ownerID: ownerID, title: "そのまま")
        let matchingWish = WishItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001106")!,
            ownerID: ownerID,
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "条件"
        )
        let state = makeState(
            inventory: [otherItem],
            wishes: [matchingWish],
            homeMatchedItems: [oldItem],
            homePossibleItems: [oldItem],
            searchResults: [
                SearchResultItem(item: oldItem, ownerUserID: ownerID, bucket: .none)
            ]
        )

        let updated = GoodsLocalStateReducer.upserting(
            updatedItem,
            kind: .inventory,
            in: state
        )

        XCTAssertEqual(updated.inventory, [updatedItem, otherItem])
        XCTAssertEqual(updated.wishes, [matchingWish])
        XCTAssertEqual(updated.homeMatchedItems, [updatedItem])
        XCTAssertEqual(updated.homePossibleItems, [updatedItem])
        XCTAssertEqual(updated.searchResults.first?.item, updatedItem)
        XCTAssertEqual(updated.searchResults.first?.bucket, .possible)
    }

    func testUpsertingWishItemRemovesMatchingInventoryAndInsertsWishAtFront() {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000001107")!
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000001108")!
        let item = makeGoodsItem(id: targetID, ownerID: ownerID, title: "Wish化")
        let existingWish = WishItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001109")!,
            ownerID: ownerID,
            title: "既存Wish"
        )
        let state = makeState(
            inventory: [item],
            wishes: [existingWish]
        )

        let updated = GoodsLocalStateReducer.upserting(
            item,
            kind: .wish,
            in: state
        )

        XCTAssertTrue(updated.inventory.isEmpty)
        XCTAssertEqual(updated.wishes.map(\.id), [targetID, existingWish.id])
        XCTAssertEqual(updated.wishes.first?.title, "Wish化")
    }

    func testRemovingGoodsItemDropsDependentReferences() {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000001110")!
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000001111")!
        let keptID = UUID(uuidString: "00000000-0000-0000-0000-000000001112")!
        let targetItem = makeGoodsItem(id: targetID, ownerID: ownerID, title: "消す")
        let keptItem = makeGoodsItem(id: keptID, ownerID: ownerID, title: "残す")
        let targetWish = WishItem(id: targetID, ownerID: ownerID, title: "消すWish")
        let listing = IndividualListing(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001113")!,
            ownerID: ownerID,
            haves: [
                ListingItemQuantity(itemID: targetID, quantity: 1),
                ListingItemQuantity(itemID: keptID, quantity: 1),
            ],
            options: [
                IndividualListingWishOption(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000001114")!,
                    listingID: UUID(uuidString: "00000000-0000-0000-0000-000000001113")!,
                    position: 1,
                    wishes: [
                        ListingItemQuantity(itemID: targetID, quantity: 1),
                        ListingItemQuantity(itemID: keptID, quantity: 1),
                    ]
                ),
                IndividualListingWishOption(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000001115")!,
                    listingID: UUID(uuidString: "00000000-0000-0000-0000-000000001113")!,
                    position: 2,
                    wishes: [
                        ListingItemQuantity(itemID: targetID, quantity: 1)
                    ],
                    isCashOffer: true
                ),
            ]
        )
        let removedListing = IndividualListing(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001116")!,
            ownerID: ownerID,
            haves: [
                ListingItemQuantity(itemID: targetID, quantity: 1)
            ],
            options: [
                IndividualListingWishOption(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000001117")!,
                    listingID: UUID(uuidString: "00000000-0000-0000-0000-000000001116")!,
                    position: 1,
                    wishes: [
                        ListingItemQuantity(itemID: keptID, quantity: 1)
                    ]
                )
            ]
        )
        let state = makeState(
            inventory: [targetItem, keptItem],
            wishes: [targetWish],
            homeMatchedItems: [targetItem],
            homePossibleItems: [targetItem],
            homeCandidateConditionSignals: [
                targetID: makeSignals()
            ],
            searchResults: [
                SearchResultItem(item: targetItem, ownerUserID: ownerID, bucket: .possible),
                SearchResultItem(item: keptItem, ownerUserID: ownerID, bucket: .none),
            ],
            listings: [listing, removedListing]
        )

        let updated = GoodsLocalStateReducer.removing(
            itemID: targetID,
            from: state
        )

        XCTAssertEqual(updated.inventory, [keptItem])
        XCTAssertTrue(updated.wishes.isEmpty)
        XCTAssertTrue(updated.homeMatchedItems.isEmpty)
        XCTAssertTrue(updated.homePossibleItems.isEmpty)
        XCTAssertTrue(updated.homeCandidateConditionSignals.isEmpty)
        XCTAssertEqual(updated.searchResults.map(\.item), [keptItem])
        XCTAssertEqual(updated.listings.count, 1)
        XCTAssertEqual(updated.listings.first?.haves.map(\.itemID), [keptID])
        XCTAssertEqual(updated.listings.first?.options.first?.wishes.map(\.itemID), [keptID])
        XCTAssertEqual(updated.listings.first?.options.last?.wishes, [])
        XCTAssertTrue(updated.listings.first?.options.last?.isCashOffer == true)
    }

    func testApplyingCompletedTradeMovesGivenAndReceivedGoodsForViewer() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000001118")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000001119")!
        let givenID = UUID(uuidString: "00000000-0000-0000-0000-000000001120")!
        let receivedID = UUID(uuidString: "00000000-0000-0000-0000-000000001121")!
        let given = makeGoodsItem(
            id: givenID,
            ownerID: viewerID,
            title: "譲るトレカ",
            quantity: 3,
            lockedQuantity: 1,
            marketAvailableQuantity: 2,
            status: .active
        )
        let received = makeGoodsItem(
            id: receivedID,
            ownerID: partnerID,
            title: "受け取るトレカ",
            quantity: 2,
            status: .active
        )
        let listing = IndividualListing(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001122")!,
            ownerID: viewerID,
            haves: [ListingItemQuantity(itemID: givenID, quantity: 3)],
            options: [
                IndividualListingWishOption(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000001123")!,
                    listingID: UUID(uuidString: "00000000-0000-0000-0000-000000001122")!,
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: receivedID, quantity: 1)]
                )
            ]
        )
        let state = makeState(
            inventory: [given],
            homeMatchedItems: [given],
            homePossibleItems: [given],
            searchResults: [SearchResultItem(item: given, ownerUserID: viewerID, bucket: .matched)],
            listings: [listing]
        )
        let proposal = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001124")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .completed,
            exchangeMethod: .hand,
            senderGoodsIDs: [givenID],
            receiverGoodsIDs: [receivedID]
        )
        let viewer = UserProfile(
            id: viewerID,
            handle: "viewer",
            displayName: "ビューアー",
            prefecture: "東京都"
        )

        let updated = GoodsLocalStateReducer.applyingCompletedTrade(
            proposal: proposal,
            viewerID: viewerID,
            viewerProfile: viewer,
            knownGoodsByID: [givenID: given, receivedID: received],
            to: state
        )

        let activeGiven = updated.inventory.first { $0.id == givenID }
        XCTAssertEqual(activeGiven?.quantity, 2)
        XCTAssertEqual(activeGiven?.lockedQuantity, 0)
        XCTAssertEqual(activeGiven?.marketAvailableQuantity, 2)
        XCTAssertEqual(updated.homeMatchedItems.first?.quantity, 2)
        XCTAssertEqual(updated.searchResults.first?.item.quantity, 2)
        XCTAssertEqual(updated.listings.first?.haves, [ListingItemQuantity(itemID: givenID, quantity: 2)])

        let keepItem = updated.inventory.first { $0.status == .keep }
        XCTAssertEqual(keepItem?.ownerID, viewerID)
        XCTAssertEqual(keepItem?.title, "受け取るトレカ")
        XCTAssertEqual(keepItem?.quantity, 1)

        let tradedItem = updated.inventory.first { $0.status == .traded }
        XCTAssertEqual(tradedItem?.ownerID, viewerID)
        XCTAssertEqual(tradedItem?.title, "譲るトレカ")
        XCTAssertEqual(tradedItem?.quantity, 1)
    }

    private func makeState(
        inventory: [GoodsItem] = [],
        wishes: [WishItem] = [],
        homeMatchedItems: [GoodsItem] = [],
        homePossibleItems: [GoodsItem] = [],
        homeCandidateConditionSignals: [UUID: HomeCandidateConditionSignals] = [:],
        searchResults: [SearchResultItem] = [],
        listings: [IndividualListing] = []
    ) -> GoodsLocalState {
        GoodsLocalState(
            inventory: inventory,
            wishes: wishes,
            homeMatchedItems: homeMatchedItems,
            homePossibleItems: homePossibleItems,
            homeCandidateConditionSignals: homeCandidateConditionSignals,
            searchResults: searchResults,
            listings: listings
        )
    }

    private func makeGoodsItem(
        idSuffix: String,
        ownerID: UUID,
        title: String
    ) -> GoodsItem {
        makeGoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001\(idSuffix)")!,
            ownerID: ownerID,
            title: title
        )
    }

    private func makeGoodsItem(
        id: UUID,
        ownerID: UUID,
        groupID: UUID? = nil,
        goodsTypeID: UUID? = nil,
        title: String,
        quantity: Int = 1,
        lockedQuantity: Int = 0,
        marketAvailableQuantity: Int? = nil,
        status: GoodsEntryStatus? = nil
    ) -> GoodsItem {
        GoodsItem(
            id: id,
            ownerID: ownerID,
            status: status,
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: title,
            quantity: quantity,
            lockedQuantity: lockedQuantity,
            marketAvailableQuantity: marketAvailableQuantity
        )
    }

    private func makeSignals() -> HomeCandidateConditionSignals {
        HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(
                hasIndividualListingHit: true,
                hasWishHit: false
            ),
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: false,
                dateMatches: false
            )
        )
    }
}
