import MegrumCore
import MegrumDesign
import SwiftUI

enum HomeDiscoverySheet: Identifiable {
    case goodsHit(HomeMockGoods)
    case wishHit(HomeMockGoods)
    case havesLookup
    case extraListingHit
    case extraWishHit

    var id: String {
        switch self {
        case .goodsHit(let goods):
            "goods-hit-\(goods.id.uuidString)"
        case .wishHit(let goods):
            "wish-hit-\(goods.id.uuidString)"
        case .havesLookup:
            "haves-lookup"
        case .extraListingHit:
            "extra-listing-hit"
        case .extraWishHit:
            "extra-wish-hit"
        }
    }
}

enum HomeGoodsCondition: String {
    case direct = "◎"
    case wish = "○"
    case none = "▲"

    var tagTitle: String { "グッズ条件\(rawValue)" }
    var floatingTagTitle: String { "グッズ条件 \(rawValue)" }
    var shortTitle: String { "条件\(rawValue)" }

    var accent: Color {
        switch self {
        case .direct:
            MegrumTheme.lavender
        case .wish:
            MegrumTheme.sky
        case .none:
            MegrumTheme.pink
        }
    }
}

enum HomeExchangeCondition: String {
    case exact = "◎"
    case possible = "○"
    case warning = "▲"

    var tagTitle: String { "交換条件\(rawValue)" }
    var floatingTagTitle: String { "交換条件 \(rawValue)" }

    var accent: Color {
        switch self {
        case .exact:
            MegrumTheme.lavender
        case .possible:
            MegrumTheme.sky
        case .warning:
            MegrumTheme.pink
        }
    }
}

enum HomeMockGoodsShape {
    case portrait
    case badge
    case stand
    case keychain
    case plush
}

struct HomeMockGoods: Identifiable, Equatable {
    var id: UUID
    var title: String
    var subtitle: String
    var displayTags: [String]
    var shape: HomeMockGoodsShape
    var palette: [Color]
    var symbol: String
    var imageURL: URL?

    static func make(
        _ uuidTail: String,
        title: String,
        subtitle: String,
        displayTags: [String] = [],
        shape: HomeMockGoodsShape,
        palette: [Color],
        symbol: String,
        imageURL: URL? = nil
    ) -> HomeMockGoods {
        HomeMockGoods(
            id: UUID(uuidString: "00000000-0000-0000-0000-\(uuidTail)")!,
            title: title,
            subtitle: subtitle,
            displayTags: displayTags,
            shape: shape,
            palette: palette,
            symbol: symbol,
            imageURL: imageURL
        )
    }

    static func from(item: GoodsItem, index: Int, goodsTypes: [GoodsType]) -> HomeMockGoods {
        let displayTags = HomeDiscoveryTagFormatter.displayTags(for: item, goodsTypes: goodsTypes)
        let shape = HomeMockGoodsShape.bestGuess(for: item.title)
        let palette = HomeMockGoodsPalette.palette(for: index, itemID: item.id)
        return HomeMockGoods(
            id: item.id,
            title: item.title,
            subtitle: displayTags.first ?? item.ownerPrefecture ?? item.kind?.inventoryKind ?? "",
            displayTags: displayTags,
            shape: shape,
            palette: palette,
            symbol: item.title.first.map(String.init) ?? "M",
            imageURL: item.imageURL
        )
    }
}

struct HomeDiscoveryCandidate: Identifiable {
    var id: UUID
    var title: String
    var signals: HomeCandidateConditionSignals
    var sheet: HomeDiscoverySheet
    var goods: [HomeMockGoods]

    var goodsCondition: HomeGoodsCondition {
        HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods)
    }

    var exchangeCondition: HomeExchangeCondition {
        HomeDiscoveryMatchPolicy.exchangeCondition(for: signals.exchange)
    }

    var linkedCount: Int {
        signals.linkCounts.totalCount
    }

    func sheet(selectedGoods: HomeMockGoods? = nil) -> HomeDiscoverySheet {
        let goods = selectedGoods ?? goods.first
        switch sheet {
        case .goodsHit(let fallbackGoods):
            return .goodsHit(goods ?? fallbackGoods)
        case .wishHit(let fallbackGoods):
            return .wishHit(goods ?? fallbackGoods)
        case .havesLookup, .extraListingHit, .extraWishHit:
            return sheet
        }
    }
}

