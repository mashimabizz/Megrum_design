import MegrumDesign
import SwiftUI

extension HomeDiscoveryFixtures {
    static let selectedYellow = HomeMockGoods.make(
        "000000000901",
        title: "サナ",
        subtitle: "2026 LIVE",
        groupID: fixtureGroupID,
        memberID: sanaMemberID,
        goodsTypeID: NativePreviewData.cardGoodsTypeID,
        groupName: "TWICE",
        memberName: "サナ",
        goodsTypeName: "トレカ",
        shape: .portrait,
        palette: [
            Color(red: 0.95, green: 0.84, blue: 0.58),
            MegrumTheme.pink.opacity(0.56),
            MegrumTheme.lavender.opacity(0.34)
        ],
        symbol: "S",
        imageURL: imageURL("twice_sana_1")
    )

    static let sanaLavender = HomeMockGoods.make(
        "000000000902",
        title: "サナ",
        subtitle: "トレカ",
        groupID: fixtureGroupID,
        memberID: sanaMemberID,
        goodsTypeID: NativePreviewData.cardGoodsTypeID,
        groupName: "TWICE",
        memberName: "サナ",
        goodsTypeName: "トレカ",
        displayTags: ["#2026 LIVE"],
        rawTagNames: ["2026 live"],
        shape: .portrait,
        palette: [
            MegrumTheme.lavender.opacity(0.78),
            Color.white.opacity(0.78),
            MegrumTheme.sky.opacity(0.38)
        ],
        symbol: "S",
        imageURL: imageURL("twice_momo_2")
    )

    static let momoFanmi = HomeMockGoods.make(
        "000000000903",
        title: "モモ",
        subtitle: "ファンミ",
        groupID: fixtureGroupID,
        memberID: momoMemberID,
        goodsTypeID: NativePreviewData.cardGoodsTypeID,
        groupName: "TWICE",
        memberName: "モモ",
        goodsTypeName: "トレカ",
        displayTags: ["#ファンミ"],
        rawTagNames: ["ファンミ"],
        shape: .portrait,
        palette: [
            Color(red: 0.92, green: 0.70, blue: 0.58),
            MegrumTheme.pink.opacity(0.68),
            MegrumTheme.lavender.opacity(0.36)
        ],
        symbol: "M",
        imageURL: imageURL("twice_momo_1")
    )

    static let momoFanmiAlt = HomeMockGoods.make(
        "000000000908",
        title: "モモ",
        subtitle: "ファンミ",
        groupID: fixtureGroupID,
        memberID: momoMemberID,
        goodsTypeID: NativePreviewData.cardGoodsTypeID,
        groupName: "TWICE",
        memberName: "モモ",
        goodsTypeName: "トレカ",
        displayTags: ["#ファンミ"],
        rawTagNames: ["ファンミ"],
        shape: .portrait,
        palette: [
            MegrumTheme.sky.opacity(0.50),
            Color.white.opacity(0.86),
            MegrumTheme.pink.opacity(0.52)
        ],
        symbol: "M",
        imageURL: imageURL("twice_momo_2")
    )

    static let momoFanmiStand = HomeMockGoods.make(
        "000000000909",
        title: "モモ",
        subtitle: "ファンミ",
        groupID: fixtureGroupID,
        memberID: momoMemberID,
        goodsTypeID: NativePreviewData.cardGoodsTypeID,
        groupName: "TWICE",
        memberName: "モモ",
        goodsTypeName: "トレカ",
        displayTags: ["#ファンミ"],
        rawTagNames: ["ファンミ"],
        shape: .stand,
        palette: [
            Color.white,
            MegrumTheme.pink.opacity(0.34),
            MegrumTheme.lavender.opacity(0.30)
        ],
        symbol: "M",
        imageURL: imageURL("twice_momo_1")
    )

    static let sanaBadge = HomeMockGoods.make(
        "000000000904",
        title: "サナ",
        subtitle: "缶バッジ",
        groupID: fixtureGroupID,
        memberID: sanaMemberID,
        goodsTypeID: NativePreviewData.cardGoodsTypeID,
        groupName: "TWICE",
        memberName: "サナ",
        goodsTypeName: "缶バッジ",
        shape: .badge,
        palette: [
            MegrumTheme.sky.opacity(0.60),
            Color.white.opacity(0.92),
            MegrumTheme.pink.opacity(0.38)
        ],
        symbol: "S",
        imageURL: imageURL("twice_dahyun_1")
    )

    static let sanaStand = HomeMockGoods.make(
        "000000000905",
        title: "サナ",
        subtitle: "アクスタ",
        groupID: fixtureGroupID,
        memberID: sanaMemberID,
        goodsTypeID: NativePreviewData.acrylicStandGoodsTypeID,
        groupName: "TWICE",
        memberName: "サナ",
        goodsTypeName: "アクスタ",
        shape: .stand,
        palette: [
            Color.white,
            MegrumTheme.lavender.opacity(0.28),
            MegrumTheme.sky.opacity(0.22)
        ],
        symbol: "S",
        imageURL: imageURL("aespa_ningning")
    )

    static let sanaKeychain = HomeMockGoods.make(
        "000000000906",
        title: "サナ",
        subtitle: "キーホルダー",
        groupID: fixtureGroupID,
        memberID: sanaMemberID,
        goodsTypeID: NativePreviewData.cardGoodsTypeID,
        groupName: "TWICE",
        memberName: "サナ",
        goodsTypeName: "キーホルダー",
        shape: .keychain,
        palette: [
            Color.white,
            MegrumTheme.pink.opacity(0.30),
            MegrumTheme.lavender.opacity(0.42)
        ],
        symbol: "S",
        imageURL: imageURL("bts_jungkook")
    )

    static let plush = HomeMockGoods.make(
        "000000000907",
        title: "サナ",
        subtitle: "ぬい",
        groupID: fixtureGroupID,
        memberID: sanaMemberID,
        goodsTypeID: NativePreviewData.cardGoodsTypeID,
        groupName: "TWICE",
        memberName: "サナ",
        goodsTypeName: "ぬい",
        shape: .plush,
        palette: [
            MegrumTheme.lavender.opacity(0.46),
            Color.white.opacity(0.82),
            MegrumTheme.sky.opacity(0.28)
        ],
        symbol: "♡",
        imageURL: imageURL("bts_v")
    )
}
