import MegrumCore
import MegrumDesign
import SwiftUI

enum HomeDiscoverySheet: Identifiable, Sendable {
    case goodsHit(HomeDiscoverySheetPayload)
    case wishHit(HomeDiscoverySheetPayload)
    case havesLookup(HomeHavesLookupPayload)
    case extraListingHit(HomeExtraHitPayload)
    case extraWishHit(HomeExtraHitPayload)

    var id: String {
        switch self {
        case .goodsHit(let payload):
            "goods-hit-\(payload.id.uuidString)"
        case .wishHit(let payload):
            "wish-hit-\(payload.id.uuidString)"
        case .havesLookup(let payload):
            "haves-lookup-\(payload.id.uuidString)"
        case .extraListingHit(let payload):
            "extra-listing-hit-\(payload.id)"
        case .extraWishHit(let payload):
            "extra-wish-hit-\(payload.id)"
        }
    }
}

struct HomeDiscoverySheetPayload: Identifiable, Equatable, Sendable {
    var goods: HomeMockGoods
    var signals: HomeCandidateConditionSignals
    var preferredOfferGoodsID: UUID?

    var id: UUID { goods.id }

    var conditionTags: HomeConditionTagSet {
        HomeConditionTagSet(signals: signals)
    }

    var individualListingSelection: HomeIndividualListingSelectionContext {
        signals.individualListingSelection ?? .defaultSelection
    }

    init(
        goods: HomeMockGoods,
        signals: HomeCandidateConditionSignals = HomeCandidateConditionSignalDefaults.noEvidence,
        preferredOfferGoodsID: UUID? = nil
    ) {
        self.goods = goods
        self.signals = signals
        self.preferredOfferGoodsID = preferredOfferGoodsID
    }
}

struct HomeHavesLookupPayload: Identifiable, Sendable {
    var offeredGoods: HomeMockGoods
    var offeredSignals: HomeCandidateConditionSignals
    var tagMatchedCandidates: [HomeDiscoveryCandidate]
    var memberMatchedCandidates: [HomeDiscoveryCandidate]

    var id: UUID { offeredGoods.id }

    var offeredConditionTags: HomeConditionTagSet {
        HomeConditionTagSet(signals: offeredSignals)
    }

    var shouldShowTagMatches: Bool {
        !offeredGoods.rawTagNames.isEmpty && !tagMatchedCandidates.isEmpty
    }

    var hasAnyMatches: Bool {
        shouldShowTagMatches || !memberMatchedCandidates.isEmpty
    }
}

enum HomeExtraHitKind: String, Equatable, Sendable {
    case listing
    case wish
}

struct HomeExtraHitPayload: Identifiable, Equatable, Sendable {
    var kind: HomeExtraHitKind
    var goods: HomeMockGoods
    var signals: HomeCandidateConditionSignals

    var id: String {
        "\(kind.rawValue)-\(goods.id.uuidString)"
    }

    var conditionTags: HomeConditionTagSet {
        HomeConditionTagSet(signals: signals)
    }

    var individualListingSelection: HomeIndividualListingSelectionContext {
        signals.individualListingSelection ?? .defaultSelection
    }

    var sheetPayload: HomeDiscoverySheetPayload {
        HomeDiscoverySheetPayload(goods: goods, signals: signals)
    }

    var nestedSheet: HomeDiscoverySheet {
        switch kind {
        case .listing:
            .extraListingHit(self)
        case .wish:
            .wishHit(sheetPayload)
        }
    }
}

struct HomeDiscoveryProposalSelection: Equatable, Sendable {
    var receiverGoodsID: UUID
    var senderGoodsIDs: [UUID]
    var matchType: ProposalMatchType
    var receiverGoods: HomeMockGoods?
    var senderGoods: [HomeMockGoods]
    var exchangeMethod: ExchangeMethod?
    var cashAmount: Int?

    init(
        receiverGoodsID: UUID,
        senderGoodsIDs: [UUID],
        matchType: ProposalMatchType,
        receiverGoods: HomeMockGoods? = nil,
        senderGoods: [HomeMockGoods] = [],
        exchangeMethod: ExchangeMethod? = nil,
        cashAmount: Int? = nil
    ) {
        self.receiverGoodsID = receiverGoodsID
        self.senderGoodsIDs = senderGoodsIDs
        self.matchType = matchType
        self.receiverGoods = receiverGoods
        self.senderGoods = senderGoods
        self.exchangeMethod = exchangeMethod
        self.cashAmount = cashAmount.map { max(0, $0) }
    }
}

