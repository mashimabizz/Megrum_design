import Foundation
import MegrumCore

@MainActor
extension MegrumAppState {
    /// 相手（打診対象）のアクティビティウィンドウを読み込み、
    /// 現地交換カレンダー用に「日付キー→会場名」へ変換して保持する。
    public func loadPartnerActivityWindows(userID: UUID) async {
        guard let windows = try? await repository.loadUserActivityWindows(userID: userID) else {
            return
        }
        var dateVenues: [String: String] = [:]
        for window in windows {
            let keys = HomeCandidateExchangePolicy.localDateKeys(
                fromStartEndPairs: [(window.startAt, window.endAt)]
            )
            for key in keys where dateVenues[key] == nil {
                dateVenues[key] = window.venue
            }
        }
        partnerActivityWindowVenuesByUserID[userID] = dateVenues
    }
}
