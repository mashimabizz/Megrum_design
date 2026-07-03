import Foundation

struct ProposalMeetupConditionDraft: Equatable {
    var prefecture: String
    var placeMemo: String?
    var startAt: Date?
    var endAt: Date?
}

enum ProposalMeetupConditionDraftResolver {
    static let defaultDuration: TimeInterval = 30 * 60

    static func resolvedDraft(
        viewerListingSummary: IndividualListingExchangeSummary?,
        defaultSummary: IndividualListingExchangeSummary,
        viewerPrefecture: String?,
        ownerPrefecture: String?
    ) -> ProposalMeetupConditionDraft? {
        if let viewerListingSummary, viewerListingSummary.includesLocal {
            return draft(from: viewerListingSummary)
        }
        if defaultSummary.includesLocal {
            return draft(from: defaultSummary)
        }
        if let viewerPrefecture = viewerPrefecture?.nilIfBlank {
            return ProposalMeetupConditionDraft(prefecture: viewerPrefecture)
        }
        if let ownerPrefecture = ownerPrefecture?.nilIfBlank {
            return ProposalMeetupConditionDraft(prefecture: ownerPrefecture)
        }
        return nil
    }

    private static func draft(from summary: IndividualListingExchangeSummary) -> ProposalMeetupConditionDraft {
        let startAt = ProposalScheduleTextDateParser.date(from: summary.localSchedule)
        return ProposalMeetupConditionDraft(
            prefecture: summary.localPrefecture,
            placeMemo: summary.localPlaceMemo,
            startAt: startAt,
            endAt: startAt?.addingTimeInterval(defaultDuration)
        )
    }
}
