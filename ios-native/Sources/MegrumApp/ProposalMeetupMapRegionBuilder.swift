import MapKit
import MegrumCore

enum ProposalMeetupMapRegionBuilder {
    static func region(for candidates: [ProposalMeetupInput]) -> MKCoordinateRegion? {
        guard !candidates.isEmpty else {
            return nil
        }

        if candidates.count == 1, let candidate = candidates.first {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: candidate.latitude, longitude: candidate.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
        }

        let latitudes = candidates.map(\.latitude)
        let longitudes = candidates.map(\.longitude)
        guard let minLatitude = latitudes.min(),
              let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(),
              let maxLongitude = longitudes.max()
        else {
            return nil
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.01, (maxLatitude - minLatitude) * 1.8),
            longitudeDelta: max(0.01, (maxLongitude - minLongitude) * 1.8)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
