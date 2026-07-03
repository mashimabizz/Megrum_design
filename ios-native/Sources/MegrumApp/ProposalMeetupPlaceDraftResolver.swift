import MegrumCore

enum ProposalMeetupPlaceDraftResolver {
    static func previousReusableDraft(
        before index: Int,
        in drafts: [ProposalMeetupCandidateDraft]
    ) -> ProposalMeetupCandidateDraft? {
        drafts.indices
            .filter { $0 != index }
            .reversed()
            .map { drafts[$0] }
            .first(where: isReusablePlaceDraft)
    }

    private static func isReusablePlaceDraft(_ draft: ProposalMeetupCandidateDraft) -> Bool {
        !draft.normalizedPlaceName.isEmpty
            || ProposalMeetupMapDraft.coordinate(
                latitudeText: draft.latitudeText,
                longitudeText: draft.longitudeText
            ) != nil
    }
}

enum ProposalMeetupCurrentLocationDraftResolver {
    static func resolvedDraft(
        currentDraft: ProposalMeetupCandidateDraft,
        coordinate: MegrumLocationCoordinate?,
        requiresMeetupBeforeSubmit: Bool
    ) -> ProposalMeetupCandidateDraft? {
        guard requiresMeetupBeforeSubmit, let coordinate else {
            return nil
        }
        return currentDraft.applyingCurrentLocation(coordinate)
    }
}
