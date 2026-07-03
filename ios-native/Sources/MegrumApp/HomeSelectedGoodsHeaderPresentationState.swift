struct HomeSelectedGoodsHeaderPresentationState: Equatable {
    var presentedListingDetail: HomeIndividualListingDetailContext?
    var presentedExchangeCalendar: HomePartnerExchangeCalendarContext?

    mutating func presentListingDetail(_ detail: HomeIndividualListingDetailContext) {
        presentedListingDetail = detail
    }

    mutating func dismissListingDetail() {
        presentedListingDetail = nil
    }

    mutating func presentExchangeCalendar(_ context: HomePartnerExchangeCalendarContext) {
        presentedExchangeCalendar = context
    }

    mutating func dismissExchangeCalendar() {
        presentedExchangeCalendar = nil
    }
}
