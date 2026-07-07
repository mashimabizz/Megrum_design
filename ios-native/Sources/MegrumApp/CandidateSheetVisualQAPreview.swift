import Foundation
import MegrumCore
import SwiftUI

/// VisualQA 用：候補シート再設計（notes/19）を実データ相当のサンプルで直接表示する。
/// `MEGRUM_VISUAL_QA_INITIAL_SCREEN=candidate-sheet` で起動。指名（相手ほしいもの2件↔自分候補2件）＋条件＋定価の3選択肢を持つ。iter1226.374。
struct CandidateSheetVisualQAPreview: View {
    /// `MEGRUM_VISUAL_QA_CANDIDATE_VARIANT` = named（既定）/ condition / cash で先頭選択肢を切替。
    private var variant: CandidateSheetVisualQASample.Variant {
        CandidateSheetVisualQASample.Variant(
            rawValue: ProcessInfo.processInfo.environment["MEGRUM_VISUAL_QA_CANDIDATE_VARIANT"] ?? ""
        ) ?? .named
    }

    var body: some View {
        HomeGoodsHitDetailSheet(
            selection: CandidateSheetVisualQASample.payload(variant: variant),
            viewerOfferGoods: CandidateSheetVisualQASample.viewerOfferGoods(variant: variant),
            addedExtraCandidateIDs: [],
            showsOtherExchangeRows: false,
            bottomButtonTitle: "この内容で打診に進む",
            preselectPreferredOffer: true,
            onOpenOwnerProfile: { _ in },
            onOpenNestedSheet: { _ in },
            onStartProposal: { _ in },
            onCopyToWish: { _ in },
            isWishCopyInProgress: false
        )
    }
}

enum CandidateSheetVisualQASample {
    enum Variant: String {
        case named
        case condition
        case cash
        case crowded
    }

