import Foundation

struct PublicProfileRoute: Identifiable, Equatable {
    var userID: UUID
    var id: UUID { userID }
}

enum PublicProfilePresentationContext: Equatable, Sendable {
    case standalone
    case stackedFromHomeDiscoverySheet
    case tradeChat

    var allowsProposalActions: Bool {
        self == .standalone
    }

    var showsDismissToolbarButton: Bool {
        self != .tradeChat
    }
}
