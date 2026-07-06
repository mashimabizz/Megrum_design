import Foundation
import MegrumCore

/// ガイドツアー中だけホームに流し込むサンプル候補（iter1226.337 オーナー指定の内容）。
/// 実データ（新規ユーザーは空）を汚さずに「候補が並んだ本物のレイアウト」を見せる。
///
/// 推し×シリーズでマッチ（上から）：
///   1. サナ × #DICON D'FESTA MINI EDITION …… あなたの〈グッズ〉が激求！
///   2. ニンニン × #MY WORLD ……………………… あなたの〈グッズ〉が求められている
///   3. V × #LOVE YOURSELF: SPEAK YOURSELF … 定価OK
/// 推しでマッチのラベルはメンバー名のみ（サナ／ニンニン／V）。
/// デモステージ（登録ウィザード／個別募集エディタ）で使うマスタfixture。
/// デモ用AppStateのマスタ読込に依存せず、TWICE×トレカの選択済み状態を確実に描画する。
enum TutorialSampleMasterData {
    static let twiceGroupID = UUID(uuidString: "00000000-0000-0000-9998-000000000001")!
    static let tradingCardTypeID = UUID(uuidString: "00000000-0000-0000-9998-000000000002")!

    static let twiceGroup = OshiGroup(id: twiceGroupID, name: "TWICE")

    static var groups: [OshiGroup] { [twiceGroup] }

    static var goodsTypes: [GoodsType] {
        [GoodsType(id: tradingCardTypeID, name: "トレカ")]
    }

    /// メンバー割当デモ用（サナ・モモ・ダヒョン）。
    static var characters: [OshiCharacter] {
        [
            OshiCharacter(id: UUID(uuidString: "00000000-0000-0000-9998-000000000011")!, groupID: twiceGroupID, name: "サナ"),
            OshiCharacter(id: UUID(uuidString: "00000000-0000-0000-9998-000000000012")!, groupID: twiceGroupID, name: "モモ"),
            OshiCharacter(id: UUID(uuidString: "00000000-0000-0000-9998-000000000013")!, groupID: twiceGroupID, name: "ダヒョン"),
        ]
    }
}

/// ガイドツアー中だけ、めぐりマップに表示するサンプルピン（表示レイヤ注入・実データ不変）。
/// 地図の初期カメラ（東京・位置情報はツアー中抑制）に合わせて配置する。
/// クラスタ闾値は「実効緯度スパン/6.5」。縦長画面では緯度スパンが約0.067度になるため
/// cell ≈ 0.0105度。全ペアの max(dLat,dLng) がこれを超える間隔にしてある。
enum TutorialSampleMeguriData {
    private static let center = (latitude: 35.7056, longitude: 139.7519)

    /// ツアー中に地図へ渡す擬似現在地（1km円・現在地ドット表示用）。
    static var centerCoordinate: MegrumLocationCoordinate {
        MegrumLocationCoordinate(latitude: center.latitude, longitude: center.longitude)
    }

    static var grooms: [GroomPost] {
        let offsets: [(latitude: Double, longitude: Double)] = [
            (0.0145, 0.0000), (0.0025, -0.0125), (-0.0110, 0.0122),
        ]
        return zip(NativePreviewData.grooms.prefix(3), offsets).map { groom, offset in
            var updated = groom
            updated.latitude = center.latitude + offset.latitude
            updated.longitude = center.longitude + offset.longitude
            return updated
        }
    }

    static var threads: [BoardThread] {
        let offsets: [(latitude: Double, longitude: Double)] = [
            (0.0020, 0.0125), (-0.0120, -0.0110),
        ]
        return zip(NativePreviewData.threads.prefix(2), offsets).map { thread, offset in
            var updated = thread
            updated.latitude = center.latitude + offset.latitude
            updated.longitude = center.longitude + offset.longitude
            return updated
        }
    }
}

enum TutorialSampleHomeData {
    // MARK: 固定ID

    private static func uuid(_ suffix: String) -> UUID {
        UUID(uuidString: "00000000-0000-0000-9999-\(suffix)")!
    }

    /// inventoryItems 差し替え時に viewer.id が未確定でも動くための仮ID。
    static let placeholderViewerID = uuid("000000000001")
    static let partnerID = uuid("000000000002")

    private static let sanaItemID = uuid("000000000101")
    private static let ningningItemID = uuid("000000000102")
    private static let vItemID = uuid("000000000103")

    private static let viewerMomoID = uuid("000000000201")
    private static let viewerDahyunID = uuid("000000000202")
    private static let viewerPenlightID = uuid("000000000203")
    private static let viewerMomo2ID = uuid("000000000204")

    private static func tag(_ name: String) -> GoodsTag {
        GoodsTag(id: UUID(), name: name)
    }

    private static func imageURL(_ name: String, _ ext: String = "png") -> URL? {
        NativePreviewData.testGoodsImageURL(name, fileExtension: ext)
    }

    // MARK: 相手側（マッチ候補の3行）

