import Foundation
import MegrumCore

/// めぐり地図の密度（件数）RPC（iter1226.434）。
/// ズームアウト時に実データを読み込む前の「おおよその件数」表示に使う。
struct MeguriMapDensityPayload: Encodable, Sendable {
    var pMinLat: Double
    var pMinLng: Double
    var pMaxLat: Double
    var pMaxLng: Double
    var pCellDeg: Double
}

struct MeguriMapDensityRow: Decodable, Sendable {
    var cellLat: Double
    var cellLng: Double
    var groomCount: Int
    var threadCount: Int

    var cell: MeguriMapDensityCell {
        MeguriMapDensityCell(
            latitude: cellLat,
            longitude: cellLng,
            groomCount: groomCount,
            threadCount: threadCount
        )
    }
}

extension SupabaseGroomClient {
    public func loadMeguriMapDensity(
        minLatitude: Double,
        minLongitude: Double,
        maxLatitude: Double,
        maxLongitude: Double,
        cellDegrees: Double
    ) async throws -> [MeguriMapDensityCell] {
        let rows: [MeguriMapDensityRow] = try await client.rpcRows(
            function: "meguri_map_density",
            payload: MeguriMapDensityPayload(
                pMinLat: minLatitude,
                pMinLng: minLongitude,
                pMaxLat: maxLatitude,
                pMaxLng: maxLongitude,
                pCellDeg: cellDegrees
            )
        )
        return rows.map(\.cell)
    }
}
