import MapKit
import SwiftUI

struct ProposalMeetupPlaceSheetContent: View {
    var isRequestingLocation: Bool
    var canApplyPreviousDraft: Bool
    @Binding var placeName: String
    @FocusState.Binding var isPlaceFocused: Bool
    var searchResults: [ProposalMeetupPlaceSearchResult]
    var isSearchingPlace: Bool
    @Binding var cameraPosition: MapCameraPosition
    var selectedCoordinate: CLLocationCoordinate2D?
    var markerTitle: String
    var coordinateCaption: String
    var canSave: Bool
    var locationStatusText: String
    var onUseCurrentLocation: () -> Void
    var onApplyPreviousDraft: () -> Void
    var onSearch: () -> Void
    var onSelectSearchResult: (ProposalMeetupPlaceSearchResult) -> Void
    var onSelectCoordinate: (CLLocationCoordinate2D) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProposalMeetupPlaceActionRow(
                isRequestingLocation: isRequestingLocation,
                canApplyPreviousDraft: canApplyPreviousDraft,
                onUseCurrentLocation: onUseCurrentLocation,
                onApplyPreviousDraft: onApplyPreviousDraft
            )

            ProposalMeetupPlaceInputCard(
                placeName: $placeName,
                isPlaceFocused: $isPlaceFocused,
                searchResults: searchResults,
                isSearchingPlace: isSearchingPlace,
                onSearch: onSearch,
                onSelectSearchResult: onSelectSearchResult
            )

            ProposalMeetupPlaceMapCard(
                cameraPosition: $cameraPosition,
                selectedCoordinate: selectedCoordinate,
                markerTitle: markerTitle,
                coordinateCaption: coordinateCaption,
                onSelectCoordinate: onSelectCoordinate
            )

            ProposalMeetupPlaceStatusRow(canSave: canSave, message: locationStatusText)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 104)
    }
}