    static var matchedItems: [GoodsItem] {
        [
            GoodsItem(
                id: sanaItemID,
                ownerID: partnerID,
                memberID: uuid("000000000301"),
                groupName: "TWICE",
                memberName: "サナ",
                goodsTypeName: "トレカ",
                title: "サナ DICON トレカ",
                imageURL: imageURL("twice_sana_1"),
                tags: [tag("DICON D'FESTA MINI EDITION")],
                quantity: 1,
                exchangeMethod: .both,
                ownerPrefecture: "東京都"
            ),
            GoodsItem(
                id: ningningItemID,
                ownerID: partnerID,
                memberID: uuid("000000000302"),
                groupName: "aespa",
                memberName: "ニンニン",
                goodsTypeName: "トレカ",
                title: "ニンニン MY WORLD トレカ",
                imageURL: imageURL("aespa_ningning"),
                tags: [tag("MY WORLD")],
                quantity: 1,
                exchangeMethod: .hand,
                ownerPrefecture: "神奈川県"
            ),
            GoodsItem(
                id: vItemID,
                ownerID: partnerID,
                memberID: uuid("000000000303"),
                groupName: "BTS",
                memberName: "V",
                goodsTypeName: "トレカ",
                title: "V SPEAK YOURSELF トレカ",
                imageURL: imageURL("bts_v"),
                tags: [tag("LOVE YOURSELF: SPEAK YOURSELF")],
                quantity: 1,
                exchangeMethod: .both,
                ownerPrefecture: "東京都"
            ),
        ]
    }

    /// 「推しでマッチ」セクションは possibleItems から生成されるため、同じ3件を供給する
    /// （空だとセクション自体が消えてハイライト対象が無くなる：v3.1 FB①）。
    static var possibleItems: [GoodsItem] { matchedItems }

    // MARK: あなた側（求められているグッズ／激求サムネイル用）

    /// ツアー中に inventoryItems へ差し替える「あなたのグッズ」サンプル。
    /// ownItems() のフィルタを通すため、実ユーザーIDで所有者を差し替えて使う。
    static func viewerInventory(ownerID: UUID) -> [GoodsItem] {
        [
            GoodsItem(
                id: viewerMomoID, ownerID: ownerID,
                memberID: uuid("000000000304"), groupName: "TWICE", memberName: "モモ",
                goodsTypeName: "トレカ", title: "モモ トレカ",
                imageURL: imageURL("twice_momo_1"), tags: [tag("Celebrate")], quantity: 1
            ),
            GoodsItem(
                id: viewerDahyunID, ownerID: ownerID,
                memberID: uuid("000000000305"), groupName: "TWICE", memberName: "ダヒョン",
                goodsTypeName: "トレカ", title: "ダヒョン トレカ",
                imageURL: imageURL("twice_dahyun_1"), tags: [tag("READY TO BE")], quantity: 1
            ),
            GoodsItem(
                id: viewerPenlightID, ownerID: ownerID,
                memberID: nil, groupName: "TWICE", memberName: nil,
                goodsTypeName: "ペンライト", title: "TWICE ペンライト",
                imageURL: imageURL("twice_penlight"), tags: [tag("READY TO BE")], quantity: 1
            ),
            GoodsItem(
                id: viewerMomo2ID, ownerID: ownerID,
                memberID: uuid("000000000304"), groupName: "TWICE", memberName: "モモ",
                goodsTypeName: "トレカ", title: "モモ 会場限定トレカ",
                imageURL: imageURL("twice_momo_2"), tags: [tag("会場限定")], quantity: 1
            ),
        ]
    }

    // MARK: シグナル（需要行のバリエーション）

    /// マッチ判定フィルタを通しつつ、行ごとの需要行を明示指定する：
    /// サナ=激求（あなたのモモトレカを指名）／ニンニン=求（ダヒョン等が条件一致）／V=定価。
    /// あわせて「求められているグッズ」レール用に、あなたのグッズへ求められ件数を付与する。
    static var conditionSignals: [UUID: HomeCandidateConditionSignals] {
        var signals = HomeCandidateConditionSignalDefaults.previewSignals(
            matchedItems: matchedItems,
            possibleItems: []
        )

        signals[sanaItemID]?.individualListingSelection = HomeIndividualListingSelectionContext(
            wantedOptions: [
                HomeIndividualListingWantedOption(
                    id: uuid("000000000401"),
                    listingID: uuid("000000000400"),
                    position: 1,
                    title: "モモ トレカ",
                    subtitle: "グッズ指定",
                    kind: .goods,
                    goodsIDs: [viewerMomoID],
                    matchingGoodsIDs: [viewerMomoID]
                ),
            ]
        )
        signals[sanaItemID]?.wishMatchedOfferGoodsIDs = [viewerMomoID]

        signals[ningningItemID]?.individualListingSelection = nil
        signals[ningningItemID]?.wishMatchedOfferGoodsIDs = [viewerDahyunID, viewerPenlightID]

        signals[vItemID]?.individualListingSelection = HomeIndividualListingSelectionContext(
            wantedOptions: [
                HomeIndividualListingWantedOption(
                    id: uuid("000000000402"),
                    listingID: uuid("000000000403"),
                    position: 1,
                    title: "定価1,500円",
                    subtitle: "金額で受け取る条件",
                    kind: .cash,
                    cashAmount: 1500
                ),
            ]
        )
        signals[vItemID]?.wishMatchedOfferGoodsIDs = []

        // あなたのグッズ（求められているグッズのレール）：件数バッジ用。
        let viewerCounts: [(UUID, Int)] = [
            (viewerMomoID, 3), (viewerDahyunID, 2), (viewerPenlightID, 1), (viewerMomo2ID, 2),
        ]
        let viewerItems = viewerInventory(ownerID: placeholderViewerID)
        let viewerBase = HomeCandidateConditionSignalDefaults.previewSignals(
            matchedItems: viewerItems,
            possibleItems: []
        )
        for (id, count) in viewerCounts {
            var signal = viewerBase[id]
            signal?.linkCounts.wishCount = count
            signal?.individualListingSelection = nil
            if let signal {
                signals[id] = signal
            }
        }
        return signals
    }
}
