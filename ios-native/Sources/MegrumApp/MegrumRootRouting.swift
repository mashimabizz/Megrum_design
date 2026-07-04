import Foundation
import MegrumCore

enum HomeSettingsRoute: Identifiable, Equatable {
    case exchange
    case payment

    var id: String {
        switch self {
        case .exchange:
            "exchange"
        case .payment:
            "payment"
        }
    }
}

public enum MegrumTab: String, CaseIterable, Identifiable, Sendable {
    case home
    case trades
    case meguri
    case inventory
    case wish

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            "ホーム"
        case .inventory:
            "マイグッズ"
        case .wish:
            "ほしいもの"
        case .trades:
            "やりとり"
        case .meguri:
            "めぐり"
        }
    }

    var symbolName: String {
        switch self {
        case .home:
            "house"
        case .inventory:
            "rectangle.on.rectangle"
        case .wish:
            "heart"
        case .trades:
            "message"
        case .meguri:
            "dot.radiowaves.left.and.right"
        }
    }
}

struct ProposalCompletionRouteState: Equatable {
    var selectedTab: MegrumTab
    var requestedTradesStage: TradeStage?
}

enum ProposalCompletionRouteResolver {
    static func resolve(action: ProposalCompletionAction) -> ProposalCompletionRouteState {
        switch action {
        case .searchMore:
            ProposalCompletionRouteState(selectedTab: .home, requestedTradesStage: nil)
        case .openTrades:
            ProposalCompletionRouteState(selectedTab: .trades, requestedTradesStage: .pending)
        }
    }
}

enum VisualQAProposalRouteResolver {
    static func shouldOpenProposalFlow(for screen: VisualQAInitialScreen?) -> Bool {
        initialStep(for: screen) != nil
    }

    static func shouldRenderDirectRoot(for screen: VisualQAInitialScreen?) -> Bool {
        shouldOpenProposalFlow(for: screen)
    }

    static func initialStep(for screen: VisualQAInitialScreen?) -> ProposalCreateStep? {
        switch screen {
        case .proposalGive:
            .give
        case .proposalReceive:
            .receive
        case .proposalMeetup, .proposalMeetupMonth:
            .meetup
        case .proposalConfirm, .proposalComplete:
            .confirm
        default:
            nil
        }
    }

    static func targetItem(candidates: [GoodsItem], viewerID: UUID?) -> GoodsItem? {
        VisualQATargetItemResolver.targetItem(candidates: candidates, viewerID: viewerID)
    }
}

enum VisualQARelationRouteResolver {
    static func shouldRenderDirectRoot(for screen: VisualQAInitialScreen?) -> Bool {
        switch screen {
        case .matchRelation, .matchRelationCandidates:
            true
        default:
            false
        }
    }
}

enum VisualQATargetItemResolver {
    static func targetItem(candidates: [GoodsItem], viewerID: UUID?) -> GoodsItem? {
        candidates.first { item in
            guard let viewerID else {
                return false
            }
            return item.ownerID != viewerID
        } ?? candidates.first
    }
}

enum VisualQATabRouteResolver {
    static func initialTab(for screen: VisualQAInitialScreen?) -> MegrumTab {
        switch screen {
        case .meguri, .groomArchive, .meguriProfileSettings, .meguriMessages, .meguriMessageThread:
            .meguri
        case .proposalPending:
            .trades
        case .inventory:
            .inventory
        case .wish:
            .wish
        default:
            .home
        }
    }

    static func requestedTradesStage(for screen: VisualQAInitialScreen?) -> TradeStage? {
        switch screen {
        case .proposalPending:
            .pending
        default:
            nil
        }
    }
}
