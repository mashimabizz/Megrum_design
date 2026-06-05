import Foundation

enum VisualQAInitialScreen: String, Equatable {
    case home
    case drawerOpen = "drawer-open"
    case matchRelation = "match-relation"
    case matchRelationCandidates = "match-relation-candidates"
    case proposalGive = "proposal-give"
    case proposalReceive = "proposal-receive"
    case proposalMeetup = "proposal-meetup"
    case proposalMeetupMonth = "proposal-meetup-month"
    case proposalConfirm = "proposal-confirm"
    case proposalComplete = "proposal-complete"
    case proposalPending = "proposal-pending"
}

enum VisualQAPreviewMode {
    static let environmentKey = "MEGRUM_VISUAL_QA_PREVIEW_AUTH"
    static let initialScreenEnvironmentKey = "MEGRUM_VISUAL_QA_INITIAL_SCREEN"

    static func isEnabled(environment: [String: String]) -> Bool {
        switch environment[environmentKey]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes", "on":
            true
        default:
            false
        }
    }

    static func initialScreen(environment: [String: String]) -> VisualQAInitialScreen? {
        guard
            let rawValue = environment[initialScreenEnvironmentKey]?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
            !rawValue.isEmpty
        else {
            return nil
        }
        return VisualQAInitialScreen(rawValue: rawValue)
    }
}
