import Foundation

enum IndividualListingNotePresentation {
    static func userMemo(from note: String?) -> String? {
        let withoutCashSummary = IndividualListingHaveCashSummary.extract(from: note).remainingNote
        let withoutExchangeSummary = IndividualListingExchangeSummary.extract(from: withoutCashSummary).remainingNote
        return withoutExchangeSummary?.nilIfBlank
    }
}
