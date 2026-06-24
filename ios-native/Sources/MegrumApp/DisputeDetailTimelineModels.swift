import Foundation

enum DisputeTimelineEventState: Equatable, Sendable {
    case completed
    case current
    case pending
}

struct DisputeTimelineEvent: Identifiable, Equatable, Sendable {
    var id: String
    var status: DisputeDetailStatus
    var title: String
    var detail: String
    var date: Date?
    var state: DisputeTimelineEventState

    init(
        status: DisputeDetailStatus,
        detail: String,
        date: Date? = nil,
        state: DisputeTimelineEventState
    ) {
        self.id = status.rawValue
        self.status = status
        self.title = status.displayName
        self.detail = detail
        self.date = date
        self.state = state
    }
}

enum DisputeDetailTimelineBuilder {
    static func build(
        status: DisputeDetailStatus,
        submittedAt: Date,
        replyDeadlineAt: Date? = nil,
        resolvedAt: Date? = nil
    ) -> [DisputeTimelineEvent] {
        let order = orderedStatuses(for: status)
        let currentIndex = order.firstIndex(of: status) ?? 0

        return order.enumerated().map { index, item in
            DisputeTimelineEvent(
                status: item,
                detail: detail(for: item, replyDeadlineAt: replyDeadlineAt),
                date: date(for: item, submittedAt: submittedAt, resolvedAt: resolvedAt),
                state: eventState(index: index, currentIndex: currentIndex)
            )
        }
    }

    private static func orderedStatuses(for status: DisputeDetailStatus) -> [DisputeDetailStatus] {
        switch status {
        case .filed:
            [.filed, .submitted, .replyWindow, .arbitration, .resolved]
        case .replyReceived:
            [.submitted, .replyWindow, .replyReceived, .arbitration, .resolved]
        case .withdrawn:
            [.submitted, .withdrawn]
        default:
            [.submitted, .replyWindow, .arbitration, .resolved]
        }
    }

    private static func eventState(index: Int, currentIndex: Int) -> DisputeTimelineEventState {
        if index < currentIndex {
            return .completed
        }
        if index == currentIndex {
            return .current
        }
        return .pending
    }

    private static func date(for status: DisputeDetailStatus, submittedAt: Date, resolvedAt: Date?) -> Date? {
        switch status {
        case .submitted:
            submittedAt
        case .resolved:
            resolvedAt
        case .withdrawn:
            resolvedAt
        default:
            nil
        }
    }

    private static func detail(for status: DisputeDetailStatus, replyDeadlineAt: Date?) -> String {
        switch status {
        case .filed:
            return "内容を確認してから申告を送ります。"
        case .submitted:
            return "受付番号が発行され、取引相手に通知されます。"
        case .replyWindow:
            if let replyDeadlineAt {
                return "相手は \(replyDeadlineAt.formatted(date: .abbreviated, time: .shortened)) まで反論できます。"
            }
            return "相手の反論を待っています。"
        case .replyReceived:
            return "相手の反論が届き、運営確認に進みます。"
        case .arbitration:
            return "運営が取引チャット、証跡、申告内容を確認しています。"
        case .resolved:
            return "仲裁結果が反映され、取引の凍結が解除されます。"
        case .withdrawn:
            return "申告は取り下げられました。"
        }
    }
}