struct HomeConditionTagSet: Equatable, Sendable {
    var goods: HomeGoodsCondition
    var exchange: HomeExchangeCondition
    var payment: HomePaymentCondition

    init(
        goods: HomeGoodsCondition,
        exchange: HomeExchangeCondition,
        payment: HomePaymentCondition
    ) {
        self.goods = goods
        self.exchange = exchange
        self.payment = payment
    }

    init(signals: HomeCandidateConditionSignals) {
        self.init(
            goods: HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods),
            exchange: HomeDiscoveryMatchPolicy.exchangeCondition(for: signals.exchange),
            payment: HomeDiscoveryMatchPolicy.paymentCondition(for: signals.payment)
        )
    }

    var accessibilityText: String {
        [
            goods.floatingTagTitle,
            exchange.floatingTagTitle,
            payment.floatingTagTitle
        ].joined(separator: "、")
    }
}

enum HomeGoodsCondition: String, Sendable {
    case direct = "◎"
    case wish = "○"
    case none = "▲"

    var tagTitle: String { "グッズ\(rawValue)" }
    var floatingTagTitle: String { "グッズ\(rawValue)" }
    var shortTitle: String { "条件\(rawValue)" }

    var accent: Color {
        switch self {
        case .direct:
            MegrumTheme.conditionExact
        case .wish:
            MegrumTheme.conditionPossible
        case .none:
            MegrumTheme.conditionWarning
        }
    }
}

enum HomeExchangeCondition: String, Sendable {
    case exact = "◎"
    case possible = "○"
    case warning = "▲"

    var tagTitle: String { "交換\(rawValue)" }
    var floatingTagTitle: String { "交換\(rawValue)" }

    var accent: Color {
        switch self {
        case .exact:
            MegrumTheme.conditionExact
        case .possible:
            MegrumTheme.conditionPossible
        case .warning:
            MegrumTheme.conditionWarning
        }
    }
}

enum HomePaymentCondition: String, Sendable {
    case compatible = "○"
    case warning = "▲"

    var tagTitle: String { "支払\(rawValue)" }
    var floatingTagTitle: String { "支払\(rawValue)" }

    var accent: Color {
        switch self {
        case .compatible:
            MegrumTheme.conditionPossible
        case .warning:
            MegrumTheme.conditionWarning
        }
    }
}

enum HomeMockGoodsShape: Sendable {
    case portrait
    case badge
    case stand
    case keychain
    case plush
}

struct HomeMockGoods: Identifiable, Equatable, Sendable {
    var id: UUID
    var ownerID: UUID?
    var groupID: UUID?
    var memberID: UUID?
    var title: String
    var subtitle: String
    var displayTags: [String]
    var rawTagNames: [String]
    var ownerPaymentMethods: [UserPaymentMethod]
    var ownerPaymentNote: String?
    var shape: HomeMockGoodsShape
    var palette: [Color]
    var symbol: String
    var imageURL: URL?

    static func make(
        _ uuidTail: String,
        title: String,
        subtitle: String,
        ownerID: UUID? = nil,
        groupID: UUID? = nil,
        memberID: UUID? = nil,
        displayTags: [String] = [],
        rawTagNames: [String] = [],
        ownerPaymentMethods: [UserPaymentMethod] = [.paypay, .other],
        ownerPaymentNote: String? = "差額相談可",
        shape: HomeMockGoodsShape,
        palette: [Color],
        symbol: String,
        imageURL: URL? = nil
    ) -> HomeMockGoods {
        guard let id = UUID(uuidString: "00000000-0000-0000-0000-\(uuidTail)") else {
            preconditionFailure("Invalid home mock goods UUID tail: \(uuidTail)")
        }

        return HomeMockGoods(
            id: id,
            ownerID: ownerID,
            groupID: groupID,
            memberID: memberID,
            title: title,
            subtitle: subtitle,
            displayTags: displayTags,
            rawTagNames: rawTagNames,
            ownerPaymentMethods: ownerPaymentMethods,
            ownerPaymentNote: ownerPaymentNote,
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
            ownerID: item.ownerID,
            groupID: item.groupID,
            memberID: item.memberID,
            title: item.title,
            subtitle: displayTags.first ?? item.ownerPrefecture ?? item.kind?.inventoryKind ?? "",
            displayTags: displayTags,
            rawTagNames: HomeDiscoveryTagFormatter.matchingTagNames(for: item, goodsTypes: goodsTypes),
            ownerPaymentMethods: item.ownerPaymentMethods,
            ownerPaymentNote: item.ownerPaymentNote,
            shape: shape,
            palette: palette,
            symbol: item.title.first.map(String.init) ?? "M",
            imageURL: item.imageURL
        )
    }

