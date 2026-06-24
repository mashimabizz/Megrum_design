import Foundation
import MegrumCore

enum DisputeDetailMessageSenderRole: String, Equatable, Sendable {
    case reporter
    case respondent
    case `operator`
    case unknown
}

enum DisputeDetailViewerRole: Equatable, Sendable {
    case reporter
    case respondent
}

struct DisputeDetailMessageModel: Identifiable, Equatable, Sendable {
    var id: UUID
    var senderID: UUID?
    var senderRole: DisputeDetailMessageSenderRole
    var senderName: String
    var body: String
    var createdAt: Date
    var photoURLs: [String]

    init(
        id: UUID = UUID(),
        senderID: UUID? = nil,
        senderRole: DisputeDetailMessageSenderRole = .unknown,
        senderName: String,
        body: String,
        createdAt: Date,
        photoURLs: [String] = []
    ) {
        self.id = id
        self.senderID = senderID
        self.senderRole = senderRole
        self.senderName = senderName
        self.body = body
        self.createdAt = createdAt
        self.photoURLs = photoURLs
    }
}

struct DisputeDetailModel: Identifiable, Equatable, Sendable {
    var id: UUID
    var proposalID: UUID
    var reporterID: UUID?
    var respondentID: UUID?
    var viewerRole: DisputeDetailViewerRole?
    var ticketNo: String
    var status: DisputeDetailStatus
    var category: TradeDisputeCategory?
    var reporterName: String
    var respondentName: String
    var factMemo: String?
    var evidencePhotoURLs: [String]
    var respondentEvidencePhotoURLs: [String]
    var createdAt: Date?
    var submittedAt: Date
    var replyDeadlineAt: Date?
    var operatorDeadlineAt: Date?
    var resolvedAt: Date?
    var resolutionSummary: String?
    var timeline: [DisputeTimelineEvent]
    var messages: [DisputeDetailMessageModel]

    init(
        id: UUID,
        proposalID: UUID,
        reporterID: UUID? = nil,
        respondentID: UUID? = nil,
        viewerRole: DisputeDetailViewerRole? = nil,
        ticketNo: String,
        status: DisputeDetailStatus,
        category: TradeDisputeCategory? = nil,
        reporterName: String = "あなた",
        respondentName: String = "相手",
        factMemo: String? = nil,
        evidencePhotoURLs: [String] = [],
        respondentEvidencePhotoURLs: [String] = [],
        createdAt: Date? = nil,
        submittedAt: Date,
        replyDeadlineAt: Date? = nil,
        operatorDeadlineAt: Date? = nil,
        resolvedAt: Date? = nil,
        resolutionSummary: String? = nil,
        timeline: [DisputeTimelineEvent]? = nil,
        messages: [DisputeDetailMessageModel] = []
    ) {
        self.id = id
        self.proposalID = proposalID
        self.reporterID = reporterID
        self.respondentID = respondentID
        self.viewerRole = viewerRole
        self.ticketNo = ticketNo
        self.status = status
        self.category = category
        self.reporterName = reporterName
        self.respondentName = respondentName
        self.factMemo = factMemo
        self.evidencePhotoURLs = evidencePhotoURLs
        self.respondentEvidencePhotoURLs = respondentEvidencePhotoURLs
        self.createdAt = createdAt
        self.submittedAt = submittedAt
        self.replyDeadlineAt = replyDeadlineAt
        self.operatorDeadlineAt = operatorDeadlineAt
        self.resolvedAt = resolvedAt
        self.resolutionSummary = resolutionSummary
        self.timeline = timeline ?? DisputeDetailTimelineBuilder.build(
            status: status,
            submittedAt: submittedAt,
            replyDeadlineAt: replyDeadlineAt,
            resolvedAt: resolvedAt
        )
        self.messages = messages
    }

    init(ticket: TradeDisputeTicket, category: TradeDisputeCategory? = nil, reporterName: String = "あなた", respondentName: String = "相手", factMemo: String? = nil, replyDeadlineAt: Date? = nil) {
        self.init(
            id: ticket.id,
            proposalID: ticket.proposalID,
            ticketNo: ticket.ticketNo,
            status: DisputeDetailStatus(rawStatus: ticket.status),
            category: category,
            reporterName: reporterName,
            respondentName: respondentName,
            factMemo: factMemo,
            submittedAt: ticket.submittedAt,
            replyDeadlineAt: replyDeadlineAt
        )
    }

    var canSubmitReply: Bool {
        status.allowsReply && viewerRole != .reporter
    }

    var canWithdraw: Bool {
        status.allowsWithdrawal && viewerRole != .respondent
    }

