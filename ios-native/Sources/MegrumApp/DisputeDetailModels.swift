import MegrumCore
import MegrumData
import MegrumDesign
import SwiftUI

enum DisputeDetailStatus: String, CaseIterable, Identifiable, Equatable, Sendable {
    case filed
    case submitted
    case replyWindow = "reply_window"
    case replyReceived = "reply_received"
    case arbitration
    case resolved
    case withdrawn

    var id: String { rawValue }

    init(rawStatus: String) {
        switch rawStatus.normalizedDisputeStatus {
        case "response_pending":
            self = .replyWindow
        case "responded":
            self = .replyReceived
        case "arbitrating":
            self = .arbitration
        case "closed":
            self = .resolved
        default:
            self = DisputeDetailStatus(rawValue: rawStatus.normalizedDisputeStatus) ?? .submitted
        }
    }

    init(supabaseStatus: String, outcome: String?, operatorComment: String?, closedAt: Date?, respondentRespondedAt: Date?) {
        let normalized = supabaseStatus.normalizedDisputeStatus
        if normalized == "closed" {
            self = outcome.nilIfBlank == nil && operatorComment.nilIfBlank == nil ? .withdrawn : .resolved
            return
        }
        if normalized == "response_pending", respondentRespondedAt != nil {
            self = .replyReceived
            return
        }
        self.init(rawStatus: normalized)
    }

    var displayName: String {
        switch self {
        case .filed:
            "申告作成中"
        case .submitted:
            "申告送信済"
        case .replyWindow:
            "反論受付中"
        case .replyReceived:
            "反論受領"
        case .arbitration:
            "仲裁中"
        case .resolved:
            "仲裁決定済"
        case .withdrawn:
            "取り下げ済"
        }
    }

    var systemImage: String {
        switch self {
        case .filed:
            "square.and.pencil"
        case .submitted:
            "tray.and.arrow.up.fill"
        case .replyWindow:
            "bubble.left.and.bubble.right.fill"
        case .replyReceived:
            "text.bubble.fill"
        case .arbitration:
            "person.2.badge.gearshape.fill"
        case .resolved:
            "checkmark.seal.fill"
        case .withdrawn:
            "arrow.uturn.backward.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .resolved:
            MegrumTheme.ok
        case .withdrawn:
            MegrumTheme.muted
        case .arbitration:
            MegrumTheme.sky
        default:
            MegrumTheme.lavender
        }
    }

    var allowsReply: Bool {
        self == .submitted || self == .replyWindow
    }

    var allowsWithdrawal: Bool {
        switch self {
        case .filed, .submitted, .replyWindow:
            true
        case .replyReceived, .arbitration, .resolved, .withdrawn:
            false
        }
    }
}

enum DisputeTimelineEventState: Equatable, Sendable {
    case completed
    case current
    case pending
}

enum DisputeDetailMessageSenderRole: String, Equatable, Sendable {
    case reporter
    case respondent
    case `operator`
    case unknown
}

enum DisputeDetailViewerRole: Equatable, Sendable {
    case reporter
    case respondent

    var participantRole: SupabaseDisputeParticipantRole {
        switch self {
        case .reporter:
            .reporter
        case .respondent:
            .respondent
        }
    }
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

struct DisputeDetailSupabaseMapper: Equatable, Sendable {
    var viewerID: UUID?
    var reporterName: String?
    var respondentName: String?

    init(viewerID: UUID? = nil, reporterName: String? = nil, respondentName: String? = nil) {
        self.viewerID = viewerID
        self.reporterName = reporterName
        self.respondentName = respondentName
    }

    func model(from detail: SupabaseDisputeDetail) -> DisputeDetailModel {
        DisputeDetailModel(supabaseDetail: detail, mapper: self)
    }

    func message(from message: SupabaseDisputeMessage, in detail: SupabaseDisputeDetail) -> DisputeDetailMessageModel {
        DisputeDetailMessageModel(supabaseMessage: message, detail: detail, mapper: self)
    }

    func senderRole(for viewerID: UUID, in detail: SupabaseDisputeDetail) -> SupabaseDisputeParticipantRole? {
        viewerRole(for: viewerID, in: detail)?.participantRole
    }

    func viewerRole(for viewerID: UUID, in detail: SupabaseDisputeDetail) -> DisputeDetailViewerRole? {
        if viewerID == detail.reporterID {
            return .reporter
        }
        if viewerID == detail.respondentID {
            return .respondent
        }
        return nil
    }

    func displayReporterName(for detail: SupabaseDisputeDetail) -> String {
        if let reporterName = reporterName?.nilIfBlank {
            return reporterName
        }
        if viewerID == detail.reporterID {
            return "あなた"
        }
        if viewerID == detail.respondentID {
            return "相手"
        }
        return "申告者"
    }

    func displayRespondentName(for detail: SupabaseDisputeDetail) -> String {
        if let respondentName = respondentName?.nilIfBlank {
            return respondentName
        }
        if viewerID == detail.respondentID {
            return "あなた"
        }
        return "相手"
    }

