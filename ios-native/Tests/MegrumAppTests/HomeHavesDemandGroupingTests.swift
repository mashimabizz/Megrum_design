@testable import MegrumApp
import MegrumCore
import XCTest

final class HomeHavesDemandGroupingTests: XCTestCase {
    func testRankedCandidatesDeduplicatesAndSortsByDemandRank() {
        let wanted = makeCandidate(title: "求", wishMatched: true, tentative: false)
        let tentative = makeCandidate(title: "求？", wishMatched: true, tentative: true)
        let none = makeCandidate(title: "合致なし", wishMatched: false, tentative: false)

        let ranked = HomeHavesDemandGrouping.rankedCandidates(
            tagMatched: [tentative, none],
            memberMatched: [wanted, tentative]
        )

        // tentative は tagMatched 側が優先され、memberMatched の重複は除外される。
        XCTAssertEqual(ranked.map(\.candidate.title), ["求", "求？", "合致なし"])
        XCTAssertEqual(ranked.map(\.titleStyle), [.member, .memberTag, .memberTag])
        XCTAssertEqual(ranked.map(\.rank), [4, 3, 0])
    }

    func testSectionsSplitByDemandTierAndDropEmpty() {
        let hot = rankedCandidate(title: "超求", rank: 6)
        let hotTentative = rankedCandidate(title: "超求？", rank: 5)
        let wanted = rankedCandidate(title: "求", rank: 4)
        let other = rankedCandidate(title: "定価", rank: 2)

        let sections = HomeHavesDemandGrouping.sections(
            from: [hot, hotTentative, wanted, other]
        )

        XCTAssertEqual(sections.map(\.title), ["超求！している人", "求めている人", "その他のマッチ"])
        XCTAssertEqual(sections[0].candidates.map(\.candidate.title), ["超求", "超求？"])
        XCTAssertEqual(sections[1].candidates.map(\.candidate.title), ["求"])
        XCTAssertEqual(sections[2].candidates.map(\.candidate.title), ["定価"])

        let onlyWanted = HomeHavesDemandGrouping.sections(from: [wanted])
        XCTAssertEqual(onlyWanted.map(\.title), ["求めている人"])
    }

    // MARK: - Fixtures

    private func rankedCandidate(title: String, rank: Int) -> HomeHavesRankedCandidate {
        HomeHavesRankedCandidate(
            candidate: makeCandidate(title: title, wishMatched: false, tentative: false),
            titleStyle: .member,
            rank: rank
        )
    }

    private func makeCandidate(
        title: String,
        wishMatched: Bool,
        tentative: Bool
    ) -> HomeDiscoveryCandidate {
        let goods = HomeDiscoveryFixtures.sanaLavender
        var signals = HomeCandidateConditionSignalDefaults.noEvidence
        if wishMatched {
            signals.wishMatchedOfferGoodsIDs = [goods.id]
            if tentative {
                signals.wishTentativeOfferGoodsIDs = [goods.id]
            }
        }
        return HomeDiscoveryCandidate(
            id: stableID(for: title),
            title: title,
            signals: signals,
            conditionSignalsByGoodsID: [goods.id: signals],
            sheet: .goodsHit(HomeDiscoverySheetPayload(goods: goods, signals: signals)),
            goods: [goods]
        )
    }

    private func stableID(for title: String) -> UUID {
        // タイトルごとに安定したIDを作る（重複除去テストで同一候補と見なすため）。
        var hash = UInt64(5381)
        for byte in title.utf8 {
            hash = hash &* 33 &+ UInt64(byte)
        }
        let hex = String(format: "%016llx", hash)
        return UUID(uuidString: "00000000-0000-4000-8000-\(hex.prefix(12))") ?? UUID()
    }
}
