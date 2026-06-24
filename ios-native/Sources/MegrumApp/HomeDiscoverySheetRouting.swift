import Foundation

enum HomeDiscoveryNestedPresentation: Identifiable {
    case discoverySheet(HomeDiscoverySheet)
    case publicProfile(PublicProfileRoute)

    var id: String {
        switch self {
        case .discoverySheet(let sheet):
            "sheet-\(sheet.id)"
        case .publicProfile(let route):
            "profile-\(route.id.uuidString)"
        }
    }
}

enum HomeDiscoveryOwnerProfilePresentationDecision: Equatable {
    case nested(PublicProfileRoute)
    case parent(UUID)
}

enum HomeDiscoveryOwnerProfileRoutingPolicy {
    static func decision(
        for userID: UUID,
        canPresentNestedProfile: Bool
    ) -> HomeDiscoveryOwnerProfilePresentationDecision {
        if canPresentNestedProfile {
            return .nested(PublicProfileRoute(userID: userID))
        }
        return .parent(userID)
    }
}

enum HomeDiscoveryDeferredPresentationPolicy {
    static let sheetDismissalDelayNanoseconds: UInt64 = 420_000_000
}