extension HomeMockGoodsShape {
    static func bestGuess(for title: String) -> HomeMockGoodsShape {
        if title.contains("缶") || title.localizedCaseInsensitiveContains("badge") {
            return .badge
        }
        if title.contains("アクスタ") || title.contains("スタンド") {
            return .stand
        }
        if title.contains("キーホルダー") || title.localizedCaseInsensitiveContains("key") {
            return .keychain
        }
        if title.contains("ぬい") || title.localizedCaseInsensitiveContains("plush") {
            return .plush
        }
        return .portrait
    }
}

private enum HomeMockGoodsPalette {
    static func palette(for index: Int, itemID: UUID) -> [Color] {
        let seed = abs(itemID.uuidString.hashValue + index)
        let palettes: [[Color]] = [
            [
                Color(red: 0.95, green: 0.84, blue: 0.58),
                MegrumTheme.pink.opacity(0.56),
                MegrumTheme.lavender.opacity(0.34)
            ],
            [
                MegrumTheme.lavender.opacity(0.78),
                Color.white.opacity(0.78),
                MegrumTheme.sky.opacity(0.38)
            ],
            [
                Color(red: 0.92, green: 0.70, blue: 0.58),
                MegrumTheme.pink.opacity(0.68),
                MegrumTheme.lavender.opacity(0.36)
            ],
            [
                MegrumTheme.sky.opacity(0.60),
                Color.white.opacity(0.92),
                MegrumTheme.pink.opacity(0.38)
            ]
        ]
        return palettes[seed % palettes.count]
    }
}

enum HomeDiscoveryCandidateSource {
    case userTag
    case user
    case haves
}

enum HomeDiscoveryTagFormatter {
    private static let fallbackGoodsTypeNames = [
        "トレカ",
        "生写真",
        "缶バッジ",
        "缶バ",
        "アクスタ",
        "アクリルスタンド",
        "キーホルダー",
        "ぬい"
    ]

    static func displayTags(for item: GoodsItem, goodsTypes: [GoodsType], limit: Int = 2) -> [String] {
        let goodsTypeNames = Set(goodsTypes.map { comparable($0.name) } + fallbackGoodsTypeNames.map(comparable))

        return item.tags.reduce(into: [String]()) { result, tag in
            guard result.count < limit else {
                return
            }
            guard let normalized = normalizedTagName(tag.name) else {
                return
            }
            guard !goodsTypeNames.contains(comparable(normalized)) else {
                return
            }
            let formatted = formattedTag(normalized)
            if !result.contains(where: { comparable($0) == comparable(formatted) }) {
                result.append(formatted)
            }
        }
    }

    private static func formattedTag(_ value: String) -> String {
        value.hasPrefix("#") ? value : "#\(value)"
    }

    private static func normalizedTagName(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutHash = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        let normalized = withoutHash.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    private static func comparable(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .lowercased()
    }
}

enum HomeDiscoveryCandidateFactory {
    static func candidates(
        from items: [GoodsItem],
        source: HomeDiscoveryCandidateSource,
        goodsTypes: [GoodsType] = [],
        conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals]
    ) -> [HomeDiscoveryCandidate] {
        items.enumerated().map { index, item in
            let signals = conditionSignalsByItemID[item.id] ?? fallbackSignals(for: source, index: index)
            let goods = goodsStack(for: item, in: items, index: index, goodsTypes: goodsTypes)
            return HomeDiscoveryCandidate(
                id: item.id,
                title: title(for: item, source: source, goodsTypes: goodsTypes),
                signals: signals,
                sheet: sheet(for: source, signals: signals, selectedGoods: goods.first),
                goods: goods
            )
        }
    }

