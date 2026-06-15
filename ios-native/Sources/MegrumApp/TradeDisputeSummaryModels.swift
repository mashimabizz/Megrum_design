import Foundation
import MegrumCore

struct TradeDisputeSummary: Identifiable, Equatable, Sendable {
    var id: UUID
    var sourceMessageID: UUID
    var proposalID: UUID
    var reporterID: UUID
    var ticketNo: String
    var status: DisputeDetailStatus
    var category: TradeDisputeCategory?
    var factMemo: String?
    var body: String
    var submittedAt: Date

    init?(message: TradeMessage) {
        guard message.messageType == .system else {
            return nil
        }

        let body = message.body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let ticketNo = message.meta.firstNonBlank([
            "ticket_no",
            "ticketNo",
            "dispute_ticket_no",
            "disputeTicketNo"
        ]) ?? body?.firstDisputeTicketNumber
        let action = message.meta.firstNonBlank(["action", "event"])
        let hasDisputeAction = action.map(Self.isDisputeAction) ?? false
        let hasDisputeBody = body?.contains("申告") == true

        guard ticketNo != nil || hasDisputeAction || hasDisputeBody else {
            return nil
        }

        self.id = message.meta.uuidValue(for: ["dispute_id", "disputeID", "ticket_id", "ticketID"]) ?? message.id
        self.sourceMessageID = message.id
        self.proposalID = message.proposalID
        self.reporterID = message.senderID
        self.ticketNo = ticketNo ?? "受付済み"
        self.status = Self.status(from: message.meta, action: action)
        self.category = message.meta.firstNonBlank(["category", "dispute_category"]).flatMap(TradeDisputeCategory.init(rawValue:))
        self.factMemo = message.meta.firstNonBlank(["fact_memo", "factMemo", "memo"])
        self.body = body ?? "取引の申告を受け付けました。"
        self.submittedAt = message.createdAt
    }

    var bannerTitle: String {
        switch status {
        case .resolved:
            "申告の結果が届いています"
        case .withdrawn:
            "申告は取り下げ済みです"
        case .replyReceived, .arbitration:
            "申告を運営が確認中です"
        default:
            "申告を受け付けました"
        }
    }

    var bannerBody: String {
        if ticketNo == "受付済み" {
            return status.displayName
        }
        return "\(ticketNo) · \(status.displayName)"
    }

    func detailModel(proposal: TradeProposal, viewerID: UUID?) -> DisputeDetailModel {
        let respondentID = proposal.partnerID(for: reporterID)
            ?? viewerID.flatMap { proposal.partnerID(for: $0) }
            ?? proposal.receiverID
        let viewerRole: DisputeDetailViewerRole?
        if viewerID == reporterID {
            viewerRole = .reporter
        } else if viewerID == respondentID {
            viewerRole = .respondent
        } else {
            viewerRole = nil
        }

        let reporterName = viewerRole == .reporter ? "あなた" : "相手"
        let respondentName = viewerRole == .respondent ? "あなた" : "相手"
        let safeStatus = status.interactionSafeFallback

        return DisputeDetailModel(
            id: id,
            proposalID: proposalID,
            reporterID: reporterID,
            respondentID: respondentID,
            viewerRole: viewerRole,
            ticketNo: ticketNo,
            status: safeStatus,
            category: category,
            reporterName: reporterName,
            respondentName: respondentName,
            factMemo: factMemo,
            submittedAt: submittedAt,
            messages: [
                DisputeDetailMessageModel(
                    id: sourceMessageID,
                    senderID: nil,
                    senderRole: .operator,
                    senderName: "運営",
                    body: body,
                    createdAt: submittedAt
                )
            ]
        )
    }

    private static func isDisputeAction(_ action: String) -> Bool {
        action.hasPrefix("dispute_") || action == "dispute"
    }

    private static func status(from meta: [String: String], action: String?) -> DisputeDetailStatus {
        if let rawStatus = meta.firstNonBlank(["dispute_status", "status"]) {
            return DisputeDetailStatus(rawStatus: rawStatus)
        }

        switch action {
        case "dispute_closed":
            return .resolved
        case "dispute_responded":
            return .replyReceived
        case "dispute_withdrawn":
            return .withdrawn
        case "dispute_received", "dispute_created", "dispute":
            return .submitted
        default:
            return .submitted
        }
    }
}

struct TradeDisputeDetailRoute: Identifiable, Equatable, Hashable {
    var summary: TradeDisputeSummary
    var model: DisputeDetailModel

    var id: UUID { summary.id }

    static func == (lhs: TradeDisputeDetailRoute, rhs: TradeDisputeDetailRoute) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

private extension DisputeDetailStatus {
    var interactionSafeFallback: DisputeDetailStatus {
        switch self {
        case .filed, .submitted, .replyWindow:
            .arbitration
        default:
            self
        }
    }
}

private extension Dictionary where Key == String, Value == String {
    func firstNonBlank(_ keys: [String]) -> String? {
        for key in keys {
            if let value = self[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }
        return nil
    }

    func uuidValue(for keys: [String]) -> UUID? {
        firstNonBlank(keys).flatMap(UUID.init(uuidString:))
    }
}

private extension String {
    var firstDisputeTicketNumber: String? {
        let pattern = #"#?(DPT-[A-Z0-9-]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let range = NSRange(startIndex..<endIndex, in: self)
        guard let match = regex.firstMatch(in: self, range: range),
              let ticketRange = Range(match.range(at: 1), in: self)
        else {
            return nil
        }
        return String(self[ticketRange])
    }
}
