import Foundation
import MapKit
import SwiftUI

extension ProposalMeetupPlaceSheet {
    func useCurrentLocation() {
        if let currentCoordinate {
            applyCurrentLocation(currentCoordinate)
            return
        }
        isWaitingForCurrentLocation = true
        onRequestCurrentLocation()
    }

    func searchCurrentPlaceName() {
        Task {
            cancelPlaceSearch()
            await searchPlace(query: trimmedSearchQuery)
        }
    }

    func applyCurrentLocation(_ coordinate: MegrumLocationCoordinate) {
        clearPlaceSearchState()
        suppressNextPlaceSearch = true
        draft = draft.applyingCurrentLocation(coordinate)
        syncCamera(to: coordinate.clLocationCoordinate, animated: true)
    }

    func applyPreviousDraft() {
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
    func searchPlace(query rawQuery: String) async {
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

    func applySearchResult(_ result: ProposalMeetupPlaceSearchResult, clearsResults: Bool = true) {
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

    func applyMapSelection(_ coordinate: CLLocationCoordinate2D) {
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

    func syncCameraToSelectedCoordinate(animated: Bool) {
        guard let selectedCoordinate else {
            return
        }
        syncCamera(to: selectedCoordinate, animated: animated)
    }

    func syncCamera(to coordinate: CLLocationCoordinate2D, animated: Bool) {
        let region = MKCoordinateRegion(center: coordinate, span: Self.mapSpan)
        if animated {
            withAnimation(.smooth(duration: 0.18)) {
                cameraPosition = .region(region)
            }
        } else {
            cameraPosition = .region(region)
        }
    }

    func schedulePlaceSearch(for placeName: String) {
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

    func cancelPlaceSearch() {
        placeSearchTask?.cancel()
        placeSearchTask = nil
    }

    func clearPlaceSearchState() {
        cancelPlaceSearch()
        activeSearchQuery = nil
        isSearchingPlace = false
        searchResults = []
        placeSearchError = nil
    }
}
