import Foundation
import MegrumCore

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

extension HomeDefaultExchangeSettings {
    func makeListingExchangeSummary(now: Date = Date.now) -> IndividualListingExchangeSummary {
        IndividualListingExchangeSummary(
            handoffMethod: preference.listingHandoffDraft,
            localPrefecture: localPrefecture.nilIfBlank ?? IndividualListingExchangeSummary.defaultLocalPrefecture,
            localPlaceMemo: "",
            localSchedule: listingLocalScheduleText(now: now),
            shippingFee: mailShippingFee,
            shippingDays: mailShippingDays,
            acceptsOutsideCondition: true
        )
    }

    private func listingLocalScheduleText(now: Date) -> String {
        let dateText = localDateKeys
            .filter { HomeExchangeDateKey.isOnOrAfterToday($0, now: now) }
            .prefix(3)
            .map { HomeExchangeDateKey.compactDisplayText(for: $0) }
            .joined(separator: "、")
        return dateText.nilIfBlank ?? IndividualListingExchangeSummary.defaultLocalSchedule
    }
}
