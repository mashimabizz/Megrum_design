import Foundation
import MegrumCore

enum HomeExchangeSettingsStorageKeys {
    static let preference = "megrum.home.exchangeSettings.preference"
    static let requiresSamePrefecture = "megrum.home.exchangeSettings.requiresSamePrefecture"
    static let requiresDateOverlap = "megrum.home.exchangeSettings.requiresDateOverlap"
    static let localPrefecture = "megrum.home.exchangeSettings.localPrefecture"
    static let localDateKeys = "megrum.home.exchangeSettings.localDateKeys"
    static let localDateDetails = "megrum.home.exchangeSettings.localDateDetails"
    static let mailShippingFee = "megrum.home.exchangeSettings.mailShippingFee"
    static let mailShippingDays = "megrum.home.exchangeSettings.mailShippingDays"
    static let configuredAt = "megrum.home.exchangeSettings.configuredAt"
}

enum JapanesePrefectureCatalog {
    static let all = [
        "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県",
        "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県",
        "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県",
        "岐阜県", "静岡県", "愛知県", "三重県",
        "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県",
        "鳥取県", "島根県", "岡山県", "広島県", "山口県",
        "徳島県", "香川県", "愛媛県", "高知県",
        "福岡県", "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"
    ]
}

struct HomeExchangeDateKey: Equatable, Hashable, Sendable {
    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    static func date(from key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else {
            return nil
        }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    static func normalizedKeys(from rawValue: String) -> [String] {
        orderedUnique(
            rawValue
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
        .sorted()
    }

    static func rawValue(from keys: some Sequence<String>) -> String {
        orderedUnique(keys.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter { !$0.isEmpty }
            .sorted()
            .joined(separator: ",")
    }

    static func isOnOrAfterToday(_ key: String, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let date = date(from: key, calendar: calendar) else {
            return false
        }
        return calendar.startOfDay(for: date) >= calendar.startOfDay(for: now)
    }

    static func displayText(for key: String, calendar: Calendar = .current) -> String {
        guard let date = date(from: key, calendar: calendar) else {
            return key
        }
        return date.formatted(
            .dateTime
                .locale(Locale(identifier: "ja_JP"))
                .month()
                .day()
                .weekday(.abbreviated)
        )
    }

    static func compactDisplayText(for key: String, calendar: Calendar = .current) -> String {
        guard let date = date(from: key, calendar: calendar) else {
            return key
        }
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else {
            return key
        }
        return "\(month)/\(day)"
    }

    private static func orderedUnique(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for value in values where seen.insert(value).inserted {
            result.append(value)
        }
        return result
    }
}

enum HomeExchangePreference: String, CaseIterable, Identifiable, Sendable {
    case local
    case mail
    case both

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .local:
            "現地交換"
        case .mail:
            "郵送交換"
        case .both:
            "現地交換・郵送OK"
        }
    }

    var detailText: String {
        switch self {
        case .local:
            "会場や駅周辺など、直接会える相手を優先します。"
        case .mail:
            "発送で交換できる相手を優先します。"
        case .both:
            "現地と郵送のどちらかが合う相手を広く表示します。"
        }
    }

    var acceptsLocal: Bool {
        self == .local || self == .both
    }

    var acceptsMail: Bool {
        self == .mail || self == .both
    }
}

struct HomeDefaultExchangeSettings: Equatable, Sendable {
    var preference: HomeExchangePreference
    var requiresSamePrefecture: Bool
    var requiresDateOverlap: Bool
    var localPrefecture: String
    var localDateKeys: [String]
    var mailShippingFee: IndividualListingShippingFeeDraft
    var mailShippingDays: IndividualListingShippingDaysDraft

    static let standard = HomeDefaultExchangeSettings(
        preference: .both,
        requiresSamePrefecture: true,
        requiresDateOverlap: false,
        localPrefecture: "",
        localDateKeys: [],
        mailShippingFee: .negotiate,
        mailShippingDays: .twoToFourDays
    )

    init(
        preference: HomeExchangePreference = .both,
        requiresSamePrefecture: Bool = true,
        requiresDateOverlap: Bool = false,
        localPrefecture: String = "",
        localDateKeys: [String] = [],
        mailShippingFee: IndividualListingShippingFeeDraft = .negotiate,
        mailShippingDays: IndividualListingShippingDaysDraft = .twoToFourDays
    ) {
        self.preference = preference
        self.requiresSamePrefecture = requiresSamePrefecture
        self.requiresDateOverlap = requiresDateOverlap
        self.localPrefecture = localPrefecture.trimmingCharacters(in: .whitespacesAndNewlines)
        self.localDateKeys = HomeExchangeDateKey.normalizedKeys(from: HomeExchangeDateKey.rawValue(from: localDateKeys))
        self.mailShippingFee = mailShippingFee
        self.mailShippingDays = mailShippingDays
    }

    init(
        preferenceRawValue: String,
        requiresSamePrefecture _: Bool,
        requiresDateOverlap _: Bool,
        localPrefecture: String = "",
        localDateKeysRawValue: String = "",
        mailShippingFeeRawValue: String = IndividualListingShippingFeeDraft.negotiate.rawValue,
        mailShippingDaysRawValue: String = IndividualListingShippingDaysDraft.twoToFourDays.rawValue
    ) {
        self.init(
            preference: HomeExchangePreference(rawValue: preferenceRawValue) ?? Self.standard.preference,
            requiresSamePrefecture: Self.standard.requiresSamePrefecture,
            requiresDateOverlap: Self.standard.requiresDateOverlap,
            localPrefecture: localPrefecture,
            localDateKeys: HomeExchangeDateKey.normalizedKeys(from: localDateKeysRawValue),
            mailShippingFee: IndividualListingShippingFeeDraft(rawValue: mailShippingFeeRawValue) ?? Self.standard.mailShippingFee,
            mailShippingDays: IndividualListingShippingDaysDraft(rawValue: mailShippingDaysRawValue) ?? Self.standard.mailShippingDays
        )
    }