    var statusDescription: String {
        switch status {
        case .filed:
            return "申告内容を確認中です。送信前なら内容を整えられます。"
        case .submitted:
            return "申告を受け付けました。相手へ反論機会を通知します。"
        case .replyWindow:
            return "相手の反論を待っています。期限後は運営確認へ進みます。"
        case .replyReceived:
            return "相手の反論を受け付けました。運営確認へ進みます。"
        case .arbitration:
            return "運営が申告内容、取引チャット、証跡を確認しています。"
        case .resolved:
            return "仲裁結果が確定しました。結果と運営コメントを確認してください。"
        case .withdrawn:
            return "この申告は取り下げ済みです。追加の反論や仲裁確認は行われません。"
        }
    }

    var nextActionText: String {
        if canSubmitReply {
            return "反論内容を入力し、必要な証跡があれば本文に補足してください。"
        }
        if canWithdraw {
            return "状況が解決した場合は、申告を取り下げられます。"
        }

        switch status {
        case .replyReceived, .arbitration:
            return "追加確認が必要な場合は運営から連絡があります。"
        case .resolved:
            return "結果を確認し、必要なら取引チャットへ戻ってください。"
        case .withdrawn:
            return "取引チャットから必要な連絡を続けてください。"
        default:
            return "現在この申告で行える操作はありません。"
        }
    }

    var withdrawalUnavailableText: String? {
        guard !canWithdraw else {
            return nil
        }
        if viewerRole == .respondent {
            return "取り下げは申告者だけが行えます。"
        }
        switch status {
        case .replyReceived:
            return "相手の反論後は運営確認に進むため、画面からは取り下げできません。"
        case .arbitration:
            return "仲裁中のため、取り下げは運営確認が必要です。"
        case .resolved:
            return "仲裁結果が確定済みです。"
        case .withdrawn:
            return "申告は取り下げ済みです。"
        case .filed, .submitted, .replyWindow:
            return nil
        }
    }

    var evidenceGroups: [DisputeEvidenceGroup] {
        [
            DisputeEvidenceGroup(title: "申告者の証跡", ownerName: reporterName, photoURLs: evidencePhotoURLs),
            DisputeEvidenceGroup(title: "相手の証跡", ownerName: respondentName, photoURLs: respondentEvidencePhotoURLs)
        ].filter { !$0.photoURLs.isEmpty }
    }

    func replacing(
        status: DisputeDetailStatus? = nil,
        resolvedAt: Date? = nil,
        resolutionSummary: String? = nil,
        messages: [DisputeDetailMessageModel]? = nil
    ) -> DisputeDetailModel {
        let nextStatus = status ?? self.status
        let nextResolvedAt = resolvedAt ?? self.resolvedAt
        let nextTimeline = status == nil && resolvedAt == nil ? timeline : nil
        return DisputeDetailModel(
            id: id,
            proposalID: proposalID,
            reporterID: reporterID,
            respondentID: respondentID,
            viewerRole: viewerRole,
            ticketNo: ticketNo,
            status: nextStatus,
            category: category,
            reporterName: reporterName,
            respondentName: respondentName,
            factMemo: factMemo,
            evidencePhotoURLs: evidencePhotoURLs,
            respondentEvidencePhotoURLs: respondentEvidencePhotoURLs,
            createdAt: createdAt,
            submittedAt: submittedAt,
            replyDeadlineAt: replyDeadlineAt,
            operatorDeadlineAt: operatorDeadlineAt,
            resolvedAt: nextResolvedAt,
            resolutionSummary: resolutionSummary ?? self.resolutionSummary,
            timeline: nextTimeline,
            messages: messages ?? self.messages
        )
    }

    func replyCountdownText(now: Date = .now) -> String {
        guard let replyDeadlineAt else {
            return "反論期限は未設定です"
        }
        let remainingSeconds = Int(replyDeadlineAt.timeIntervalSince(now))
        guard remainingSeconds > 0 else {
            return "反論期限を過ぎています"
        }
        let hours = remainingSeconds / 3_600
        if hours >= 1 {
            return "反論期限まで残り\(hours)時間"
        }
        let minutes = max(1, remainingSeconds / 60)
        return "反論期限まで残り\(minutes)分"
    }

    func counterpartyID(for viewerID: UUID) -> UUID? {
        if reporterID == viewerID {
            return respondentID
        }
        if respondentID == viewerID {
            return reporterID
        }
        return nil
    }
}

struct DisputeEvidenceGroup: Identifiable, Equatable, Sendable {
    var id: String { title }
    var title: String
    var ownerName: String
    var photoURLs: [String]
}
