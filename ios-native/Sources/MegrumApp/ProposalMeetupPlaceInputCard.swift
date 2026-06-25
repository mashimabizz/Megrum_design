import MegrumDesign
import SwiftUI

struct ProposalMeetupPlaceInputCard: View {
    @Binding var placeName: String
    @FocusState.Binding var isPlaceFocused: Bool
    var searchResults: [ProposalMeetupPlaceSearchResult]
    var isSearchingPlace: Bool
    var onSearch: () -> Void
    var onSelectSearchResult: (ProposalMeetupPlaceSearchResult) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("場所名")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            ProposalMeetupPlaceInputRow(
                placeName: $placeName,
                isPlaceFocused: $isPlaceFocused,
                isSearchingPlace: isSearchingPlace,
                onSearch: onSearch
            )

            if !searchResults.isEmpty {
                ProposalMeetupPlaceSearchResultsList(
                    results: searchResults,
                    onSelect: onSelectSearchResult
                )
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