    var summaryText: String {
        let localParts = [
            localPrefecture.nilIfBlank,
            usableLocalDateKeys.isEmpty ? nil : "\(usableLocalDateKeys.count)日程"
        ].compactMap(\.self)
        let mailParts = preference.acceptsMail ? [
            "送料 \(mailShippingFee.title)",
            "発送 \(mailShippingDays.title)"
        ] : []
        let detailParts = (preference.acceptsLocal ? localParts : []) + mailParts

        guard !detailParts.isEmpty else {
            return preference.displayName
        }
        return "\(preference.displayName) / \(detailParts.joined(separator: "・"))"
    }

    var usableLocalDateKeys: [String] {
        localDateKeys.filter { HomeExchangeDateKey.isOnOrAfterToday($0) }
    }

    func needsConfiguration(isExplicitlyConfigured: Bool, now: Date = Date()) -> Bool {
        guard isExplicitlyConfigured else {
            return true
        }
        guard preference.acceptsLocal else {
            return false
        }
        let hasUsableDate = localDateKeys.contains {
            HomeExchangeDateKey.isOnOrAfterToday($0, now: now)
        }
        return localPrefecture.isBlank || !hasUsableDate
    }

    func applying(to signals: HomeCandidateConditionSignals) -> HomeCandidateConditionSignals {
        var updated = signals
        updated.exchange = applying(to: signals.exchange)
        return updated
    }

    func applying(to signals: HomeExchangeConditionSignals) -> HomeExchangeConditionSignals {
        let localSelected = preference.acceptsLocal && signals.localExchangeSelected
        let localPrefectureMatch = resolvedLocalPrefectureMatch(signals: signals, localSelected: localSelected)
        let localDateMatch = resolvedLocalDateMatch(signals: signals, localSelected: localSelected)
        let localPrefectureUnset = localSelected && localPrefecture.isBlank
        let localDateNeedsDiscussion = localSelected && !localDateMatch && signals.dateNeedsDiscussion
        let mailSelected = preference.acceptsMail && signals.postalAcceptedByBoth

        return HomeExchangeConditionSignals(
            postalAcceptedByBoth: mailSelected,
            localExchangeSelected: localSelected,
            prefectureMatches: localPrefectureMatch,
            dateMatches: localDateMatch,
            prefectureUnset: localPrefectureUnset,
            dateNeedsDiscussion: localDateNeedsDiscussion,
            shippingFeeNeedsDiscussion: mailSelected && (mailShippingFee != .owner || signals.shippingFeeNeedsDiscussion),
            viewerExchangeMethodTitle: preference.displayName,
            partnerExchangeMethodTitle: signals.partnerExchangeMethodTitle,
            viewerLocalConditionText: viewerLocalConditionText ?? signals.viewerLocalConditionText,
            partnerLocalConditionText: signals.partnerLocalConditionText,
            viewerShippingFeeTitle: mailSelected ? viewerMailConditionText : signals.viewerShippingFeeTitle,
            partnerShippingFeeTitle: signals.partnerShippingFeeTitle,
            localRouteAvailable: localSelected,
            localRoutePrefectureMatches: localPrefectureMatch,
            localRouteDateMatches: localDateMatch,
            localRoutePrefectureUnset: localPrefectureUnset,
            localRouteDateNeedsDiscussion: localDateNeedsDiscussion,
            partnerLocalPrefectures: signals.partnerLocalPrefectures,
            partnerLocalDateKeys: signals.partnerLocalDateKeys
        )
    }

    func applying(to signalsByItemID: [UUID: HomeCandidateConditionSignals]) -> [UUID: HomeCandidateConditionSignals] {
        signalsByItemID.mapValues(applying)
    }

    private var viewerLocalConditionText: String? {
        guard preference.acceptsLocal else {
            return nil
        }
        let dateText = usableLocalDateKeys
            .prefix(3)
            .map { HomeExchangeDateKey.displayText(for: $0) }
            .joined(separator: "、")
        let parts = [
            localPrefecture.nilIfBlank,
            dateText.nilIfBlank
        ].compactMap(\.self)
        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }

    var viewerMailConditionText: String {
        "送料 \(mailShippingFee.title) / 発送 \(mailShippingDays.title)"
    }

    private func resolvedLocalPrefectureMatch(
        signals: HomeExchangeConditionSignals,
        localSelected: Bool
    ) -> Bool {
        guard localSelected else {
            return false
        }
        guard let normalizedPrefecture = normalizedText(localPrefecture) else {
            return false
        }
        guard !signals.partnerLocalPrefectures.isEmpty else {
            return false
        }
        return signals.partnerLocalPrefectures.contains(normalizedPrefecture)
    }

    private func resolvedLocalDateMatch(
        signals: HomeExchangeConditionSignals,
        localSelected: Bool
    ) -> Bool {
        guard localSelected else {
            return false
        }
        let selectedDateKeys = Set(usableLocalDateKeys)
        guard !selectedDateKeys.isEmpty else {
            return requiresDateOverlap ? signals.dateMatches : false
        }
        guard !signals.partnerLocalDateKeys.isEmpty else {
            return false
        }
        return !selectedDateKeys.isDisjoint(with: signals.partnerLocalDateKeys)
    }

    private func normalizedText(_ value: String) -> String? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? nil : normalized
    }
}
