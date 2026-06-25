import SwiftUI

struct ProposalMeetupPlaceActionRow: View {
    var isRequestingLocation: Bool
    var canApplyPreviousDraft: Bool
    var onUseCurrentLocation: () -> Void
    var onApplyPreviousDraft: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ProposalMeetupPlaceActionButton(
                title: "現在地を中心に",
                systemImage: "location.fill",
                isEnabled: true,
                showsProgress: isRequestingLocation,
                onTap: onUseCurrentLocation
            )

            ProposalMeetupPlaceActionButton(
                title: "前の設定と同じに",
                systemImage: "clock.arrow.circlepath",
                isEnabled: canApplyPreviousDraft,
                onTap: onApplyPreviousDraft
            )
        }
        .font(.system(size: 13, weight: .black, design: .rounded))
    }
}

struct ProposalMeetupPlaceSearchResultsList: View {
    var results: [ProposalMeetupPlaceSearchResult]
    var onSelect: (ProposalMeetupPlaceSearchResult) -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(results) { result in
                ProposalMeetupPlaceSearchResultButton(result: result) {
                    onSelect(result)
                }
            }
        }
        .padding(.top, 2)
    }
}
