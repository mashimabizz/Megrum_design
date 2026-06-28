import Foundation
import MegrumCore

struct MeguriFeedCacheKey: Equatable {
    var latitudeBucket: Int?
    var longitudeBucket: Int?
    var radiusMeters: Int
    var prefectureKey: String?
    var scope: BoardThread.Audience?

    init(
        latitude: Double?,
        longitude: Double?,
        radiusMeters: Int,
        prefecture: String? = nil,
        scope: BoardThread.Audience? = nil
    ) {
        self.latitudeBucket = Self.coordinateBucket(latitude)
        self.longitudeBucket = Self.coordinateBucket(longitude)
        self.radiusMeters = radiusMeters
        self.prefectureKey = prefecture?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .nilIfBlank
        self.scope = scope
    }

    private static func coordinateBucket(_ coordinate: Double?) -> Int? {
        coordinate.map { Int(($0 * 1_000).rounded()) }
    }
}
