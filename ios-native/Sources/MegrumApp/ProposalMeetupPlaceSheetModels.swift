import Foundation
import MapKit

struct ProposalMeetupPlaceSheetRoute: Identifiable, Equatable {
    let presentationID = UUID()
    var index: Int
    var draft: ProposalMeetupCandidateDraft

    var id: String {
        "\(index)-\(draft.id.uuidString)-\(presentationID.uuidString)"
    }
}

struct ProposalMeetupPlaceSearchResult: Identifiable {
    let id = UUID()
    var title: String
    var subtitle: String
    var coordinate: CLLocationCoordinate2D
}

enum ProposalMeetupPlaceFormatter {
    static func placeAreaText(for placemark: MKPlacemark) -> String {
        let rawParts = [
            placemark.administrativeArea,
            placemark.locality ?? placemark.subAdministrativeArea ?? placemark.subLocality
        ]
        var parts: [String] = []
        for rawPart in rawParts {
            let part = rawPart?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !part.isEmpty, !parts.contains(part) else {
                continue
            }
            parts.append(part)
        }
        if !parts.isEmpty {
            return parts.joined(separator: " ")
        }
        return placemark.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
