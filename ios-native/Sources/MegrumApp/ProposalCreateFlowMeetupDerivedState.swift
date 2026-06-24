import Foundation
import MegrumCore

extension ProposalCreateFlow {
    var meetupInput: ProposalMeetupInput? {
        guard exchangeMethod == .hand || exchangeMethod == .both else {
            return nil
        }
        let input = ProposalMeetupInput(
            startAt: meetupStartAt,
            endAt: meetupEndAt,
            placeName: meetupDisplayPlaceName,
            latitude: meetupLatitude,
            longitude: meetupLongitude
        )
        return input.isValid ? input : nil
    }

    var meetupInputsForSubmission: [ProposalMeetupInput] {
        meetupInput.map { [$0] } ?? []
    }

    var selectedMeetupCandidateDraft: ProposalMeetupCandidateDraft {
        let candidateID = meetupCandidateDrafts.indices.contains(selectedMeetupCandidateIndex)
            ? meetupCandidateDrafts[selectedMeetupCandidateIndex].id
            : UUID()
        return ProposalMeetupCandidateDraft(
            id: candidateID,
            startAt: meetupStartAt,
            endAt: meetupEndAt,
            placeName: meetupPlaceName,
            latitudeText: meetupLatitudeText,
            longitudeText: meetupLongitudeText
        )
    }

    var displayMeetupCandidateDrafts: [ProposalMeetupCandidateDraft] {
        var drafts = meetupCandidateDrafts
        if drafts.indices.contains(selectedMeetupCandidateIndex) {
            drafts[selectedMeetupCandidateIndex] = selectedMeetupCandidateDraft
        }
        return drafts
    }

    var proposalScheduleContext: ProposalScheduleContext {
        let cachedSchedules = appState.schedulesByProposalID.values.reduce(into: [PersonalSchedule]()) { result, schedules in
            result.append(contentsOf: schedules)
        }
        return ProposalScheduleContext(
            schedules: cachedSchedules,
            viewerID: appState.viewer?.id,
            partnerID: targetItem.ownerID,
            selectedStartAt: meetupStartAt,
            selectedEndAt: meetupEndAt
        )
    }

    var meetupSummary: String {
        if let meetupInput {
            return "\(Self.dateText(meetupInput.startAt)) / \(meetupInput.normalizedPlaceName)"
        }
        return configuration.requiresMeetupBeforeSubmit ? "未設定" : "現地では会わない設定"
    }

    var currentMeetupPrefecture: String {
        meetupPrefecture.nilIfBlank
            ?? appState.viewer?.prefecture.nilIfBlank
            ?? targetItem.ownerPrefecture.nilIfBlank
            ?? "未設定"
    }

    var meetupDisplayPlaceName: String {
        [currentMeetupPrefecture.nilIfBlank, meetupPlaceMemo.nilIfBlank]
            .compactMap(\.self)
            .joined(separator: " / ")
    }

    var meetupLatitude: Double {
        Double(meetupLatitudeText) ?? locationState.coordinate?.latitude ?? 0
    }

    var meetupLongitude: Double {
        Double(meetupLongitudeText) ?? locationState.coordinate?.longitude ?? 0
    }

    var proposalMeetupSummaryText: String {
        draftExchangeSummary.localDetailTextForProposalDisplay ?? "未設定"
    }
}