    private static func fallbackSignals(
        for source: HomeDiscoveryCandidateSource,
        index: Int
    ) -> HomeCandidateConditionSignals {
        switch source {
        case .userTag:
            return HomeCandidateConditionSignalDefaults.matched(index: index)
        case .user, .haves:
            return HomeCandidateConditionSignalDefaults.possible(index: index)
        }
    }

    private static func sheet(
        for source: HomeDiscoveryCandidateSource,
        signals: HomeCandidateConditionSignals,
        selectedGoods: HomeMockGoods?
    ) -> HomeDiscoverySheet {
        guard source != .haves else {
            return .havesLookup
        }
        let fallbackGoods = selectedGoods ?? HomeDiscoveryFixtures.selectedYellow
        return HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods) == .direct ? .goodsHit(fallbackGoods) : .wishHit(fallbackGoods)
    }

    private static func title(for item: GoodsItem, source: HomeDiscoveryCandidateSource, goodsTypes: [GoodsType]) -> String {
        switch source {
        case .userTag:
            return memberTagTitle(from: item, goodsTypes: goodsTypes)
        case .haves:
            return item.title
        case .user:
            return item.title.components(separatedBy: .whitespacesAndNewlines).first(where: { !$0.isEmpty }) ?? item.title
        }
    }

    private static func memberTagTitle(from item: GoodsItem, goodsTypes: [GoodsType]) -> String {
        let memberName = memberName(from: item.title)
        if let tag = HomeDiscoveryTagFormatter.displayTags(for: item, goodsTypes: goodsTypes, limit: 1).first {
            return "\(memberName)×\(tag)"
        }
        return memberTagTitle(from: item.title)
    }

    private static func memberTagTitle(from title: String) -> String {
        if title.contains("×") {
            return title
        }
        let parts = title.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count == 2 else {
            return title
        }
        return "\(parts[0])×\(parts[1])"
    }

    private static func memberName(from title: String) -> String {
        if title.contains("×"),
           let left = title.split(separator: "×", maxSplits: 1, omittingEmptySubsequences: true).first {
            return String(left).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return title
            .split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            .first
            .map(String.init) ?? title
    }

    private static func goodsStack(
        for item: GoodsItem,
        in items: [GoodsItem],
        index: Int,
        goodsTypes: [GoodsType]
    ) -> [HomeMockGoods] {
        var stack = [HomeMockGoods.from(item: item, index: index, goodsTypes: goodsTypes)]
        let neighbors = items
            .filter { $0.id != item.id }
            .prefix(2)
            .enumerated()
            .map { offset, neighbor in
                HomeMockGoods.from(item: neighbor, index: index + offset + 1, goodsTypes: goodsTypes)
            }
        stack.append(contentsOf: neighbors)

        let fallback = [
            HomeDiscoveryFixtures.sanaBadge,
            HomeDiscoveryFixtures.sanaStand,
            HomeDiscoveryFixtures.sanaKeychain
        ]
        for goods in fallback where stack.count < 3 {
            stack.append(goods)
        }
        return stack
    }
}

enum HomeDiscoveryFixtures {
    private static func imageURL(_ name: String, fileExtension ext: String = "png") -> URL? {
        Bundle.module.url(
            forResource: name,
            withExtension: ext,
            subdirectory: "TestGoodsImages"
        ) ?? Bundle.module.url(forResource: name, withExtension: ext)
    }