    // HomeMockGoods.make が使うプレフィックスと一致させ、matchingGoodsIDs と手持ちIDを噛み合わせる。
    private static func uuid(_ tail: String) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-\(tail)")!
    }

    private static func image(_ name: String) -> URL? {
        NativePreviewData.testGoodsImageURL(name, fileExtension: "png")
    }

    private static let ownerID = uuid("000000000001")
    private static let listingID = uuid("000000000010")

    private static let rmMemberID = uuid("000000000201")
    private static let jinMemberID = uuid("000000000202")

    private static let myRMID = uuid("000000000101")
    private static let myJinID = uuid("000000000102")
    private static let partnerWishRMID = uuid("000000000301")
    private static let partnerWishJinID = uuid("000000000302")

    private static let crowdedImageNames = ["twice_momo_1", "twice_dahyun_1", "bts_v", "twice_sana_1", "aespa_ningning", "twice_momo_1"]
    private static let crowdedMembers = ["RM", "ジン", "SUGA", "j-hope", "ジミン", "ユンギ"]

    /// crowded 用：条件に合う手持ち候補6件（ゆずる列の「他N件を見る」検証）。
    private static var crowdedViewerGoods: [HomeMockGoods] {
        (0..<6).map { i in
            HomeMockGoods.make(
                "00000000011\(i)",
                title: "\(crowdedMembers[i]) トレカ（自分）",
                subtitle: "BTS / トレカ",
                memberID: uuid("00000000031\(i)"),
                groupName: "BTS",
                memberName: crowdedMembers[i],
                goodsTypeName: "トレカ",
                shape: .portrait,
                palette: [],
                symbol: String(crowdedMembers[i].prefix(1)),
                imageURL: image(crowdedImageNames[i])
            )
        }
    }

    static func viewerOfferGoods(variant: Variant = .named) -> [HomeMockGoods] {
        variant == .crowded ? crowdedViewerGoods : viewerOfferGoods
    }

    /// 自分の手持ち候補（譲る側）。指名の相手ほしいものに1対1で充てられる。
    static var viewerOfferGoods: [HomeMockGoods] {
        [
            HomeMockGoods.make(
                "000000000101",
                title: "RM トレカ（自分）",
                subtitle: "BTS / トレカ",
                memberID: rmMemberID,
                groupName: "BTS",
                memberName: "RM",
                goodsTypeName: "トレカ",
                shape: .portrait,
                palette: [],
                symbol: "R",
                imageURL: image("twice_momo_1")
            ),
            HomeMockGoods.make(
                "000000000102",
                title: "ジン トレカ（自分）",
                subtitle: "BTS / トレカ",
                memberID: jinMemberID,
                groupName: "BTS",
                memberName: "ジン",
                goodsTypeName: "トレカ",
                shape: .portrait,
                palette: [],
                symbol: "J",
                imageURL: image("twice_dahyun_1")
            ),
        ]
    }

    /// 相手の選んだグッズ（受け取る側に出る）。
    private static var partnerGoods: HomeMockGoods {
        HomeMockGoods.make(
            "000000000020",
            title: "V スペシャルフォト",
            subtitle: "BTS / フォト",
            ownerID: ownerID,
            ownerDisplayName: "michilion",
            ownerHandle: "michilion",
            ownerGender: .female,
            ownerAge: 27,
            ownerAverageStars: 4.7,
            ownerEvaluationCount: 8,
            ownerPrefecture: "東京都",
            groupName: "BTS",
            memberName: "V",
            goodsTypeName: "フォト",
            shape: .portrait,
            palette: [],
            symbol: "V",
            imageURL: image("bts_v")
        )
    }

    private static var namedOption: HomeIndividualListingWantedOption {
        HomeIndividualListingWantedOption(
            id: uuid("000000000401"),
            listingID: listingID,
            position: 0,
            title: "RM・ジンを指名",
            subtitle: "2件を指名",
            logic: .all,
            minimumCount: 1,
            kind: .goods,
            goodsIDs: [partnerWishRMID, partnerWishJinID],
            matchingGoodsIDs: [myRMID, myJinID],
            tentativeGoodsIDs: [],
            previewItems: [
                HomeIndividualListingWantedPreviewItem(id: partnerWishRMID, title: "RM 希望", imageURL: image("twice_sana_1")),
                HomeIndividualListingWantedPreviewItem(id: partnerWishJinID, title: "ジン 希望", imageURL: image("aespa_ningning")),
            ],
            namedPairings: [
                HomeWantedNamedPairing(id: partnerWishRMID, title: "RM 希望", imageURL: image("twice_sana_1"), characterID: rmMemberID, candidateGoodsIDs: [myRMID]),
                HomeWantedNamedPairing(id: partnerWishJinID, title: "ジン 希望", imageURL: image("aespa_ningning"), characterID: jinMemberID, candidateGoodsIDs: [myJinID]),
            ]
        )
    }

    private static var conditionOption: HomeIndividualListingWantedOption {
        HomeIndividualListingWantedOption(
            id: uuid("000000000402"),
            listingID: listingID,
            position: 1,
            title: "条件",
            subtitle: "条件に合うもの",
            logic: .one,
            minimumCount: 1,
            kind: .condition,
            goodsIDs: [],
            matchingGoodsIDs: [myRMID],
            tentativeGoodsIDs: [],
            groupID: uuid("000000000501"),
            conditionSummary: "BTS / トレカ / #DICON D'FESTA"
        )
    }

    private static var cashOption: HomeIndividualListingWantedOption {
        HomeIndividualListingWantedOption(
            id: uuid("000000000403"),
            listingID: listingID,
            position: 2,
            title: "定価",
            subtitle: "金額で受け取る",
            logic: .one,
            kind: .cash,
            cashAmount: 1500
        )
    }

    private static var crowdedConditionOption: HomeIndividualListingWantedOption {
        HomeIndividualListingWantedOption(
            id: uuid("000000000404"),
            listingID: listingID,
            position: 0,
            title: "条件",
            subtitle: "条件に合うもの",
            logic: .one,
            minimumCount: 1,
            kind: .condition,
            matchingGoodsIDs: (0..<6).map { uuid("00000000011\($0)") },
            groupID: uuid("000000000501"),
            conditionSummary: "BTS / トレカ / #DICON D'FESTA"
        )
    }

    /// crowded 用：相手が渡す（受け取る）グッズ5件。うけとる列の「+N」→一覧ポップアップ検証。
    private static var crowdedDetail: HomeIndividualListingDetailContext {
        let items = (0..<5).map { i in
            HomeIndividualListingOfferedItem(
                id: uuid("00000000012\(i)"),
                title: "\(crowdedMembers[i]) フォト",
                imageURL: image(crowdedImageNames[i]),
                quantity: 1
            )
        }
        return HomeIndividualListingDetailContext(
            listingID: listingID,
            wantedLogic: .one,
            offeredLogic: .all,
            wantedOptions: [crowdedConditionOption],
            offeredItems: items
        )
    }

    static func payload(variant: Variant = .named) -> HomeDiscoverySheetPayload {
        // 条件/定価は単独選択肢で確実に自動選択させ、その相手希望・金額入力を検証する。
        // named は3選択肢を持たせて選択肢ピルも検証する。crowded は多数の畳み方を検証する。
        let ordered: [HomeIndividualListingWantedOption]
        switch variant {
        case .named:
            ordered = [namedOption, conditionOption, cashOption]
        case .condition:
            ordered = [conditionOption]
        case .cash:
            ordered = [cashOption]
        case .crowded:
            ordered = [crowdedConditionOption]
        }
        let selection = HomeIndividualListingSelectionContext(
            wantedLogic: .one,
            offeredLogic: .all,
            wantedOptions: ordered,
            listingNote: "現地で当日交換できる方を優先します。",
            detail: variant == .crowded ? crowdedDetail : nil,
            listingUpdatedAt: nil
        )
        var signals = HomeCandidateConditionSignalDefaults.noEvidence
        signals.individualListingSelection = selection
        return HomeDiscoverySheetPayload(
            goods: partnerGoods,
            signals: signals,
            preferredOfferGoodsID: myRMID
        )
    }
}
