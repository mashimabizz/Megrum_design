import Foundation
import MegrumCore

enum TradeStageRouteRequestResolver {
    static func resolve(current: TradeStage, requested: TradeStage?) -> TradeStage {
        requested ?? current
    }
}

struct TradeDetailRoute: Identifiable, Hashable {
    var proposalID: UUID

    var id: UUID { proposalID }
}

enum TradeCardReadState: Equatable {
    case unopened
    case opened
    case waitingForReply

    var title: String {
        switch self {
        case .unopened:
            "未開封"
        case .opened:
            "開封済み"
        case .waitingForReply:
            "返信待ち"
        }
    }
}
