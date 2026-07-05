import Foundation
import MegrumCore

enum TradeStage: String, CaseIterable, Identifiable {
    case pending
    case inProgress
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending:
            "打診中"
        case .inProgress:
            "進行中"
        case .completed:
            "完了済み"
        }
    }

    var subtitle: String {
        switch self {
        case .pending:
            "送信済み・調整中の打診"
        case .inProgress:
            "成立後の取引"
        case .completed:
            "完了・キャンセル・終了した取引"
        }
    }

    func contains(_ status: ProposalStatus) -> Bool {
        switch self {
        case .pending:
            [.draft, .sent, .negotiating, .agreementOneSide].contains(status)
        case .inProgress:
            status == .agreed
        case .completed:
            [.completed, .cancelled, .rejected, .expired].contains(status)
        }
    }

    /// 一覧に表示する取引か。完了済みステージは「取引成立後」のものだけ
    /// 表示する（成立前の拒否・期限切れ・キャンセルは表示しない）。
    func containsForDisplay(_ proposal: TradeProposal) -> Bool {
        switch self {
        case .pending, .inProgress:
            return contains(proposal.status)
        case .completed:
            if proposal.status == .completed {
                return true
            }
            let wasAgreed = proposal.agreedBySender && proposal.agreedByReceiver
            return wasAgreed && [.cancelled, .rejected, .expired].contains(proposal.status)
        }
    }

    var next: TradeStage {
        switch self {
        case .pending:
            .inProgress
        case .inProgress:
            .completed
        case .completed:
            .completed
        }
    }

    var previous: TradeStage {
        switch self {
        case .pending:
            .pending
        case .inProgress:
            .pending
        case .completed:
            .inProgress
        }
    }

    var emptyTitle: String {
        switch self {
        case .pending:
            "打診中の取引はありません"
        case .inProgress:
            "進行中の取引はありません"
        case .completed:
            "完了済みの取引はありません"
        }
    }

    var emptyMessage: String {
        switch self {
        case .pending:
            "送信済み・調整中の打診が届くとここに表示されます。"
        case .inProgress:
            "成立した取引はここから取引チャットを開けます。"
        case .completed:
            "完了後の証跡・評価や終了した打診をここから確認できます。"
        }
    }
}

extension TradeProposal {
    var isProposalResponsePending: Bool {
        [.sent, .negotiating, .agreementOneSide].contains(status)
    }
}
