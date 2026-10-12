import Foundation
import MegrumCore

extension ProposalCreateFlow {
    var draftExchangeSummary: IndividualListingExchangeSummary {
        IndividualListingExchangeSummary(
            handoffMethod: exchangeMethod.listingHandoffDraft,
            localPrefecture: currentMeetupPrefecture,
            localPlaceMemo: meetupPlaceMemo,
            localSchedule: ProposalCreateDisplayTextFormatter.dateText(meetupStartAt),
            shippingFee: shippingFee,
            shippingDays: shippingDays,
            acceptsOutsideCondition: true
        )
    }

    var defaultExchangeSettings: HomeDefaultExchangeSettings {
        HomeDefaultExchangeSettings(
            preferenceRawValue: exchangePreferenceRawValue,
            requiresSamePrefecture: exchangeRequiresSamePrefecture,
            requiresDateOverlap: exchangeRequiresDateOverlap,
            localPrefecture: exchangeLocalPrefecture,
            localDateKeysRawValue: exchangeLocalDateKeysRawValue,
            mailShippingFeeRawValue: exchangeMailShippingFeeRawValue,
            mailShippingDaysRawValue: exchangeMailShippingDaysRawValue
        )
    }

    var defaultExchangeSummary: IndividualListingExchangeSummary {
        defaultExchangeSettings.makeListingExchangeSummary()
    }

    var viewerListingExchangeSummary: IndividualListingExchangeSummary? {
        let selectedOrInitialSenderIDs = selectedSenderGoodsIDs.union(Set(initialSenderGoodsIDs))
        if let listingID,
           let listing = appState.listings.first(where: { $0.id == listingID }) {
            return IndividualListingExchangeSummary.extract(from: listing.note).summary
        }
        guard !selectedOrInitialSenderIDs.isEmpty else {
            return nil
        }
        return appState.listings
            .filter { $0.status == .active }
            .first { listing in
                listing.haves.contains { selectedOrInitialSenderIDs.contains($0.itemID) }
            }
            .flatMap { IndividualListingExchangeSummary.extract(from: $0.note).summary }
    }

    var partnerExchangeSummary: IndividualListingExchangeSummary? {
        let partnerListings = appState.publicListingsByUserID[targetItem.ownerID] ?? []
        if let listingID,
           let listing = partnerListings.first(where: { $0.id == listingID }) {
            return IndividualListingExchangeSummary.extract(from: listing.note).summary
        }
        let receiverIDs = Set((receiverGoodsIDs ?? []) + [targetItem.id])
        return partnerListings
            .filter { $0.status == .active }
            .first { listing in
                listing.haves.contains { receiverIDs.contains($0.itemID) }
            }
            .flatMap { IndividualListingExchangeSummary.extract(from: $0.note).summary }
    }

    var viewerListingForConditionDisplay: IndividualListing? {
        let selectedOrInitialSenderIDs = selectedSenderGoodsIDs.union(Set(initialSenderGoodsIDs))
        if let listingID,
           let listing = appState.listings.first(where: { $0.id == listingID }) {
            return listing
        }
        guard !selectedOrInitialSenderIDs.isEmpty else {
            return nil
        }
        return appState.listings
            .filter { $0.status == .active }
            .first { listing in
                listing.haves.contains { selectedOrInitialSenderIDs.contains($0.itemID) }
            }
    }

    var partnerListingForConditionDisplay: IndividualListing? {
        let partnerListings = appState.publicListingsByUserID[targetItem.ownerID] ?? []
        if let listingID,
           let listing = partnerListings.first(where: { $0.id == listingID }) {
            return listing
        }
        let receiverIDs = Set((receiverGoodsIDs ?? []) + [targetItem.id])
        return partnerListings
            .filter { $0.status == .active }
            .first { listing in
                listing.haves.contains { receiverIDs.contains($0.itemID) }
            }
    }

    // MARK: - 現地交換条件テキスト（自分・相手で共通ロジック）

