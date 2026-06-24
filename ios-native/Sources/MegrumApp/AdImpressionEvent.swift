import Foundation

struct AdImpressionEvent: Equatable, Sendable {
    var viewerID: UUID?
    var placement: AdPlacement
    var provider: AdProvider
    var unitID: String?
    var shownAt: Date

    var screenID: String {
        placement.screenID
    }

    var adType: String {
        placement.format.rawValue
    }
}
