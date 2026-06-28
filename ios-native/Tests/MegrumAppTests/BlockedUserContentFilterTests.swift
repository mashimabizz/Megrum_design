@testable import MegrumApp
import MegrumCore
import XCTest

final class BlockedUserContentFilterTests: XCTestCase {
    func testFiltersSearchResultsByOwner() {
        let blockedUserID = uuid("00000000-0000-0000-0000-000000000101")
        let visibleUserID = uuid("00000000-0000-0000-0000-000000000102")
        let blockedItem = goods(id: "00000000-0000-0000-0000-000000000201", ownerID: blockedUserID)
        let visibleItem = goods(id: "00000000-0000-0000-0000-000000000202", ownerID: visibleUserID)
        let results = [
            SearchResultItem(item: blockedItem, ownerUserID: blockedUserID, bucket: .possible),
            SearchResultItem(item: visibleItem, ownerUserID: visibleUserID, bucket: .possible)
        ]

        let filtered = BlockedUserContentFilter.searchResults(results, blockedUserIDs: [blockedUserID])

        XCTAssertEqual(filtered.map(\.id), [visibleItem.id])
    }

    func testFiltersHomeSectionsAndMutualCandidatesByPartner() {
        let blockedUserID = uuid("00000000-0000-0000-0000-000000000301")
        let visibleUserID = uuid("00000000-0000-0000-0000-000000000302")
        let viewerID = uuid("00000000-0000-0000-0000-000000000303")
        let blockedItem = goods(id: "00000000-0000-0000-0000-000000000401", ownerID: blockedUserID)
        let visibleItem = goods(id: "00000000-0000-0000-0000-000000000402", ownerID: visibleUserID)
        let viewerItem = goods(id: "00000000-0000-0000-0000-000000000403", ownerID: viewerID)
        let blockedCandidate = mutualCandidate(
            id: "00000000-0000-0000-0000-000000000501",
            partnerID: blockedUserID,
            partnerGoods: [blockedItem],
            viewerGoods: [viewerItem]
        )
        let visibleCandidate = mutualCandidate(
            id: "00000000-0000-0000-0000-000000000502",
            partnerID: visibleUserID,
            partnerGoods: [visibleItem],
            viewerGoods: [viewerItem]
        )
        let sections = HomeCandidateSections(
            matchedItems: [blockedItem, visibleItem],
            possibleItems: [blockedItem],
            conditionSignalsByItemID: [
                blockedItem.id: HomeCandidateConditionSignalDefaults.matched(index: 0),
                visibleItem.id: HomeCandidateConditionSignalDefaults.matched(index: 1)
            ],
            mutualMatchCandidates: [blockedCandidate, visibleCandidate]
        )

        let filtered = BlockedUserContentFilter.homeSections(sections, blockedUserIDs: [blockedUserID])

        XCTAssertEqual(filtered.matchedItems.map(\.id), [visibleItem.id])
        XCTAssertTrue(filtered.possibleItems.isEmpty)
        XCTAssertNil(filtered.conditionSignalsByItemID[blockedItem.id])
        XCTAssertEqual(filtered.mutualMatchCandidates.map(\.id), [visibleCandidate.id])
    }

    private func goods(id: String, ownerID: UUID) -> GoodsItem {
        GoodsItem(
            id: uuid(id),
            ownerID: ownerID,
            title: "候補グッズ"
        )
    }

    private func mutualCandidate(
        id: String,
        partnerID: UUID,
        partnerGoods: [GoodsItem],
        viewerGoods: [GoodsItem]
    ) -> HomeMutualMatchCandidateData {
        HomeMutualMatchCandidateData(
            id: uuid(id),
            partnerID: partnerID,
            partnerName: "相手",
            partnerHandle: "partner",
            partnerInitial: "相",
            partnerArea: "東京都",
            partnerOshiText: "推し",
            partnerGoodsItems: partnerGoods,
            viewerGoodsItems: viewerGoods,
            signals: HomeCandidateConditionSignalDefaults.matched(index: 0),
            attentionKinds: [.ready]
        )
    }

    private func uuid(_ value: String) -> UUID {
        UUID(uuidString: value)!
    }
}
