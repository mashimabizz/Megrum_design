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

    @State private var draft: ProposalMeetupCandidateDraft
    @State private var cameraPosition: MapCameraPosition
    @State private var isWaitingForCurrentLocation = false
    @State private var searchResults: [ProposalMeetupPlaceSearchResult] = []
    @State private var isSearchingPlace = false
    @State private var placeSearchError: String?
    @State private var activeSearchQuery: String?
    @State private var placeSearchTask: Task<Void, Never>?
    @State private var suppressNextPlaceSearch = false
    @FocusState private var isPlaceFocused: Bool

    private static let fallbackCoordinate = CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125)
    private static let mapSpan = MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)

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

    private var selectedCoordinate: CLLocationCoordinate2D? {
        ProposalMeetupMapDraft.coordinate(
            latitudeText: draft.latitudeText,
            longitudeText: draft.longitudeText
        )?.clLocationCoordinate
    }

    private var canSave: Bool {
        draft.meetupInput != nil
    }

    private var trimmedSearchQuery: String {
        draft.placeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var locationStatusText: String {
        if let placeSearchError {
            return placeSearchError
        }
        if let locationErrorMessage {
            return locationErrorMessage
        }
        if !searchResults.isEmpty, selectedCoordinate == nil {
            return "候補を選ぶと地図にピンが立ちます。"
        }
        if selectedCoordinate == nil {
            return "場所名を検索するか、地図をタップしてピンを置くと保存できます。"
        }
        return "ピン位置を確認して「この場所にする」を押してください。"
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
        ProposalMeetupPlaceSaveButton(canSave: canSave) {
            var normalizedDraft = draft
            normalizedDraft.placeName = normalizedDraft.normalizedPlaceName
            onSave(normalizedDraft, route.index)
            dismiss()
        }
    }

    private var coordinateCaption: String {
        guard let selectedCoordinate else {
            return "ピン未設定：地図をタップしてください"
        }
        return String(
            format: "ピン %.6f, %.6f",
            selectedCoordinate.latitude,
            selectedCoordinate.longitude
        )
    }

    private func useCurrentLocation() {
        if let currentCoordinate {
            applyCurrentLocation(currentCoordinate)
            return
        }
        isWaitingForCurrentLocation = true
        onRequestCurrentLocation()
    }

    private func searchCurrentPlaceName() {
        Task {
            cancelPlaceSearch()
            await searchPlace(query: trimmedSearchQuery)
        }
    }

    private func applyCurrentLocation(_ coordinate: MegrumLocationCoordinate) {
        clearPlaceSearchState()
        suppressNextPlaceSearch = true
        draft = draft.applyingCurrentLocation(coordinate)
        syncCamera(to: coordinate.clLocationCoordinate, animated: true)
    }

    private func applyPreviousDraft() {
        guard let previousDraft else {
            return
        }
        clearPlaceSearchState()
        suppressNextPlaceSearch = true
        draft.placeName = previousDraft.placeName
        draft.latitudeText = previousDraft.latitudeText
        draft.longitudeText = previousDraft.longitudeText
        searchResults = []
        placeSearchError = nil
        syncCameraToSelectedCoordinate(animated: true)
    }

    @MainActor
    private func searchPlace(query rawQuery: String) async {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            placeSearchError = nil
            isSearchingPlace = false
            activeSearchQuery = nil
            return
        }
        activeSearchQuery = query
        isSearchingPlace = true
        placeSearchError = nil

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: selectedCoordinate ?? currentCoordinate?.clLocationCoordinate ?? Self.fallbackCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard activeSearchQuery == query, !Task.isCancelled else {
                return
            }
            let results = response.mapItems.prefix(3).compactMap { item -> ProposalMeetupPlaceSearchResult? in
                let coordinate = item.placemark.coordinate
                guard ProposalMeetupMapDraft.isValid(latitude: coordinate.latitude, longitude: coordinate.longitude) else {
                    return nil
                }
                let title = item.name?.trimmingCharacters(in: .whitespacesAndNewlines)
                    ?? item.placemark.name?.trimmingCharacters(in: .whitespacesAndNewlines)
                    ?? query
                let subtitle = ProposalMeetupPlaceFormatter.placeAreaText(for: item.placemark)
                return ProposalMeetupPlaceSearchResult(title: title, subtitle: subtitle, coordinate: coordinate)
            }
            searchResults = Array(results)
            if searchResults.isEmpty {
                placeSearchError = "場所が見つかりませんでした。別の名前で検索してください。"
            }
        } catch {
            guard activeSearchQuery == query, !Task.isCancelled else {
                return
            }
            placeSearchError = "場所検索に失敗しました。通信状況を確認してください。"
        }
        if activeSearchQuery == query {
            isSearchingPlace = false
            activeSearchQuery = nil
        }
    }

    private func applySearchResult(_ result: ProposalMeetupPlaceSearchResult, clearsResults: Bool = true) {
        clearPlaceSearchState()
        suppressNextPlaceSearch = true
        draft.placeName = result.title
        draft.latitudeText = ProposalMeetupMapDraft.coordinateText(result.coordinate.latitude)
        draft.longitudeText = ProposalMeetupMapDraft.coordinateText(result.coordinate.longitude)
        placeSearchError = nil
        isPlaceFocused = false
        if clearsResults {
            searchResults = []
        }
        syncCamera(to: result.coordinate, animated: true)
    }

    private func applyMapSelection(_ coordinate: CLLocationCoordinate2D) {
        guard ProposalMeetupMapDraft.isValid(latitude: coordinate.latitude, longitude: coordinate.longitude) else {
            return
        }
        clearPlaceSearchState()
        draft.latitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.latitude)
        draft.longitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.longitude)
        placeSearchError = nil
        let trimmedPlaceName = draft.normalizedPlaceName
        if trimmedPlaceName.isEmpty || trimmedPlaceName == "現在地" {
            suppressNextPlaceSearch = true
            draft.placeName = ProposalMeetupMapDraft.fallbackPlaceName
        }
        searchResults = []
        syncCamera(to: coordinate, animated: true)
    }

    private func syncCameraToSelectedCoordinate(animated: Bool) {
        guard let selectedCoordinate else {
            return
        }
        syncCamera(to: selectedCoordinate, animated: animated)
    }

    private func syncCamera(to coordinate: CLLocationCoordinate2D, animated: Bool) {
        let region = MKCoordinateRegion(center: coordinate, span: Self.mapSpan)
        if animated {
            withAnimation(.smooth(duration: 0.18)) {
                cameraPosition = .region(region)
            }
        } else {
            cameraPosition = .region(region)
        }
    }

    private func schedulePlaceSearch(for placeName: String) {
        if suppressNextPlaceSearch {
            suppressNextPlaceSearch = false
            return
        }
        cancelPlaceSearch()
        let query = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            placeSearchError = nil
            isSearchingPlace = false
            activeSearchQuery = nil
            return
        }
        placeSearchTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 260_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else {
                return
            }
            await searchPlace(query: query)
        }
    }

    private func cancelPlaceSearch() {
        placeSearchTask?.cancel()
        placeSearchTask = nil
    }

    private func clearPlaceSearchState() {
        cancelPlaceSearch()
        activeSearchQuery = nil
        isSearchingPlace = false
        searchResults = []
        placeSearchError = nil
    }
}