    static func signals(
        listingHit: Bool,
        wishHit: Bool,
        postal: Bool,
        local: Bool,
        prefecture: Bool,
        date: Bool,
        wishCount: Int = 0,
        listingCount: Int = 0
    ) -> HomeCandidateConditionSignals {
        HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(
                hasIndividualListingHit: listingHit,
                hasWishHit: wishHit
            ),
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: postal,
                localExchangeSelected: local,
                prefectureMatches: prefecture,
                dateMatches: date
            ),
            linkCounts: HomeCandidateLinkCounts(
                wishCount: wishCount,
                listingCount: listingCount
            )
        )
    }

    static let selectedYellow = HomeMockGoods.make(
        "000000000901",
        title: "サナ",
        subtitle: "2026 LIVE",
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
        shape: .portrait,
        palette: [
            Color(red: 0.92, green: 0.70, blue: 0.58),
            MegrumTheme.pink.opacity(0.68),
            MegrumTheme.lavender.opacity(0.36)
        ],
        symbol: "M",
        imageURL: imageURL("twice_momo_1")
    )

    static let sanaBadge = HomeMockGoods.make(
        "000000000904",
        title: "サナ",
        subtitle: "缶バッジ",
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
        shape: .plush,
        palette: [
            MegrumTheme.lavender.opacity(0.46),
            Color.white.opacity(0.82),
            MegrumTheme.sky.opacity(0.28)
        ],
        symbol: "♡",
        imageURL: imageURL("bts_v")
    )

    static let userTagCandidates: [HomeDiscoveryCandidate] = [
        HomeDiscoveryCandidate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000911")!,
            title: "サナ×#2026 LIVE",
            signals: signals(listingHit: true, wishHit: true, postal: false, local: true, prefecture: true, date: true),
            sheet: .goodsHit(selectedYellow),
            goods: [selectedYellow, sanaBadge, sanaStand]
        ),
        HomeDiscoveryCandidate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000912")!,
            title: "モモ×#ファンミ",
            signals: signals(listingHit: false, wishHit: true, postal: false, local: true, prefecture: false, date: false),
            sheet: .wishHit(momoFanmi),
            goods: [momoFanmi, sanaLavender, sanaKeychain]
        )
    ]

    static let userCandidates: [HomeDiscoveryCandidate] = [
        HomeDiscoveryCandidate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000913")!,
            title: "サナ",
            signals: signals(listingHit: false, wishHit: true, postal: false, local: true, prefecture: true, date: false),
            sheet: .wishHit(sanaLavender),
            goods: [sanaLavender, sanaBadge, sanaKeychain]
        ),
        HomeDiscoveryCandidate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000914")!,
            title: "モモ",
            signals: signals(listingHit: false, wishHit: false, postal: false, local: false, prefecture: false, date: false),
            sheet: .wishHit(momoFanmi),
            goods: [momoFanmi, plush, sanaStand]
        )
    ]

    static let havesCandidates: [HomeDiscoveryCandidate] = [
        HomeDiscoveryCandidate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000915")!,
            title: "サナ",
            signals: signals(
                listingHit: true,
                wishHit: true,
                postal: true,
                local: false,
                prefecture: false,
                date: false,
                wishCount: 8,
                listingCount: 3
            ),
            sheet: .havesLookup,
            goods: [sanaLavender, sanaBadge, sanaStand]
        ),
        HomeDiscoveryCandidate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000916")!,
            title: "ぬい",
            signals: signals(
                listingHit: false,
                wishHit: true,
                postal: false,
                local: true,
                prefecture: true,
                date: false,
                wishCount: 5,
                listingCount: 0
            ),
            sheet: .havesLookup,
            goods: [plush, sanaKeychain, sanaBadge]
        ),
        HomeDiscoveryCandidate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000917")!,
            title: "缶バッジ",
            signals: signals(
                listingHit: true,
                wishHit: true,
                postal: false,
                local: true,
                prefecture: false,
                date: true,
                wishCount: 4,
                listingCount: 2
            ),
            sheet: .havesLookup,
            goods: [sanaBadge, sanaLavender, momoFanmi]
        ),
        HomeDiscoveryCandidate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000918")!,
            title: "アクスタ",
            signals: signals(
                listingHit: false,
                wishHit: true,
                postal: false,
                local: true,
                prefecture: true,
                date: true,
                wishCount: 3,
                listingCount: 1
            ),
            sheet: .havesLookup,
            goods: [sanaStand, selectedYellow, sanaKeychain]
        )
    ]

    static let wantedGoods = [sanaBadge, sanaLavender, sanaStand]
    static let offerGoods = [sanaLavender, sanaBadge, sanaKeychain, momoFanmi]
    static let otherListingHit = [momoFanmi, plush, sanaKeychain, sanaLavender]
    static let otherWishHit = [sanaBadge, selectedYellow, sanaStand, plush]
}
