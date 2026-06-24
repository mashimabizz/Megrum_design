import Foundation
import MapKit

extension ProposalMeetupPlaceSheet {
    var selectedCoordinate: CLLocationCoordinate2D? {
        ProposalMeetupMapDraft.coordinate(
            latitudeText: draft.latitudeText,
            longitudeText: draft.longitudeText
        )?.clLocationCoordinate
    }

    var canSave: Bool {
        draft.meetupInput != nil
    }

    var trimmedSearchQuery: String {
        draft.placeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var locationStatusText: String {
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

    var coordinateCaption: String {
        guard let selectedCoordinate else {
            return "ピン未設定：地図をタップしてください"
        }
        return String(
            format: "ピン %.6f, %.6f",
            selectedCoordinate.latitude,
            selectedCoordinate.longitude
        )
    }
}
