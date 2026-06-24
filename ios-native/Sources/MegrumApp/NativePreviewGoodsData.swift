import Foundation
import MegrumCore

extension NativePreviewData {
    static let inventory: [GoodsItem] = [
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000201")!,
            ownerID: viewerID,
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: cardGoodsTypeID,
            title: "モモ 2026 LIVE",
            imageURL: testGoodsImageURL("twice_momo_2"),
            tags: [tags[3], tags[6], tags[2]],
            quantity: 1,
            exchangeMethod: .both,
            ownerPrefecture: "東京都",
            ownerPaymentMethods: ownerPaymentMethods(for: viewerID),
            ownerPaymentNote: ownerPaymentNote(for: viewerID)
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000202")!,
            ownerID: viewerID,
            groupID: thirdGroupID,
            memberID: thirdMemberID,
            goodsTypeID: cardGoodsTypeID,
            title: "ジョングク トレカ",
            imageURL: testGoodsImageURL("bts_jungkook"),
            tags: [tags[4], tags[2]],
            quantity: 1,
            exchangeMethod: .mail,
            ownerPrefecture: "東京都",
            ownerPaymentMethods: ownerPaymentMethods(for: viewerID),
            ownerPaymentNote: ownerPaymentNote(for: viewerID)
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000203")!,
            ownerID: partnerID,
            status: .traded,
            groupID: secondGroupID,
            memberID: secondMemberID,
            goodsTypeID: cardGoodsTypeID,
            title: "サナ 2026 LIVE",
            imageURL: testGoodsImageURL("twice_sana_1"),
            tags: [tags[3], tags[6], tags[2]],
            quantity: 1,
            exchangeMethod: .hand,
            ownerPrefecture: "福岡県",
            ownerPaymentMethods: ownerPaymentMethods(for: partnerID),
            ownerPaymentNote: ownerPaymentNote(for: partnerID)
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000204")!,
            ownerID: partnerID,
            groupID: groupID,
            goodsTypeID: acrylicStandGoodsTypeID,
            title: "ニンニン 制服",
            imageURL: testGoodsImageURL("aespa_ningning"),
            tags: [tags[0], tags[2]],
            quantity: 1,
            exchangeMethod: .both,
            ownerPrefecture: "東京都",
            ownerPaymentMethods: ownerPaymentMethods(for: partnerID),
            ownerPaymentNote: ownerPaymentNote(for: partnerID)
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000205")!,
            ownerID: partnerID,
            groupID: secondGroupID,
            memberID: secondMemberID,
            goodsTypeID: cardGoodsTypeID,
            title: "モモ ファンミ",
            imageURL: testGoodsImageURL("twice_momo_1"),
            tags: [tags[3], tags[1], tags[2]],
            quantity: 1,
            exchangeMethod: .hand,
            ownerPrefecture: "大阪府",
            ownerPaymentMethods: ownerPaymentMethods(for: partnerID),
            ownerPaymentNote: ownerPaymentNote(for: partnerID)
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000206")!,
            ownerID: partnerID,
            groupID: groupID,
            goodsTypeID: cardGoodsTypeID,
            title: "ダヒョン 缶バッジ",
            imageURL: testGoodsImageURL("twice_dahyun_1"),
            tags: [tags[3], tags[7]],
            quantity: 1,
            exchangeMethod: .mail,
            ownerPrefecture: "東京都",
            ownerPaymentMethods: ownerPaymentMethods(for: partnerID),
            ownerPaymentNote: ownerPaymentNote(for: partnerID)
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000207")!,
            ownerID: partnerID,
            groupID: thirdGroupID,
            memberID: thirdMemberID,
            goodsTypeID: cardGoodsTypeID,
            title: "V トレカ",
            imageURL: testGoodsImageURL("bts_v"),
            tags: [tags[4], tags[2]],
            quantity: 1,
            exchangeMethod: .both,
            ownerPrefecture: "兵庫県",
            ownerPaymentMethods: ownerPaymentMethods(for: partnerID),
            ownerPaymentNote: ownerPaymentNote(for: partnerID)
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000208")!,
            ownerID: partnerID,
            groupID: thirdGroupID,
            goodsTypeID: cardGoodsTypeID,
            title: "Joshua トレカ",
            imageURL: testGoodsImageURL("svt_joshua", fileExtension: "jpg"),
            tags: [tags[5], tags[2]],
            quantity: 1,
            exchangeMethod: .hand,
            ownerPrefecture: "愛知県",
            ownerPaymentMethods: ownerPaymentMethods(for: partnerID),
            ownerPaymentNote: ownerPaymentNote(for: partnerID)
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000209")!,
            ownerID: partnerID,
            groupID: groupID,
            goodsTypeID: cardGoodsTypeID,
            title: "S.Coups トレカ",
            imageURL: testGoodsImageURL("svt_scoups", fileExtension: "jpg"),
            tags: [tags[5], tags[2]],
            quantity: 1,
            exchangeMethod: .mail,
            ownerPrefecture: "神奈川県",
            ownerPaymentMethods: ownerPaymentMethods(for: partnerID),
            ownerPaymentNote: ownerPaymentNote(for: partnerID)
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000210")!,
            ownerID: viewerID,
            groupID: groupID,
            goodsTypeID: acrylicStandGoodsTypeID,
            title: "TWICE ペンライト",
            imageURL: testGoodsImageURL("twice_penlight"),
            tags: [tags[3], tags[6]],
            quantity: 1,
            exchangeMethod: .both,
            ownerPrefecture: "東京都",
            ownerPaymentMethods: ownerPaymentMethods(for: viewerID),
            ownerPaymentNote: ownerPaymentNote(for: viewerID)
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000211")!,
            ownerID: viewerID,
            groupID: thirdGroupID,
            memberID: thirdMemberID,
            goodsTypeID: cardGoodsTypeID,
            title: "ジミン トレカ",
            imageURL: testGoodsImageURL("bts_jimin"),
            tags: [tags[4], tags[2]],
            quantity: 1,
            exchangeMethod: .mail,
            ownerPrefecture: "東京都",
            ownerPaymentMethods: ownerPaymentMethods(for: viewerID),
            ownerPaymentNote: ownerPaymentNote(for: viewerID)
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000212")!,
            ownerID: viewerID,
            groupID: groupID,
            goodsTypeID: cardGoodsTypeID,
            title: "Mingyu トレカ",
            imageURL: testGoodsImageURL("svt_mingyu", fileExtension: "jpg"),
            tags: [tags[5], tags[2]],
            quantity: 1,
            exchangeMethod: .hand,
            ownerPrefecture: "東京都",
            ownerPaymentMethods: ownerPaymentMethods(for: viewerID),
            ownerPaymentNote: ownerPaymentNote(for: viewerID)
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000213")!,
            ownerID: viewerID,
            groupID: groupID,
            goodsTypeID: acrylicStandGoodsTypeID,
            title: "ニンニン トレカ",
            imageURL: testGoodsImageURL("aespa_ningning_2"),
            tags: [tags[0], tags[2]],
            quantity: 1,
            exchangeMethod: .both,
            ownerPrefecture: "東京都",
            ownerPaymentMethods: ownerPaymentMethods(for: viewerID),
            ownerPaymentNote: ownerPaymentNote(for: viewerID)
        )
    ]

    static let wishes: [WishItem] = [
        WishItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000301")!,
            ownerID: viewerID,
            groupID: secondGroupID,
            memberID: secondMemberID,
            goodsTypeID: cardGoodsTypeID,
            title: "スア ラキドロ",
            imageURL: testGoodsImageURL("twice_sana_1"),
            tags: [tags[3], tags[6], tags[2]]
        ),
        WishItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000302")!,
            ownerID: viewerID,
            groupID: groupID,
            goodsTypeID: acrylicStandGoodsTypeID,
            title: "ニンニン 制服",
            imageURL: testGoodsImageURL("aespa_ningning"),
            tags: [tags[0], tags[2]]
        )
    ]

    static var homeMatchedItems: [GoodsItem] {
        partnerGoods + viewerGoods
    }

    static var homePossibleItems: [GoodsItem] {
        viewerGoods + partnerGoods
    }

    private static var partnerGoods: [GoodsItem] {
        inventory.filter { $0.ownerID == partnerID }
    }

    private static var viewerGoods: [GoodsItem] {
        inventory.filter { $0.ownerID == viewerID }
    }
}
