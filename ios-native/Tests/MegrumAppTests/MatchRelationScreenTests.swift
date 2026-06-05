@testable import MegrumApp
import Foundation
import MegrumCore
import XCTest

final class MatchRelationScreenTests: XCTestCase {
    func testSelectableSenderGoodsKeepsOnlyTradeableInventory() {
        let viewerID = uuid(1)
        let active = goods(id: 10, ownerID: viewerID, status: .active)
        let reserved = goods(id: 11, ownerID: viewerID, status: .reserved)
        let keep = goods(id: 12, ownerID: viewerID, status: .keep)
        let traded = goods(id: 13, ownerID: viewerID, status: .traded)
        let archived = goods(id: 14, ownerID: viewerID, status: .archived)

        let result = MatchRelationComposer.selectableSenderGoods(from: [active, reserved, keep, traded, archived])

        XCTAssertEqual(result.map(\.id), [active.id, reserved.id])
    }

    func testPartnerListingRendersCandidateGoodsInsideRelationTree() {
        let viewerID = uuid(1)
        let partnerID = uuid(2)
        let groupID = uuid(20)
        let typeID = uuid(21)
        let expected = goods(id: 30, ownerID: viewerID, groupID: groupID, goodsTypeID: typeID)
        let other = goods(id: 31, ownerID: viewerID, groupID: groupID, goodsTypeID: uuid(22))
        let partnerHave = goods(id: 32, ownerID: partnerID, groupID: groupID, goodsTypeID: typeID)
        let listing = IndividualListing(
            id: uuid(40),
            ownerID: partnerID,
            haves: [ListingItemQuantity(itemID: partnerHave.id, quantity: 1)],
            options: [
                IndividualListingWishOption(
                    id: uuid(41),
                    listingID: uuid(40),
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: expected.id, quantity: 1)],
                    wishGroupID: groupID,
                    wishGoodsTypeID: typeID
                )
            ]
        )

        let details = MatchRelationComposer.buildRelationDetails(
            ownListings: [],
            partnerListings: [listing],
            senderGoods: [other, expected],
            partnerGoods: [partnerHave],
            highlightedItemID: partnerHave.id
        )

        XCTAssertEqual(details.count, 1)
        XCTAssertFalse(details[0].isMyListing)
        XCTAssertEqual(details[0].options[0].wishes[0].candidates.map(\.item.id), [expected.id])
    }

    func testRelationDetailsTolerateDuplicateGoodsIDsFromPreviewSources() {
        let viewerID = uuid(1)
        let partnerID = uuid(2)
        let groupID = uuid(20)
        let typeID = uuid(21)
        let shared = goods(id: 33, ownerID: partnerID, groupID: groupID, goodsTypeID: typeID)
        let ownHave = goods(id: 34, ownerID: viewerID, groupID: groupID, goodsTypeID: typeID)
        let listing = IndividualListing(
            id: uuid(35),
            ownerID: viewerID,
            haves: [ListingItemQuantity(itemID: ownHave.id, quantity: 1)],
            options: [
                IndividualListingWishOption(
                    id: uuid(36),
                    listingID: uuid(35),
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: shared.id, quantity: 1)],
                    wishGroupID: groupID,
                    wishGoodsTypeID: typeID
                )
            ]
        )

        let details = MatchRelationComposer.buildRelationDetails(
            ownListings: [listing],
            partnerListings: [],
            senderGoods: [ownHave, shared],
            partnerGoods: [shared],
            highlightedItemID: shared.id
        )

        XCTAssertEqual(details.count, 1)
        XCTAssertEqual(details[0].options[0].wishes[0].item.id, shared.id)
        XCTAssertEqual(details[0].options[0].wishes[0].candidates.map(\.item.id), [shared.id])
    }

    func testOwnListingInitialSelectionAggregatesPartnerCandidatesWithoutChoosingListingItself() {
        let viewerID = uuid(1)
        let partnerID = uuid(2)
        let groupID = uuid(20)
        let typeID = uuid(21)
        let ownHave = goods(id: 50, ownerID: viewerID, groupID: groupID, goodsTypeID: typeID)
        let target = goods(id: 60, ownerID: partnerID, groupID: groupID, goodsTypeID: typeID)
        let listing = IndividualListing(
            id: uuid(70),
            ownerID: viewerID,
            haves: [ListingItemQuantity(itemID: ownHave.id, quantity: 1)],
            options: [
                IndividualListingWishOption(
                    id: uuid(71),
                    listingID: uuid(70),
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: target.id, quantity: 1)],
                    logic: .all,
                    wishGroupID: groupID,
                    wishGoodsTypeID: typeID
                )
            ]
        )
        let details = MatchRelationComposer.buildRelationDetails(
            ownListings: [listing],
            partnerListings: [],
            senderGoods: [ownHave],
            partnerGoods: [target],
            highlightedItemID: target.id
        )

        let candidates = MatchRelationComposer.initialCandidateSelection(for: details, highlightedItemID: target.id)
        let haves = MatchRelationComposer.initialHaveSelection(for: details, highlightedItemID: target.id)
        let aggregate = MatchRelationComposer.aggregateSelection(
            details: details,
            selectedCandidateIDsByListingID: candidates,
            selectedHaveIDsByListingID: haves
        )

        XCTAssertEqual(aggregate.referencedListingIDs, [listing.id])
        XCTAssertEqual(aggregate.senderIDs, [ownHave.id])
        XCTAssertEqual(aggregate.receiverIDs, [target.id])
    }

    func testOwnListingKeepsMultiplePartnerCandidatesExpandableWhileSelectingHighlightedOnly() {
        let viewerID = uuid(1)
        let partnerID = uuid(2)
        let groupID = uuid(20)
        let typeID = uuid(21)
        let ownHave = goods(id: 61, ownerID: viewerID, groupID: groupID, goodsTypeID: typeID)
        let highlighted = goods(id: 62, ownerID: partnerID, groupID: groupID, goodsTypeID: typeID)
        let alternative = goods(id: 63, ownerID: partnerID, groupID: groupID, goodsTypeID: typeID)
        let listing = IndividualListing(
            id: uuid(64),
            ownerID: viewerID,
            haves: [ListingItemQuantity(itemID: ownHave.id, quantity: 1)],
            options: [
                IndividualListingWishOption(
                    id: uuid(65),
                    listingID: uuid(64),
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: highlighted.id, quantity: 1)],
                    wishGroupID: groupID,
                    wishGoodsTypeID: typeID
                )
            ]
        )

        let details = MatchRelationComposer.buildRelationDetails(
            ownListings: [listing],
            partnerListings: [],
            senderGoods: [ownHave],
            partnerGoods: [highlighted, alternative],
            highlightedItemID: highlighted.id
        )
        let selection = MatchRelationComposer.initialCandidateSelection(
            for: details,
            highlightedItemID: highlighted.id
        )

        XCTAssertEqual(details[0].options[0].wishes[0].candidates.map(\.item.id), [highlighted.id, alternative.id])
        XCTAssertEqual(selection[listing.id], Set([highlighted.id]))
    }

    func testAggregateCanIncludeOwnAndPartnerListingsAtTheSameTime() {
        let viewerID = uuid(1)
        let partnerID = uuid(2)
        let groupID = uuid(20)
        let typeID = uuid(21)
        let ownHave = goods(id: 80, ownerID: viewerID, groupID: groupID, goodsTypeID: typeID)
        let myCandidateForPartner = goods(id: 81, ownerID: viewerID, groupID: groupID, goodsTypeID: typeID)
        let partnerHave = goods(id: 82, ownerID: partnerID, groupID: groupID, goodsTypeID: typeID)
        let partnerCandidateForMe = goods(id: 83, ownerID: partnerID, groupID: groupID, goodsTypeID: typeID)

        let ownListing = IndividualListing(
            id: uuid(90),
            ownerID: viewerID,
            haves: [ListingItemQuantity(itemID: ownHave.id, quantity: 1)],
            options: [
                IndividualListingWishOption(
                    id: uuid(91),
                    listingID: uuid(90),
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: partnerCandidateForMe.id, quantity: 1)],
                    wishGroupID: groupID,
                    wishGoodsTypeID: typeID
                )
            ]
        )
        let partnerListing = IndividualListing(
            id: uuid(92),
            ownerID: partnerID,
            haves: [ListingItemQuantity(itemID: partnerHave.id, quantity: 1)],
            options: [
                IndividualListingWishOption(
                    id: uuid(93),
                    listingID: uuid(92),
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: myCandidateForPartner.id, quantity: 1)],
                    wishGroupID: groupID,
                    wishGoodsTypeID: typeID
                )
            ]
        )

        let details = MatchRelationComposer.buildRelationDetails(
            ownListings: [ownListing],
            partnerListings: [partnerListing],
            senderGoods: [ownHave, myCandidateForPartner],
            partnerGoods: [partnerHave, partnerCandidateForMe],
            highlightedItemID: partnerHave.id
        )
        let candidates: [UUID: Set<UUID>] = [
            ownListing.id: [partnerCandidateForMe.id],
            partnerListing.id: [myCandidateForPartner.id]
        ]
        let haves = MatchRelationComposer.initialHaveSelection(for: details, highlightedItemID: partnerHave.id)
        let aggregate = MatchRelationComposer.aggregateSelection(
            details: details,
            selectedCandidateIDsByListingID: candidates,
            selectedHaveIDsByListingID: haves
        )

        XCTAssertEqual(Set(aggregate.referencedListingIDs), [ownListing.id, partnerListing.id])
        XCTAssertEqual(Set(aggregate.senderIDs), [ownHave.id, myCandidateForPartner.id])
        XCTAssertEqual(Set(aggregate.receiverIDs), [partnerCandidateForMe.id, partnerHave.id])
    }

    func testRelationSwipeItemsPreserveMatchedOrderAndIncludeCurrentWhenMissing() {
        let viewerID = uuid(1)
        let first = goods(id: 100, ownerID: viewerID)
        let second = goods(id: 101, ownerID: viewerID)
        let current = goods(id: 102, ownerID: viewerID)

        let ordered = MatchRelationComposer.relationSwipeItems(
            homeMatchedItems: [first, second],
            currentTarget: current
        )

        XCTAssertEqual(ordered.map(\.id), [current.id, first.id, second.id])
        XCTAssertEqual(
            MatchRelationComposer.adjacentSwipeTarget(in: ordered, currentID: current.id, direction: .next)?.id,
            first.id
        )
        XCTAssertNil(
            MatchRelationComposer.adjacentSwipeTarget(in: ordered, currentID: current.id, direction: .previous)
        )
    }

    func testRelationSwipeResolverKeepsVerticalScrollPriorityAndThresholdReturn() {
        XCTAssertNil(
            MatchRelationSwipeResolver.direction(
                for: CGSize(width: 34, height: 44)
            )
        )
        XCTAssertEqual(
            MatchRelationSwipeResolver.direction(
                for: CGSize(width: -84, height: 12)
            ),
            .next
        )
        XCTAssertFalse(
            MatchRelationSwipeResolver.shouldSwitchTarget(
                translation: CGSize(width: -42, height: 4),
                predictedEndTranslationWidth: -56,
                screenWidth: 390,
                hasAdjacentTarget: true
            )
        )
        XCTAssertTrue(
            MatchRelationSwipeResolver.shouldSwitchTarget(
                translation: CGSize(width: -96, height: 8),
                predictedEndTranslationWidth: -124,
                screenWidth: 390,
                hasAdjacentTarget: true
            )
        )
    }

    func testRelationSwipeResolverAppliesResistanceAtListEdges() throws {
        let resistedOffset = MatchRelationSwipeResolver.presentationOffset(
            translation: CGSize(width: 100, height: 6),
            screenWidth: 390,
            hasAdjacentTarget: false
        )
        let normalOffset = MatchRelationSwipeResolver.presentationOffset(
            translation: CGSize(width: 100, height: 6),
            screenWidth: 390,
            hasAdjacentTarget: true
        )

        XCTAssertEqual(try XCTUnwrap(resistedOffset), 22, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(normalOffset), 100, accuracy: 0.001)
        XCTAssertFalse(
            MatchRelationSwipeResolver.shouldSwitchTarget(
                translation: CGSize(width: 180, height: 8),
                predictedEndTranslationWidth: 240,
                screenWidth: 390,
                hasAdjacentTarget: false
            )
        )
    }

    func testDefaultPopupTargetFollowsHighlightedCandidate() {
        let viewerID = uuid(1)
        let partnerID = uuid(2)
        let groupID = uuid(20)
        let typeID = uuid(21)
        let ownHave = goods(id: 110, ownerID: viewerID, groupID: groupID, goodsTypeID: typeID)
        let highlighted = goods(id: 111, ownerID: partnerID, groupID: groupID, goodsTypeID: typeID)
        let alternative = goods(id: 112, ownerID: partnerID, groupID: groupID, goodsTypeID: typeID)
        let listing = IndividualListing(
            id: uuid(120),
            ownerID: viewerID,
            haves: [ListingItemQuantity(itemID: ownHave.id, quantity: 1)],
            options: [
                IndividualListingWishOption(
                    id: uuid(121),
                    listingID: uuid(120),
                    position: 1,
                    wishes: [
                        ListingItemQuantity(itemID: highlighted.id, quantity: 1),
                        ListingItemQuantity(itemID: alternative.id, quantity: 1)
                    ],
                    logic: .all,
                    wishGroupID: groupID,
                    wishGoodsTypeID: typeID
                )
            ]
        )

        let details = MatchRelationComposer.buildRelationDetails(
            ownListings: [listing],
            partnerListings: [],
            senderGoods: [ownHave],
            partnerGoods: [highlighted, alternative],
            highlightedItemID: highlighted.id
        )

        let popupTarget = MatchRelationComposer.defaultPopupTarget(
            for: details,
            highlightedItemID: highlighted.id
        )

        XCTAssertEqual(popupTarget?.listingID, listing.id)
        XCTAssertEqual(popupTarget?.viewpoint, .mine)
        XCTAssertEqual(popupTarget?.wish.id, highlighted.id)
        XCTAssertEqual(popupTarget?.fallbackHave.id, ownHave.id)
    }

    func testWishRowSelectionHelpersMirrorPopupSelectionStrip() {
        let viewerID = uuid(1)
        let wish = MatchRelationWish(
            item: goods(id: 130, ownerID: viewerID),
            quantity: 1,
            candidates: [
                MatchRelationCandidate(item: goods(id: 131, ownerID: viewerID), quantity: 1),
                MatchRelationCandidate(item: goods(id: 132, ownerID: viewerID), quantity: 1)
            ]
        )

        XCTAssertFalse(
            MatchRelationComposer.hasSelectedCandidate(
                for: wish,
                selectedCandidateIDs: []
            )
        )
        XCTAssertEqual(
            MatchRelationComposer.selectedCandidates(
                for: wish,
                selectedCandidateIDs: [uuid(132)]
            )
            .map(\.id),
            [uuid(132)]
        )
    }

    func testWishPopupCopyMatchesRNBottomSheetLabels() {
        XCTAssertEqual(
            MatchRelationPopupCopy.subtitle(quantity: 1, candidateCount: 2),
            "wish ×1・2 件の候補"
        )
        XCTAssertEqual(
            MatchRelationPopupCopy.fallbackTitle("item-130"),
            "↑ あなたの譲：item-130"
        )
        XCTAssertEqual(
            MatchRelationPopupCopy.candidateOwnerTitle(viewpoint: .mine, partnerHandle: "michilion"),
            "@michilion が譲るもの"
        )
    }

    func testNativePreviewRelationCandidateSheetMatchesRNExpandedScenario() throws {
        let target = try XCTUnwrap(NativePreviewData.homeMatchedItems.first)
        let details = MatchRelationComposer.buildRelationDetails(
            ownListings: NativePreviewData.listings,
            partnerListings: NativePreviewData.publicListings,
            senderGoods: NativePreviewData.inventory,
            partnerGoods: NativePreviewData.homeMatchedItems,
            highlightedItemID: target.id
        )
        let popupTarget = try XCTUnwrap(
            MatchRelationComposer.defaultPopupTarget(
                for: details,
                highlightedItemID: target.id
            )
        )

        XCTAssertEqual(popupTarget.wish.item.title, "スア 春ver.")
        XCTAssertEqual(popupTarget.wish.candidates.map(\.item.title), ["スア 春ver.", "スア 会場限定"])
        XCTAssertEqual(MatchRelationPopupCopy.subtitle(quantity: popupTarget.wish.quantity, candidateCount: popupTarget.wish.candidates.count), "wish ×1・2 件の候補")
    }

    func testBottomBarCopyMatchesRelationAndSimpleProposalModes() {
        XCTAssertEqual(
            MatchRelationBottomBarCopy.primaryTitle(
                isEnabled: true,
                showsReset: true,
                totalSelectionCount: 2
            ),
            "打診に進む（2件）"
        )
        XCTAssertEqual(
            MatchRelationBottomBarCopy.primaryTitle(
                isEnabled: true,
                showsReset: false,
                totalSelectionCount: 1
            ),
            "この内容で打診へ"
        )
        XCTAssertEqual(
            MatchRelationBottomBarCopy.primaryTitle(
                isEnabled: false,
                showsReset: false,
                totalSelectionCount: 0
            ),
            "候補を読み込んでいます"
        )
        XCTAssertEqual(
            MatchRelationBottomBarCopy.secondaryTitle(showsReset: true),
            "リセット"
        )
        XCTAssertEqual(
            MatchRelationBottomBarCopy.secondaryTitle(showsReset: false),
            "閉じる"
        )
    }

    private func goods(
        id: Int,
        ownerID: UUID,
        status: GoodsEntryStatus? = .active,
        groupID: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000020")!,
        goodsTypeID: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000021")!
    ) -> GoodsItem {
        GoodsItem(
            id: uuid(id),
            ownerID: ownerID,
            kind: .inventory,
            status: status,
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "item-\(id)"
        )
    }

    private func uuid(_ suffix: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", suffix))!
    }
}
