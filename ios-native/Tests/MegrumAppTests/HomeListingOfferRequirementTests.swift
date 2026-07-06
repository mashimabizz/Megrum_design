import Foundation
import MegrumCore
import Testing
@testable import MegrumApp

@Suite("HomeListingSelectionPolicy.requiredOfferCount")
struct HomeListingOfferRequirementTests {
    @Test("「すべて」は指定グッズ数ぶんの選択を要求する")
    func allRequiresDesignatedCount() {
        #expect(
            HomeListingSelectionPolicy.requiredOfferCount(logic: .all, designatedCount: 3, minimumCount: 1) == 3
        )
    }

    @Test("「n個以上」は手持ち数に関係なく n を要求する")
    func atLeastIsNotClamped() {
        #expect(
            HomeListingSelectionPolicy.requiredOfferCount(logic: .atLeast, designatedCount: 0, minimumCount: 4) == 4
        )
    }

    @Test("「どれか1つ」は1つで足りる")
    func oneRequiresSingle() {
        #expect(
            HomeListingSelectionPolicy.requiredOfferCount(logic: .one, designatedCount: 5, minimumCount: 2) == 1
        )
    }
}
