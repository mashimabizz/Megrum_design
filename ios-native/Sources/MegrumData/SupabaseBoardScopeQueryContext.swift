import Foundation
import MegrumCore

struct BoardScopeQueryContext: Sendable {
    var latitude: Double?
    var longitude: Double?
    var prefecture: String?
    var rpcScope: BoardThread.Audience

    init(latitude: Double?, longitude: Double?, prefecture: String?, scope: BoardThread.Audience) {
        let trimmedPrefecture = SupabaseTextNormalizer.optional(prefecture)
        switch scope {
        case .nearby3km:
            self.latitude = latitude
            self.longitude = longitude
            self.prefecture = nil
            self.rpcScope = .nearby3km
        case .samePrefecture:
            self.latitude = nil
            self.longitude = nil
            self.prefecture = trimmedPrefecture
            self.rpcScope = .samePrefecture
        case .sameSpot, .global:
            self.latitude = latitude
            self.longitude = longitude
            self.prefecture = trimmedPrefecture
            self.rpcScope = scope == .sameSpot ? .nearby3km : .global
        }
    }
}
