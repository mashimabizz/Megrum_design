import Foundation
import MapKit
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalMeetupPlaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    var route: ProposalMeetupPlaceSheetRoute
    var previousDraft: ProposalMeetupCandidateDraft?
    var currentCoordinate: MegrumLocationCoordinate?
    var isRequestingLocation: Bool
    var locationErrorMessage: String?
    var onRequestCurrentLocation: () -> Void
    var onSave: (ProposalMeetupCandidateDraft, Int) -> Void

    @State var draft: ProposalMeetupCandidateDraft
    @State var cameraPosition: MapCameraPosition
    @State var isWaitingForCurrentLocation = false
    @State var searchResults: [ProposalMeetupPlaceSearchResult] = []
    @State var isSearchingPlace = false
    @State var placeSearchError: String?
    @State var activeSearchQuery: String?
    @State var placeSearchTask: Task<Void, Never>?
    @State var suppressNextPlaceSearch = false
    @FocusState var isPlaceFocused: Bool

    static let fallbackCoordinate = CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125)
    static let mapSpan = MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)

    init(
        route: ProposalMeetupPlaceSheetRoute,
        previousDraft: ProposalMeetupCandidateDraft?,
        currentCoordinate: MegrumLocationCoordinate?,
        isRequestingLocation: Bool,
        locationErrorMessage: String?,
        onRequestCurrentLocation: @escaping () -> Void,
        onSave: @escaping (ProposalMeetupCandidateDraft, Int) -> Void
    ) {
        let initialCoordinate = ProposalMeetupMapDraft.coordinate(
            latitudeText: route.draft.latitudeText,
            longitudeText: route.draft.longitudeText
        )?.clLocationCoordinate ?? currentCoordinate?.clLocationCoordinate ?? Self.fallbackCoordinate

        self.route = route
        self.previousDraft = previousDraft
        self.currentCoordinate = currentCoordinate
        self.isRequestingLocation = isRequestingLocation
        self.locationErrorMessage = locationErrorMessage
        self.onRequestCurrentLocation = onRequestCurrentLocation
        self.onSave = onSave
        _draft = State(initialValue: route.draft)
        _cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(center: initialCoordinate, span: Self.mapSpan)
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    actionRow
                    placeInputCard
                    mapCard
                    statusRow
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 104)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle("交換できる場所")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                saveButton
            }
        }
        .onAppear {
            isPlaceFocused = true
            syncCameraToSelectedCoordinate(animated: false)
        }
        .onDisappear {
            cancelPlaceSearch()
        }
        .onChange(of: draft.placeName) { _, placeName in
            schedulePlaceSearch(for: placeName)
        }
        .onChange(of: draft.latitudeText) { _, _ in
            syncCameraToSelectedCoordinate(animated: true)
        }
        .onChange(of: draft.longitudeText) { _, _ in
            syncCameraToSelectedCoordinate(animated: true)
        }
        .onChange(of: currentCoordinate) { _, coordinate in
            guard isWaitingForCurrentLocation, let coordinate else {
                return
            }
            isWaitingForCurrentLocation = false
            applyCurrentLocation(coordinate)
        }
    }

    private var actionRow: some View {
        ProposalMeetupPlaceActionRow(
            isRequestingLocation: isRequestingLocation,
            canApplyPreviousDraft: previousDraft != nil,
            onUseCurrentLocation: useCurrentLocation,
            onApplyPreviousDraft: applyPreviousDraft
        )
    }

    private var placeInputCard: some View {
        ProposalMeetupPlaceInputCard(
            placeName: $draft.placeName,
            isPlaceFocused: $isPlaceFocused,
            searchResults: searchResults,
            isSearchingPlace: isSearchingPlace,
            onSearch: searchCurrentPlaceName,
            onSelectSearchResult: { result in
                applySearchResult(result)
            }
        )
    }

    private var mapCard: some View {
        ProposalMeetupPlaceMapCard(
            cameraPosition: $cameraPosition,
            selectedCoordinate: selectedCoordinate,
            markerTitle: draft.normalizedPlaceName,
            coordinateCaption: coordinateCaption,
            onSelectCoordinate: applyMapSelection
        )
    }

    private var statusRow: some View {
        ProposalMeetupPlaceStatusRow(canSave: canSave, message: locationStatusText)
    }

    private var saveButton: some View {
        ProposalMeetupPlaceSaveButton(canSave: canSave, onSave: savePlace)
    }

    private func savePlace() {
        var normalizedDraft = draft
        normalizedDraft.placeName = normalizedDraft.normalizedPlaceName
        onSave(normalizedDraft, route.index)
        dismiss()
    }
}
