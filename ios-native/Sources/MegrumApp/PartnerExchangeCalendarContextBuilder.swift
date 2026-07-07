import Foundation
import MegrumCore

/// 相手の「現地交換の条件」カレンダー（HomePartnerExchangeCalendarSheet）用コンテキストを
/// 相手のアクティビティウィンドウ・デフォルト交換設定・個別募集の現地条件から組み立てる。
/// 打診フローと相手プロフィールの両方から使う共通ビルダー（iter1226.358）。
enum PartnerExchangeCalendarContextBuilder {
    @MainActor
    static func context(
        appState: MegrumAppState,
        userID: UUID?,
        listingLocalPrefecture: String?,
        listingLocalMemo: String?,
        conditionText: String?,
        displayName: String,
        headerTitle: String = "相手の交換条件"
    ) -> HomePartnerExchangeCalendarContext {
        let dateVenues = userID.flatMap { appState.partnerActivityWindowVenuesByUserID[$0] } ?? [:]
        let settings = userID.flatMap { appState.publicExchangeSettingsByUserID[$0] }
        let parsed = HomePartnerExchangeCalendarTextParser.parse(conditionText)
        let fallbackPrefecture = listingLocalPrefecture?.nilIfBlank
            ?? settings?.localPrefecture.nilIfBlank
            ?? parsed.prefecture

        var dateDetails: [String: HomeExchangeLocalDateDetail] = [:]
        // 1) デフォルト交換設定の日付ごと詳細（都道府県・メモ）を優先。
        if let settings {
            for key in settings.localDateKeys {
                let detail = settings.localDateDetails[key]
                dateDetails[key] = HomeExchangeLocalDateDetail(
                    prefecture: detail?.prefecture.nilIfBlank ?? settings.localPrefecture.nilIfBlank ?? fallbackPrefecture ?? "",
                    memo: detail?.memo.nilIfBlank ?? listingLocalMemo?.nilIfBlank ?? ""
                )
            }
        }
        // 2) AW由来の日付（会場名つき）を補完。
        for (key, venue) in dateVenues where dateDetails[key] == nil {
            dateDetails[key] = HomeExchangeLocalDateDetail(
                prefecture: fallbackPrefecture ?? "",
                memo: venue.nilIfBlank ?? listingLocalMemo?.nilIfBlank ?? ""
            )
        }
        // 3) いずれも無ければ、現地条件テキストの日付解析でフォールバック。
        if dateDetails.isEmpty {
            let detail = HomeExchangeLocalDateDetail(
                prefecture: fallbackPrefecture ?? "",
                memo: listingLocalMemo?.nilIfBlank ?? parsed.memo ?? ""
            )
            for key in HomePartnerExchangeCalendarTextParser.dateKeys(in: conditionText) {
                dateDetails[key] = detail
            }
        }

        return HomePartnerExchangeCalendarContext(
            ownerName: displayName.nilIfBlank,
            methodTitle: "現地交換の条件",
            dateDetails: dateDetails,
            fallbackPrefecture: fallbackPrefecture,
            fallbackMemo: listingLocalMemo?.nilIfBlank ?? parsed.memo,
            headerTitle: headerTitle
        )
    }
}
