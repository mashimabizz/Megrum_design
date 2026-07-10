import Foundation

/// めぐり地図のズームアウト時に表示する「おおよその件数」セル（iter1226.434）。
/// 実データを読み込む前に、セル中心座標とグルーム/チャットルームの件数だけを持つ。
public struct MeguriMapDensityCell: Equatable, Identifiable, Sendable {
    public var latitude: Double
    public var longitude: Double
    public var groomCount: Int
    public var threadCount: Int

    public init(latitude: Double, longitude: Double, groomCount: Int, threadCount: Int) {
        self.latitude = latitude
        self.longitude = longitude
        self.groomCount = groomCount
        self.threadCount = threadCount
    }

    public var id: String {
        "\(latitude):\(longitude)"
    }

    public var totalCount: Int {
        groomCount + threadCount
    }
}