    func displayName(for role: DisputeDetailMessageSenderRole, senderID: UUID?, in detail: SupabaseDisputeDetail) -> String {
        if let viewerID, senderID == viewerID {
            return "あなた"
        }

        switch role {
        case .reporter:
            return displayReporterName(for: detail)
        case .respondent:
            return displayRespondentName(for: detail)
        case .operator:
            return "運営"
        case .unknown:
            if senderID == detail.reporterID {
                return displayReporterName(for: detail)
            }
            if senderID == detail.respondentID {
                return displayRespondentName(for: detail)
            }
            return senderID == nil ? "運営" : "参加者"
        }
    }
}

extension DisputeDetailModel {
    init(supabaseDetail detail: SupabaseDisputeDetail, mapper: DisputeDetailSupabaseMapper = DisputeDetailSupabaseMapper()) {
        let status = DisputeDetailStatus(
            supabaseStatus: detail.status,
            outcome: detail.outcome,
            operatorComment: detail.operatorComment,
            closedAt: detail.closedAt,
            respondentRespondedAt: detail.respondentRespondedAt
        )
        let messages = Self.mappedMessages(from: detail, mapper: mapper)
        self.init(
            id: detail.id,
            proposalID: detail.proposalID,
            reporterID: detail.reporterID,
            respondentID: detail.respondentID,
            viewerRole: mapper.viewerID.flatMap { mapper.viewerRole(for: $0, in: detail) },
            ticketNo: detail.ticketNo,
            status: status,
            category: detail.category,
            reporterName: mapper.displayReporterName(for: detail),
            respondentName: mapper.displayRespondentName(for: detail),
            factMemo: detail.factMemo,
            evidencePhotoURLs: detail.evidencePhotoURLs.cleanedPhotoURLs,
            respondentEvidencePhotoURLs: detail.respondentEvidenceURLs.cleanedPhotoURLs,
            createdAt: detail.createdAt,
            submittedAt: detail.submittedAt,
            replyDeadlineAt: detail.respondentDeadlineAt,
            operatorDeadlineAt: detail.operatorDeadlineAt,
            resolvedAt: detail.closedAt,
            resolutionSummary: Self.resolutionSummary(from: detail, status: status),
            messages: messages
        )
    }

    private static func mappedMessages(
        from detail: SupabaseDisputeDetail,
        mapper: DisputeDetailSupabaseMapper
    ) -> [DisputeDetailMessageModel] {
        var messages = detail.messages.map { mapper.message(from: $0, in: detail) }

        let respondentBody = detail.respondentResponseText.nilIfBlank ?? detail.respondentResponse.nilIfBlank
        let respondentPhotoURLs = detail.respondentEvidenceURLs.cleanedPhotoURLs
        let hasPersistedRespondentMessage = messages.contains { message in
            message.senderRole == .respondent && (respondentBody == nil || message.body == respondentBody)
        }
        if !hasPersistedRespondentMessage, respondentBody != nil || !respondentPhotoURLs.isEmpty {
            messages.append(
                DisputeDetailMessageModel(
                    id: detail.id,
                    senderID: detail.respondentID,
                    senderRole: .respondent,
                    senderName: mapper.displayRespondentName(for: detail),
                    body: respondentBody ?? "証跡写真が追加されました。",
                    createdAt: detail.respondentRespondedAt ?? detail.updatedAt ?? detail.submittedAt,
                    photoURLs: respondentPhotoURLs
                )
            )
        }

        return messages.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.createdAt < rhs.createdAt
        }
    }

    private static func resolutionSummary(from detail: SupabaseDisputeDetail, status: DisputeDetailStatus) -> String? {
        if status == .withdrawn {
            return "申告は取り下げられました。"
        }

        let outcome = detail.outcome.nilIfBlank
        let operatorComment = detail.operatorComment.nilIfBlank
        switch (outcome, operatorComment) {
        case let (.some(outcome), .some(operatorComment)):
            return "\(outcome)\n\(operatorComment)"
        case let (.some(outcome), .none):
            return outcome
        case let (.none, .some(operatorComment)):
            return operatorComment
        case (.none, .none):
            return nil
        }
    }
}

extension DisputeDetailMessageModel {
    init(
        supabaseMessage message: SupabaseDisputeMessage,
        detail: SupabaseDisputeDetail,
        mapper: DisputeDetailSupabaseMapper = DisputeDetailSupabaseMapper()
    ) {
        let role = DisputeDetailMessageSenderRole(supabaseRole: message.senderRole, senderID: message.senderID)
        self.init(
            id: message.id,
            senderID: message.senderID,
            senderRole: role,
            senderName: mapper.displayName(for: role, senderID: message.senderID, in: detail),
            body: message.body,
            createdAt: message.createdAt,
            photoURLs: message.photoURLs.cleanedPhotoURLs
        )
    }
}

private extension DisputeDetailMessageSenderRole {
    init(supabaseRole: SupabaseDisputeParticipantRole?, senderID: UUID?) {
        switch supabaseRole {
        case .reporter:
            self = .reporter
        case .respondent:
            self = .respondent
        case .none:
            self = senderID == nil ? .operator : .unknown
        }
    }
}

private extension Array where Element == String {
    var cleanedPhotoURLs: [String] {
        map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private extension String {
    var normalizedDisputeStatus: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
    }

}
