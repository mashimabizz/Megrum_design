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
        XCTAssertEqual(input.note, "会場で相談")
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
        XCTAssertNil(updated.note)
        XCTAssertEqual(updated.options.first?.id, optionID)
        XCTAssertEqual(updated.options.first?.wishes, [ListingItemQuantity(itemID: wish.id, quantity: 3)])
        XCTAssertEqual(updated.options.first?.exchangeType, .sameKind)
    }
}
