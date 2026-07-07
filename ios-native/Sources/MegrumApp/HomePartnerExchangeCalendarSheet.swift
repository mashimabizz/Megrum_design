import Foundation
import MegrumDesign
import SwiftUI

struct HomePartnerExchangeCalendarContext: Identifiable, Equatable, Sendable {
    var ownerName: String?
    var methodTitle: String
    var dateDetails: [String: HomeExchangeLocalDateDetail]
    var fallbackPrefecture: String?
    var fallbackMemo: String?
    /// シート上部の大見出し。相手＝「相手の交換条件」、自分＝「あなたの交換条件」。
    var headerTitle: String = "相手の交換条件"

    var id: String {
        [
            headerTitle,
            ownerName ?? "",
            methodTitle,
            dateDetails.keys.sorted().joined(separator: ","),
            fallbackPrefecture ?? "",
            fallbackMemo ?? ""
        ].joined(separator: "|")
    }

    var dateKeys: Set<String> {
        Set(dateDetails.keys)
    }

    var initialDateKey: String? {
        sortedDateKeys(onlyFuture: true).first ?? sortedDateKeys(onlyFuture: false).first
    }

    var initialVisibleMonth: Date {
        guard let initialDateKey,
              let date = HomeExchangeDateKey.date(from: initialDateKey, calendar: Self.calendar)
        else {
            return HomePartnerExchangeCalendarMonthBuilder.monthStart(containing: Date(), calendar: Self.calendar)
        }
        return HomePartnerExchangeCalendarMonthBuilder.monthStart(containing: date, calendar: Self.calendar)
    }

    static func from(
        signals: HomeCandidateConditionSignals,
        ownerName: String?
    ) -> HomePartnerExchangeCalendarContext? {
        let exchange = signals.exchange
        let methodTitle = HomeDiscoveryOwnerExchangeSummary.fromCandidateSignals(signals)?.methodTitle
            ?? exchange.partnerExchangeMethodTitle
            ?? "交換条件"
        let parsed = HomePartnerExchangeCalendarTextParser.parse(exchange.partnerLocalConditionText)
        let dateKeys = Set(exchange.partnerLocalDateKeys)
            .union(HomePartnerExchangeCalendarTextParser.dateKeys(in: exchange.partnerLocalConditionText))
        let fallbackPrefecture = parsed.prefecture
            ?? exchange.partnerLocalPrefectures.sorted().first
        let fallbackMemo = parsed.memo

        guard exchange.localExchangeSelected
            || methodTitle.contains("現地")
            || !dateKeys.isEmpty
            || fallbackPrefecture?.nilIfBlank != nil
            || fallbackMemo?.nilIfBlank != nil
        else {
            return nil
        }

        return HomePartnerExchangeCalendarContext(
            ownerName: ownerName?.nilIfBlank,
            methodTitle: methodTitle,
            dateDetails: Dictionary(uniqueKeysWithValues: dateKeys.sorted().map { key in
                (
                    key,
                    HomeExchangeLocalDateDetail(
                        prefecture: fallbackPrefecture ?? "",
                        memo: fallbackMemo ?? ""
                    )
                )
            }),
            fallbackPrefecture: fallbackPrefecture?.nilIfBlank,
            fallbackMemo: fallbackMemo?.nilIfBlank
        )
    }

    func sortedDateKeys(onlyFuture: Bool) -> [String] {
        dateKeys
            .filter { !onlyFuture || HomeExchangeDateKey.isOnOrAfterToday($0, calendar: Self.calendar) }
            .compactMap { key -> (String, Date)? in
                guard let date = HomeExchangeDateKey.date(from: key, calendar: Self.calendar) else {
                    return nil
                }
                return (key, date)
            }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    private static var calendar: Calendar {
        HomePartnerExchangeCalendarMonthBuilder.calendar
    }
}

struct HomePartnerExchangeCalendarSheet: View {
    var context: HomePartnerExchangeCalendarContext

    @State private var presentationState: HomePartnerExchangeCalendarPresentationState

    init(context: HomePartnerExchangeCalendarContext) {
        self.context = context
        _presentationState = State(initialValue: HomePartnerExchangeCalendarPresentationState(context: context))
    }

    var body: some View {
        HomeSheetScaffold(bottomButton: nil) {
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(context.headerTitle)
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.trailing, 58)

                HomePartnerExchangeCalendarCard(
                    visibleMonth: $presentationState.visibleMonth,
                    selectedDateKey: $presentationState.selectedDateKey,
                    context: context
                )

                HomePartnerExchangeDateMemoCard(
                    dateKey: presentationState.selectedDateKey,
                    detail: selectedDetail,
                    fallbackPrefecture: context.fallbackPrefecture,
                    fallbackMemo: context.fallbackMemo
                )
            }
        }
    }

    private var subtitle: String {
        if let ownerName = context.ownerName {
            return "\(ownerName)さんの\(context.methodTitle)"
        }
        return context.methodTitle
    }

    private var selectedDetail: HomeExchangeLocalDateDetail? {
        presentationState.selectedDetail(in: context)
    }
}
