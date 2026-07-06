import Foundation
import MegrumCore

/// ホーム常駐「最初の3ステップ」ミッションの達成状況。
/// マイグッズ登録・ほしいもの登録・個別募集作成の3タスクを実データから判定する純ロジック。
struct HomeStarterMissionState: Equatable, Sendable {
    var inventoryDone: Bool
    var wishDone: Bool
    var listingDone: Bool

    var allDone: Bool { inventoryDone && wishDone && listingDone }

    /// 未達成タスク数（0〜3）。
    var remainingCount: Int {
        [inventoryDone, wishDone, listingDone].filter { !$0 }.count
    }

    static func evaluate(
        inventory: [GoodsItem],
        wishes: [WishItem],
        listings: [IndividualListing]
    ) -> HomeStarterMissionState {
        HomeStarterMissionState(
            inventoryDone: !inventory.isEmpty,
            wishDone: !wishes.isEmpty,
            // アーカイブ済み（closed）の個別募集は達成扱いにしない。
            listingDone: listings.contains { $0.status != .closed }
        )
    }
}