    /// 指定ユーザーの現地交換の日付キー（当日以降・直近順）。AW＋デフォルト交換設定の両方から。
    func upcomingLocalDateKeys(userID: UUID?, settings: HomeDefaultExchangeSettings?) -> [String] {
        let awKeys: Set<String> = userID
            .flatMap { appState.partnerActivityWindowVenuesByUserID[$0] }
            .map { Set($0.keys) } ?? []
        let settingsKeys = Set(settings?.localDateKeys ?? [])
        return awKeys.union(settingsKeys)
            .filter { HomeExchangeDateKey.isOnOrAfterToday($0) }
            .compactMap { key -> (String, Date)? in
                guard let date = HomeExchangeDateKey.date(from: key) else { return nil }
                return (key, date)
            }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    /// 現地交換条件の表示テキスト（自分・相手で共通）。
    /// - 当日以降の直近日があれば「都道府県 / メモ / 7/21他」
    /// - 個別募集に現地条件（都道府県）があれば「都道府県 / メモ」
    /// - どちらも無ければデフォルト交換設定の都道府県「大阪府（デフォルト設定）」
    func localConditionText(
        settings: HomeDefaultExchangeSettings?,
        summary: IndividualListingExchangeSummary?,
        upcomingKeys: [String]
    ) -> String {
        if let nearestKey = upcomingKeys.first {
            let detail = settings?.localDateDetails[nearestKey]
            let prefecture = detail?.prefecture.nilIfBlank
                ?? settings?.localPrefecture.nilIfBlank
                ?? summary?.localPrefecture.nilIfBlank
            let memo = detail?.memo.nilIfBlank ?? summary?.localPlaceMemo.nilIfBlank
            let dateText = HomeExchangeDateKey.compactDisplayText(for: nearestKey)
                + (upcomingKeys.count > 1 ? "他" : "")
            var parts: [String] = []
            if let prefecture { parts.append(prefecture) }
            if let memo { parts.append(memo) }
            parts.append(dateText)
            return parts.joined(separator: " / ")
        }

        if let summary, summary.includesLocal, let prefecture = summary.localPrefecture.nilIfBlank {
            var parts = [prefecture]
            if let memo = summary.localPlaceMemo.nilIfBlank {
                parts.append(memo)
            }
            return parts.joined(separator: " / ")
        }

        if let defaultPrefecture = settings?.localPrefecture.nilIfBlank {
            return "\(defaultPrefecture)（デフォルト設定）"
        }

        return "未設定"
    }

    // MARK: 自分

    /// 自分（打診者）のデフォルト交換設定。map に無ければ自身の保存済み設定にフォールバック。
    var viewerExchangeSettings: HomeDefaultExchangeSettings? {
        if let id = appState.viewer?.id,
           let settings = appState.publicExchangeSettingsByUserID[id] {
            return settings
        }
        return appState.exchangeSettings
    }

    var viewerUpcomingLocalDateKeys: [String] {
        upcomingLocalDateKeys(userID: appState.viewer?.id, settings: viewerExchangeSettings)
    }

    var viewerLocalConditionText: String {
        localConditionText(
            settings: viewerExchangeSettings,
            summary: viewerListingExchangeSummary,
            upcomingKeys: viewerUpcomingLocalDateKeys
        )
    }

    /// 自分の「交換条件カレンダー」シート用コンテキスト（相手と同一モジュール）。
    var viewerExchangeCalendarContext: HomePartnerExchangeCalendarContext {
        PartnerExchangeCalendarContextBuilder.context(
            appState: appState,
            userID: appState.viewer?.id,
            listingLocalPrefecture: viewerListingExchangeSummary?.localPrefecture,
            listingLocalMemo: viewerListingExchangeSummary?.localPlaceMemo,
            conditionText: viewerLocalConditionText,
            displayName: "",
            headerTitle: "あなたの交換条件"
        )
    }

    // MARK: 相手

    /// 相手の現地交換の日付キー（当日以降・直近順）。AW＋デフォルト交換設定の両方から。
    var partnerUpcomingLocalDateKeys: [String] {
        upcomingLocalDateKeys(
            userID: targetItem.ownerID,
            settings: appState.publicExchangeSettingsByUserID[targetItem.ownerID]
        )
    }

    /// 相手の現地交換条件の表示テキスト。
    var partnerLocalConditionText: String {
        localConditionText(
            settings: appState.publicExchangeSettingsByUserID[targetItem.ownerID],
            summary: partnerExchangeSummary,
            upcomingKeys: partnerUpcomingLocalDateKeys
        )
    }

    var viewerShippingConditionText: String {
        viewerListingExchangeSummary?.mailDetailText ?? "未設定"
    }

    /// 相手の表示名（カレンダーのサブタイトル用）。名前が取れなければ handle → 「相手」。
    var partnerDisplayName: String {
        let profile = appState.publicProfilesByUserID[targetItem.ownerID]?.profile
        return profile?.displayName.nilIfBlank
            ?? profile?.handle.nilIfBlank
            ?? "相手"
    }

    /// 相手の「交換条件カレンダー」シート用コンテキスト（ホーム・プロフィールと同一モジュール）。
    var partnerExchangeCalendarContext: HomePartnerExchangeCalendarContext {
        PartnerExchangeCalendarContextBuilder.context(
            appState: appState,
            userID: targetItem.ownerID,
            listingLocalPrefecture: partnerExchangeSummary?.localPrefecture,
            listingLocalMemo: partnerExchangeSummary?.localPlaceMemo,
            conditionText: partnerLocalConditionText,
            displayName: partnerDisplayName
        )
    }

    var partnerShippingConditionText: String {
        partnerExchangeSummary?.mailDetailText ?? "未設定"
    }

    var proposalShippingSummaryText: String {
        draftExchangeSummary.mailDetailText ?? "未設定"
    }
}

private extension ExchangeMethod {
    var listingHandoffDraft: IndividualListingHandoffDraft {
        switch self {
        case .hand:
            .local
        case .mail:
            .mail
        case .both:
            .both
        }
    }
}
