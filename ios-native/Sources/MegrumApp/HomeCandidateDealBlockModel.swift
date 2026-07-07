import Foundation
import MegrumCore

/// 候補シート再設計（notes/19）の取引ブロック（3列：受け取る｜相手希望｜譲る）の描画モデル。
/// 選択状態・数量ラベル・達成カウンタまで純粋データとして持ち、View は index → トグルへ橋渡しするだけにする。iter1226.374。
struct HomeDealBlockModel: Equatable {
    var receive: HomeDealReceiveColumn
    var partner: HomeDealPartnerColumn
    var offer: HomeDealOfferColumn
    var achievement: HomeDealAchievement?
}

/// 受け取る列（相手から受け取るもの）。数量ラベルは複数時のみ。
struct HomeDealReceiveColumn: Equatable {
    var qtyLabel: String?
    var selectable: Bool
    var cells: [HomeDealGoodsCell]
}

/// 相手希望列。指名なら相手のほしいもの画像を1件ずつ、条件なら条件タイル。
struct HomeDealPartnerColumn: Equatable {
    var kind: HomeIndividualListingWantedOption.Kind
    /// 指名：相手のほしいもの（namedItems[i] が offer.rows[i] と1対1）。
    var namedItems: [HomeDealWishCell]
    /// 条件：条件タイル。
    var conditionTile: HomeDealConditionTile?
}

/// 譲る列（自分の候補）。指名は行が namedItems と1対1、条件は1行にフラット表示。
struct HomeDealOfferColumn: Equatable {
    var qtyLabel: String?
    var isNamed: Bool
    var rows: [HomeDealOfferRow]
}

struct HomeDealOfferRow: Equatable, Identifiable {
    var id: UUID
    var cells: [HomeDealGoodsCell]
}

/// 譲る/受け取るセル。index は offerGoods / receiveGoods の位置（トグル用）。
struct HomeDealGoodsCell: Equatable, Identifiable {
    var id: UUID
    var index: Int
    var imageURL: URL?
    var title: String
    var selected: Bool
    var selectable: Bool
    var tentative: Bool
}

/// 相手のほしいもの画像セル（相手希望・指名）。
struct HomeDealWishCell: Equatable, Identifiable {
    var id: UUID
    var imageURL: URL?
    var title: String
}

/// 条件タイル（スライダーアイコン＋不確定なら「?」＋条件文トークン）。
struct HomeDealConditionTile: Equatable {
    var tokens: [String]
    var tentative: Bool
    var selected: Bool
    /// 条件タイルの選択トグルに使う wanted オプション index（displayedWantedOptionIndex）。
    var wantedOptionIndex: Int?
}

/// 取引ブロック直下の達成カウンタ。
struct HomeDealAchievement: Equatable {
    var text: String
    var satisfied: Bool
}

/// 条件パターンの「条件のグッズを確認！」セクション。notes/19 Phase4。
/// ①参考画像2枚があればそれを、②無ければ「グループ メンバー #シリーズ」でGoogle画像検索。①②は排他。
struct HomeConditionSeriesCheckModel: Equatable {
    /// ① 参考グッズ画像（この推し×シリーズ）。2枚以上あれば①、無ければ②。
    var referenceImageURLs: [URL]
    /// ② Google画像検索クエリ（例「BTS RM #DICON D'FESTA」）。
    var searchQuery: String
    /// ② 検索URL。
    var searchURL: URL?

    var usesReferenceImages: Bool {
        referenceImageURLs.count >= 2
    }
}
