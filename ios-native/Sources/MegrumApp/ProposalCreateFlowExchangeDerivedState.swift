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

    var viewerLocalConditionText: String {
        viewerListingExchangeSummary?.localDetailTextForProposalDisplay ?? "未設定"
    }

    /// 相手の現地交換の日付キー（当日以降・直近順）。AW＋デフォルト交換設定の両方から。
    var partnerUpcomingLocalDateKeys: [String] {
        let settings = appState.publicExchangeSettingsByUserID[targetItem.ownerID]
        let awKeys = Set(appState.partnerActivityWindowVenuesByUserID[targetItem.ownerID]?.keys ?? [:].keys)
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

    /// 相手の現地交換条件の表示テキスト。
    /// - 当日以降の直近日があれば「都道府県 / メモ / 7/21他」
    /// - 個別募集に現地条件（都道府県）があれば「都道府県 / メモ」
    /// - どちらも無ければデフォルト交換設定の都道府県「大阪府（デフォルト設定）」
    var partnerLocalConditionText: String {
        let settings = appState.publicExchangeSettingsByUserID[targetItem.ownerID]
        let summary = partnerExchangeSummary
        let upcomingKeys = partnerUpcomingLocalDateKeys

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

    /// 相手の「交換条件カレンダー」シート用コンテキスト（ホームの相手交換条件と同一モジュール）。
    /// 日程は相手のアクティビティウィンドウ（現地交換可能日）から、都道府県は個別募集の
    /// 現地交換条件から取得する。
    var partnerExchangeCalendarContext: HomePartnerExchangeCalendarContext? {
        let dateVenues = appState.partnerActivityWindowVenuesByUserID[targetItem.ownerID] ?? [:]
        let parsed = HomePartnerExchangeCalendarTextParser.parse(partnerLocalConditionText)
        let listingPrefecture = partnerExchangeSummary?.localPrefecture.nilIfBlank
        let listingMemo = partnerExchangeSummary?.localPlaceMemo.nilIfBlank
        let fallbackPrefecture = listingPrefecture ?? parsed.prefecture

        var dateDetails: [String: HomeExchangeLocalDateDetail] = [:]
        // デフォルト交換設定に日付ごとの都道府県・メモがあれば優先的に採用。
        if let settings = appState.publicExchangeSettingsByUserID[targetItem.ownerID] {
            for key in settings.localDateKeys {
                let detail = settings.localDateDetails[key]
                dateDetails[key] = HomeExchangeLocalDateDetail(
                    prefecture: detail?.prefecture.nilIfBlank ?? settings.localPrefecture.nilIfBlank ?? fallbackPrefecture ?? "",
                    memo: detail?.memo.nilIfBlank ?? listingMemo ?? ""
                )
            }
        }
        // AW由来の日付（会場名つき）を補完。
        for (key, venue) in dateVenues where dateDetails[key] == nil {
            dateDetails[key] = HomeExchangeLocalDateDetail(
                prefecture: fallbackPrefecture ?? "",
                memo: venue.nilIfBlank ?? listingMemo ?? ""
            )
        }
        // AWが取れない場合は、相手の現地交換条件テキストの日付解析でフォールバック。
        if dateDetails.isEmpty {
            let detail = HomeExchangeLocalDateDetail(
                prefecture: fallbackPrefecture ?? "",
                memo: listingMemo ?? parsed.memo ?? ""
            )
            for key in HomePartnerExchangeCalendarTextParser.dateKeys(in: partnerLocalConditionText) {
                dateDetails[key] = detail
            }
        }
        guard !dateDetails.isEmpty || fallbackPrefecture != nil else {
            return nil
        }
        return HomePartnerExchangeCalendarContext(
            ownerName: partnerDisplayName,
            methodTitle: "現地交換の条件",
            dateDetails: dateDetails,
            fallbackPrefecture: fallbackPrefecture,
            fallbackMemo: listingMemo ?? parsed.memo
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
