import Foundation

struct HomePartnerExchangeCalendarPresentationState: Equatable {
    var visibleMonth: Date
    var selectedDateKey: String?

    init(context: HomePartnerExchangeCalendarContext) {
        visibleMonth = context.initialVisibleMonth
        selectedDateKey = context.initialDateKey
    }

    func selectedDetail(in context: HomePartnerExchangeCalendarContext) -> HomeExchangeLocalDateDetail? {
        selectedDateKey.flatMap { context.dateDetails[$0] }
    }
}