    var ownerPaymentSummaryText: String {
        UserPaymentMethod.displayText(
            for: ownerPaymentMethods,
            otherNote: ownerPaymentNote,
            emptyText: "支払い条件未設定"
        )
    }
}

struct HomeDiscoveryCandidate: Identifiable, Sendable {
    var id: UUID
    var title: String
    var signals: HomeCandidateConditionSignals
    var conditionSignalsByGoodsID: [UUID: HomeCandidateConditionSignals] = [:]
    var sheet: HomeDiscoverySheet
    var goods: [HomeMockGoods]

    var goodsCondition: HomeGoodsCondition {
        HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods)
    }

    var exchangeCondition: HomeExchangeCondition {
        HomeDiscoveryMatchPolicy.exchangeCondition(for: signals.exchange)
    }

    var paymentCondition: HomePaymentCondition {
        HomeDiscoveryMatchPolicy.paymentCondition(for: signals.payment)
    }

    var linkedCount: Int {
        signals.linkCounts.totalCount
    }

    var conditionTags: HomeConditionTagSet {
        HomeConditionTagSet(signals: signals)
    }

    func conditionSignals(for goods: HomeMockGoods?) -> HomeCandidateConditionSignals {
        guard let goods else {
            return signals
        }
        return conditionSignalsByGoodsID[goods.id] ?? signals
    }

    func conditionTags(for goods: HomeMockGoods?) -> HomeConditionTagSet {
        HomeConditionTagSet(signals: conditionSignals(for: goods))
    }

    func sheet(selectedGoods: HomeMockGoods? = nil) -> HomeDiscoverySheet {
        let goods = selectedGoods ?? goods.first
        let selectedSignals = conditionSignals(for: goods)
        let payload = HomeDiscoverySheetPayload(
            goods: goods ?? HomeDiscoveryFixtures.selectedYellow,
            signals: selectedSignals,
            preferredOfferGoodsID: preferredOfferGoodsID(from: sheet)
        )
        switch sheet {
        case .goodsHit, .wishHit:
            return HomeDiscoveryMatchPolicy.goodsCondition(for: selectedSignals.goods) == .direct
                ? .goodsHit(payload)
                : .wishHit(payload)
        case .havesLookup(_):
            return sheet
        case .extraListingHit, .extraWishHit:
            return sheet
        }
    }

    private func preferredOfferGoodsID(from sheet: HomeDiscoverySheet) -> UUID? {
        switch sheet {
        case .goodsHit(let payload), .wishHit(let payload):
            return payload.preferredOfferGoodsID
        case .havesLookup(let payload):
            return payload.offeredGoods.id
        case .extraListingHit, .extraWishHit:
            return nil
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

enum HomeDiscoveryCandidateSource: Sendable {
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

    static func matchingTagNames(for item: GoodsItem, goodsTypes: [GoodsType]) -> [String] {
        displayTags(for: item, goodsTypes: goodsTypes, limit: Int.max)
            .map(comparable)
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
        if source == .userTag {
            return memberTagCandidates(
                from: items,
                goodsTypes: goodsTypes,
                conditionSignalsByItemID: conditionSignalsByItemID
            )
        }

        return items.enumerated().map { index, item in
            candidate(
                from: item,
                in: items,
                source: source,
                index: index,
                goodsTypes: goodsTypes,
                conditionSignalsByItemID: conditionSignalsByItemID
            )
        }
    }

    private struct MemberTagGroupKey: Hashable {
        var member: String
        var tag: String
        var fallbackID: UUID?
    }

    private struct MemberTagDescriptor {
        var key: MemberTagGroupKey
        var title: String
    }

    private static func memberTagCandidates(
        from items: [GoodsItem],
        goodsTypes: [GoodsType],
        conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals]
    ) -> [HomeDiscoveryCandidate] {
        var groupedItems: [MemberTagGroupKey: [GoodsItem]] = [:]
        var groupTitles: [MemberTagGroupKey: String] = [:]
        var orderedKeys: [MemberTagGroupKey] = []

        for item in items {
            let descriptor = memberTagDescriptor(for: item, goodsTypes: goodsTypes)
            if groupedItems[descriptor.key] == nil {
                orderedKeys.append(descriptor.key)
                groupTitles[descriptor.key] = descriptor.title
            }
            groupedItems[descriptor.key, default: []].append(item)
        }

        return orderedKeys.enumerated().compactMap { index, key in
            guard let items = groupedItems[key],
                  let firstItem = items.first
            else {
                return nil
            }
            return candidate(
                from: firstItem,
                in: items,
                source: .userTag,
                index: index,
                goodsTypes: goodsTypes,
                conditionSignalsByItemID: conditionSignalsByItemID,
                titleOverride: groupTitles[key]
            )
        }
    }

    private static func candidate(
        from item: GoodsItem,
        in items: [GoodsItem],
        source: HomeDiscoveryCandidateSource,
        index: Int,
        goodsTypes: [GoodsType],
        conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals],
        titleOverride: String? = nil
    ) -> HomeDiscoveryCandidate {
        let signals = conditionSignalsByItemID[item.id] ?? fallbackSignals(for: source, index: index)
        let goods = goodsStack(for: item, in: items, source: source, index: index, goodsTypes: goodsTypes)
        return HomeDiscoveryCandidate(
            id: item.id,
            title: titleOverride ?? title(for: item, source: source, goodsTypes: goodsTypes),
            signals: signals,
            conditionSignalsByGoodsID: conditionSignalsByGoodsID(
                for: goods,
                selectedItemID: item.id,
                selectedSignals: signals,
                source: source,
                index: index,
                explicitSignals: conditionSignalsByItemID
            ),
            sheet: sheet(for: source, signals: signals, selectedGoods: goods.first),
            goods: goods
        )
    }

    private static func conditionSignalsByGoodsID(
        for goods: [HomeMockGoods],
        selectedItemID: UUID,
        selectedSignals: HomeCandidateConditionSignals,
        source: HomeDiscoveryCandidateSource,
        index: Int,
        explicitSignals: [UUID: HomeCandidateConditionSignals]
    ) -> [UUID: HomeCandidateConditionSignals] {
        Dictionary(
            uniqueKeysWithValues: goods.enumerated().map { offset, goods in
                (
                    goods.id,
                    explicitSignals[goods.id]
                        ?? (goods.id == selectedItemID
                            ? selectedSignals
                            : fallbackSignals(for: source, index: index + offset))
                )
            }
        )
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
            let offeredGoods = selectedGoods ?? HomeDiscoveryFixtures.selectedYellow
            return .havesLookup(
                HomeHavesLookupPayload(
                    offeredGoods: offeredGoods,
                    offeredSignals: signals,
                    tagMatchedCandidates: [],
                    memberMatchedCandidates: []
                )
            )
        }
        let fallbackGoods = selectedGoods ?? HomeDiscoveryFixtures.selectedYellow
        let payload = HomeDiscoverySheetPayload(goods: fallbackGoods, signals: signals)
        return HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods) == .direct ? .goodsHit(payload) : .wishHit(payload)
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
        let memberName = HomeDiscoveryTitleParser.memberName(from: item.title)
        if let tag = HomeDiscoveryTagFormatter.displayTags(for: item, goodsTypes: goodsTypes, limit: 1).first {
            return HomeDiscoveryTitleParser.joinedMemberTagTitle(member: memberName, tag: tag)
        }
        return HomeDiscoveryTitleParser.memberTagTitle(from: item.title)
    }

    private static func goodsStack(
        for item: GoodsItem,
        in items: [GoodsItem],
        source: HomeDiscoveryCandidateSource,
        index: Int,
        goodsTypes: [GoodsType]
    ) -> [HomeMockGoods] {
        if source == .userTag {
            return items.enumerated().map { offset, item in
                HomeMockGoods.from(item: item, index: index + offset, goodsTypes: goodsTypes)
            }
        }

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

    private static func memberTagDescriptor(for item: GoodsItem, goodsTypes: [GoodsType]) -> MemberTagDescriptor {
        let memberName = HomeDiscoveryTitleParser.memberName(from: item.title)
        let memberKey = item.memberID?.uuidString.lowercased()
            ?? HomeDiscoveryTitleParser.comparableMemberName(from: item.title)
        guard let tag = HomeDiscoveryTagFormatter.displayTags(for: item, goodsTypes: goodsTypes, limit: 1).first else {
            return MemberTagDescriptor(
                key: MemberTagGroupKey(member: memberKey, tag: "", fallbackID: item.id),
                title: HomeDiscoveryTitleParser.memberTagTitle(from: item.title)
            )
        }
        return MemberTagDescriptor(
            key: MemberTagGroupKey(member: memberKey, tag: comparableTagName(tag), fallbackID: nil),
            title: HomeDiscoveryTitleParser.joinedMemberTagTitle(member: memberName, tag: tag)
        )
    }

    private static func comparableTagName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .lowercased()
    }
}
