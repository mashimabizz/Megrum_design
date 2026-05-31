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

    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension Optional where Wrapped == String {
    var nilIfBlank: String? {
        flatMap(\.nilIfBlank)
    }
}

struct DisputeReplyDraft: Equatable, Sendable {
    static let maxBodyLength = 4_000

    var body: String = ""
    var includesEvidenceNote = true

    var normalizedBody: String {
        body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSubmittable: Bool {
        validationMessage == nil
    }

    var validationMessage: String? {
        if normalizedBody.isEmpty {
            return "本文を入力してください"
        }
        if normalizedBody.count > Self.maxBodyLength {
            return "本文は\(Self.maxBodyLength)文字以内で入力してください"
        }
        return nil
    }
}

enum TradeRequestKind: String, CaseIterable, Identifiable, Sendable {
    case cancellation
    case late

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cancellation:
            "キャンセル申請"
        case .late:
            "遅刻申請"
        }
    }

    var shortTitle: String {
        switch self {
        case .cancellation:
            "キャンセル"
        case .late:
            "遅刻"
        }
    }

    var systemImage: String {
        switch self {
        case .cancellation:
            "xmark.circle.fill"
        case .late:
            "clock.badge.exclamationmark.fill"
        }
    }

    var reasonPlaceholder: String {
        switch self {
        case .cancellation:
            "キャンセルが必要な理由"
        case .late:
            "遅れる理由と到着見込み"
        }
    }

    var acknowledgementText: String {
        switch self {
        case .cancellation:
            "キャンセル後の取引継続可否は相手と運営の確認が必要です。"
        case .late:
            "30分を超える遅刻では、相手にキャンセル権が発生する可能性があります。"
        }
    }
}

struct TradeRequestDraft: Equatable, Sendable {
    var kind: TradeRequestKind
    var reason: String = ""
    var estimatedDelayMinutes = 10
    var acknowledgesImpact = false

    var normalizedReason: String {
        reason.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSubmittable: Bool {
        guard !normalizedReason.isEmpty, acknowledgesImpact else {
            return false
        }

        switch kind {
        case .cancellation:
            return true
        case .late:
            return (5...180).contains(estimatedDelayMinutes)
        }
    }

    var systemMessageBody: String? {
        guard isSubmittable else {
            return nil
        }

        switch kind {
        case .cancellation:
            return "キャンセル申請: \(normalizedReason)"
        case .late:
            return "遅刻申請: \(estimatedDelayMinutes)分ほど遅れます。\(normalizedReason)"
        }
    }
}

enum DisputeDetailLoadState: Equatable, Sendable {
    case loading
    case loaded(DisputeDetailModel)
    case empty
    case failed(String)

    var model: DisputeDetailModel? {
        if case .loaded(let model) = self {
            return model
        }
        return nil
    }
}

enum DisputeDetailActionError: LocalizedError, Equatable {
    case notCompleted
    case notParticipant

    var errorDescription: String? {
        switch self {
        case .notCompleted:
            "操作を完了できませんでした。"
        case .notParticipant:
            "この申告を操作できません。"
        }
    }
}

@MainActor
final class DisputeDetailStore: ObservableObject {
    typealias DetailAction = () async throws -> DisputeDetailModel?
    typealias ReplyAction = (DisputeReplyDraft) async throws -> DisputeDetailModel?
    typealias WithdrawAction = () async throws -> DisputeDetailModel?

    struct Actions {
        var detail: DetailAction
        var reply: ReplyAction
        var withdraw: WithdrawAction

        init(
            detail: @escaping DetailAction,
            reply: @escaping ReplyAction,
            withdraw: @escaping WithdrawAction
        ) {
            self.detail = detail
            self.reply = reply
            self.withdraw = withdraw
        }

        static func supabase(
            ticketID: UUID,
            viewerID: UUID,
            client: SupabaseDisputeClient,
            mapper: DisputeDetailSupabaseMapper? = nil
        ) -> Actions {
            let mapper = mapper ?? DisputeDetailSupabaseMapper(viewerID: viewerID)
            return Actions(
                detail: {
                    try await client.loadDispute(ticketID: ticketID).map(mapper.model(from:))
                },
                reply: { draft in
                    guard let detail = try await client.loadDispute(ticketID: ticketID) else {
                        return nil
                    }
                    guard let senderRole = mapper.senderRole(for: viewerID, in: detail) else {
                        throw DisputeDetailActionError.notParticipant
                    }
                    _ = try await client.createDisputeReply(
                        SupabaseDisputeReplyCreateInput(
                            disputeID: ticketID,
                            senderID: viewerID,
                            senderRole: senderRole,
                            body: draft.normalizedBody
                        )
                    )
                    return try await client.loadDispute(ticketID: ticketID).map(mapper.model(from:))
                },
                withdraw: {
                    try await client.withdrawDispute(ticketID: ticketID, reporterID: viewerID)
                        .map(mapper.model(from:))
                }
            )
        }
    }

    @Published private(set) var state: DisputeDetailLoadState
    @Published var replyDraft: DisputeReplyDraft
    @Published private(set) var isLoading = false
    @Published private(set) var isSubmittingReply = false
    @Published private(set) var isWithdrawing = false
    @Published private(set) var actionErrorMessage: String?

    private let detail: DetailAction
    private let reply: ReplyAction
    private let withdraw: WithdrawAction
    private var hasLoaded = false

    convenience init(
        initialState: DisputeDetailLoadState = .loading,
        initialReplyDraft: DisputeReplyDraft = DisputeReplyDraft(),
        detail: @escaping DetailAction,
        reply: @escaping ReplyAction,
        withdraw: @escaping WithdrawAction
    ) {
        self.init(
            initialState: initialState,
            initialReplyDraft: initialReplyDraft,
            actions: Actions(detail: detail, reply: reply, withdraw: withdraw)
        )
    }

    init(
        initialState: DisputeDetailLoadState = .loading,
        initialReplyDraft: DisputeReplyDraft = DisputeReplyDraft(),
        actions: Actions
    ) {
        self.state = initialState
        self.replyDraft = initialReplyDraft
        self.detail = actions.detail
        self.reply = actions.reply
        self.withdraw = actions.withdraw
        self.hasLoaded = initialState.model != nil
    }

    func loadIfNeeded() async {
        guard !hasLoaded else {
            return
        }
        await load()
    }

    func load() async {
        hasLoaded = true
        isLoading = true
        if state.model == nil {
            state = .loading
        }
        do {
            state = try await resolvedState(from: detail())
        } catch {
            state = .failed(Self.message(for: error))
        }
        isLoading = false
    }

    func submitReply() async {
        let draft = replyDraft
        guard draft.isSubmittable, !isSubmittingReply else {
            return
        }
        guard state.model?.canSubmitReply == true else {
            actionErrorMessage = "この状態では反論を送信できません。"
            return
        }

        isSubmittingReply = true
        actionErrorMessage = nil
        do {
            let updated = try await reply(draft)
            replyDraft = DisputeReplyDraft()
            if let updated {
                state = .loaded(updated)
            } else {
                state = try await resolvedState(from: detail())
            }
        } catch {
            actionErrorMessage = Self.message(for: error)
        }
        isSubmittingReply = false
    }

    func withdrawDispute() async {
        guard state.model?.canWithdraw == true, !isWithdrawing else {
            return
        }

        isWithdrawing = true
        actionErrorMessage = nil
        do {
            state = try await resolvedState(from: withdraw())
        } catch {
            actionErrorMessage = Self.message(for: error)
        }
        isWithdrawing = false
    }

    func clearActionError() {
        actionErrorMessage = nil
    }

    private func resolvedState(from model: DisputeDetailModel?) -> DisputeDetailLoadState {
        if let model {
            return .loaded(model)
        }
        return .empty
    }

    private static func message(for error: Error) -> String {
        let localized = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !localized.isEmpty {
            return localized
        }
        return "時間をおいてもう一度お試しください。"
    }
}

struct DisputeDetailScreen: View {
    @StateObject private var store: DisputeDetailStore
    var onSubmitTradeRequest: (TradeRequestDraft) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var presentedRequestKind: TradeRequestKind?
    @State private var isShowingWithdrawConfirmation = false

    init(
        model: DisputeDetailModel,
        initialReplyDraft: DisputeReplyDraft = DisputeReplyDraft(),
        onSubmitReply: @escaping (DisputeReplyDraft) async -> Bool = { _ in false },
        onSubmitTradeRequest: @escaping (TradeRequestDraft) async -> Bool = { _ in false },
        onWithdraw: @escaping () async -> Bool = { false }
    ) {
        self._store = StateObject(
            wrappedValue: DisputeDetailStore(
                initialState: .loaded(model),
                initialReplyDraft: initialReplyDraft,
                detail: { model },
                reply: { draft in
                    if await onSubmitReply(draft) {
                        return nil
                    }
                    throw DisputeDetailActionError.notCompleted
                },
                withdraw: {
                    if await onWithdraw() {
                        return model.replacing(
                            status: .withdrawn,
                            resolvedAt: Date(),
                            resolutionSummary: "申告は取り下げられました。"
                        )
                    }
                    throw DisputeDetailActionError.notCompleted
                }
            )
        )
        self.onSubmitTradeRequest = onSubmitTradeRequest
    }

    init(
        initialReplyDraft: DisputeReplyDraft = DisputeReplyDraft(),
        detail: @escaping DisputeDetailStore.DetailAction,
        reply: @escaping DisputeDetailStore.ReplyAction,
        withdraw: @escaping DisputeDetailStore.WithdrawAction,
        onSubmitTradeRequest: @escaping (TradeRequestDraft) async -> Bool = { _ in false }
    ) {
        self._store = StateObject(
            wrappedValue: DisputeDetailStore(
                initialReplyDraft: initialReplyDraft,
                detail: detail,
                reply: reply,
                withdraw: withdraw
            )
        )
        self.onSubmitTradeRequest = onSubmitTradeRequest
    }

    init(
        initialReplyDraft: DisputeReplyDraft = DisputeReplyDraft(),
        actions: DisputeDetailStore.Actions,
        onSubmitTradeRequest: @escaping (TradeRequestDraft) async -> Bool = { _ in false }
    ) {
        self._store = StateObject(
            wrappedValue: DisputeDetailStore(
                initialReplyDraft: initialReplyDraft,
                actions: actions
            )
        )
        self.onSubmitTradeRequest = onSubmitTradeRequest
    }

    init(
        ticketID: UUID,
        viewerID: UUID,
        disputeClient: SupabaseDisputeClient,
        mapper: DisputeDetailSupabaseMapper? = nil,
        initialReplyDraft: DisputeReplyDraft = DisputeReplyDraft(),
        onSubmitTradeRequest: @escaping (TradeRequestDraft) async -> Bool = { _ in false }
    ) {
        self.init(
            initialReplyDraft: initialReplyDraft,
            actions: .supabase(
                ticketID: ticketID,
                viewerID: viewerID,
                client: disputeClient,
                mapper: mapper
            ),
            onSubmitTradeRequest: onSubmitTradeRequest
        )
    }

    init(
        store: DisputeDetailStore,
        onSubmitTradeRequest: @escaping (TradeRequestDraft) async -> Bool = { _ in false }
    ) {
        self._store = StateObject(wrappedValue: store)
        self.onSubmitTradeRequest = onSubmitTradeRequest
    }

    var body: some View {
        Group {
            switch store.state {
            case .loading:
                loadingView
            case .loaded(let model):
                loadedList(model: model)
            case .empty:
                emptyView
            case .failed(let message):
                errorView(message: message)
            }
        }
        .task {
            await store.loadIfNeeded()
        }
        .navigationTitle("異議詳細")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }

            if store.state.model?.canWithdraw == true {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        isShowingWithdrawConfirmation = true
                    } label: {
                        if store.isWithdrawing {
                            ProgressView()
                        } else {
                            Label("取り下げ", systemImage: "arrow.uturn.backward")
                        }
                    }
                }
            }
        }
        .sheet(item: $presentedRequestKind) { kind in
            NavigationStack {
                TradeRequestSheet(kind: kind, onSubmit: onSubmitTradeRequest)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "申告を取り下げますか？",
            isPresented: $isShowingWithdrawConfirmation,
            titleVisibility: .visible
        ) {
            Button("取り下げる", role: .destructive) {
                Task {
                    await store.withdrawDispute()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("取り下げ後は、この申告への反論や仲裁確認を進められません。")
        }
        .alert(
            "操作を完了できませんでした",
            isPresented: Binding(
                get: { store.actionErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        store.clearActionError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                store.clearActionError()
            }
        } message: {
            Text(store.actionErrorMessage ?? "")
        }
    }

    private var loadingView: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    ProgressView("読み込み中")
                    Spacer()
                }
                .padding(.vertical, 32)
            }
        }
        .scrollContentBackground(.hidden)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .disputeDetailListStyle()
    }

    private var emptyView: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.bubble")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(MegrumTheme.muted)
                    Text("申告が見つかりません")
                        .font(.headline)
                        .foregroundStyle(MegrumTheme.ink)
                    Text("取引チャットや通知から、もう一度開いてください。")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(MegrumTheme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
        .scrollContentBackground(.hidden)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .disputeDetailListStyle()
    }

    private func errorView(message: String) -> some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(MegrumTheme.muted)
                    Text("読み込めませんでした")
                        .font(.headline)
                        .foregroundStyle(MegrumTheme.ink)
                    Text(message)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(MegrumTheme.muted)
                    Button {
                        Task {
                            await store.load()
                        }
                    } label: {
                        Label("再読み込み", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
        .scrollContentBackground(.hidden)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .disputeDetailListStyle()
    }

    private func loadedList(model: DisputeDetailModel) -> some View {
        List {
            Section {
                DisputeStatusHeader(model: model)
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .listRowBackground(Color.clear)

            Section("タイムライン") {
                DisputeTimelineView(entries: model.timeline)
                    .padding(.vertical, 4)
            }

            Section("申告内容") {
                LabeledContent("受付番号", value: model.ticketNo)
                LabeledContent("カテゴリ", value: model.category?.displayName ?? "未設定")
                LabeledContent("申告者", value: model.reporterName)
                LabeledContent("相手", value: model.respondentName)

                if let factMemo = model.factMemo?.trimmingCharacters(in: .whitespacesAndNewlines), !factMemo.isEmpty {
                    Text(factMemo)
                        .font(.body)
                        .foregroundStyle(MegrumTheme.ink)
                        .padding(.vertical, 4)
                }
            }

            Section("証跡") {
                if model.evidenceGroups.isEmpty {
                    ContentUnavailableView(
                        "添付された証跡はありません",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("取引チャットや交換証跡の内容も運営確認の対象です。")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else {
                    ForEach(model.evidenceGroups) { group in
                        DisputeEvidenceGroupView(group: group)
                    }
                }
            }

            if let resolutionSummary = model.resolutionSummary {
                Section("仲裁結果") {
                    Text(resolutionSummary)
                        .foregroundStyle(MegrumTheme.ink)
                }
            }

            Section("返信履歴") {
                if model.messages.isEmpty {
                    Text("まだ返信はありません。")
                        .font(.callout)
                        .foregroundStyle(MegrumTheme.muted)
                } else {
                    ForEach(model.messages) { message in
                        DisputeMessageRow(message: message)
                    }
                }
            }

            if model.canSubmitReply {
                Section {
                    DisputeReplyComposer(
                        draft: Binding(
                            get: { store.replyDraft },
                            set: { store.replyDraft = $0 }
                        ),
                        isSubmitting: store.isSubmittingReply,
                        onSubmit: {
                            Task {
                                await store.submitReply()
                            }
                        }
                    )
                } header: {
                    Text("反論")
                } footer: {
                    Text(model.replyCountdownText())
                }
            }

            Section {
                if model.canWithdraw {
                    Button(role: .destructive) {
                        isShowingWithdrawConfirmation = true
                    } label: {
                        Label("申告を取り下げる", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(store.isWithdrawing)
                } else if let message = model.withdrawalUnavailableText {
                    Label(message, systemImage: "lock.fill")
                        .font(.callout)
                        .foregroundStyle(MegrumTheme.muted)
                }

                Button {
                    presentedRequestKind = .late
                } label: {
                    Label(TradeRequestKind.late.title, systemImage: TradeRequestKind.late.systemImage)
                }

                Button(role: .destructive) {
                    presentedRequestKind = .cancellation
                } label: {
                    Label(TradeRequestKind.cancellation.title, systemImage: TradeRequestKind.cancellation.systemImage)
                }
            } header: {
                Text("操作")
            } footer: {
                Text("遅刻やキャンセルは取引チャット側へ反映するための独立した申請として扱います。")
            }
        }
        .scrollContentBackground(.hidden)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .disputeDetailListStyle()
    }
}

private extension View {
    @ViewBuilder
    func disputeDetailListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self
        #endif
    }
}

private struct DisputeStatusHeader: View {
    var model: DisputeDetailModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: model.status.systemImage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(model.status.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.status.displayName)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(model.ticketNo)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                statusChip(title: "受付", value: model.submittedAt.formatted(date: .abbreviated, time: .shortened))
                if model.canSubmitReply {
                    statusChip(title: "反論", value: model.replyCountdownText())
                } else if let operatorDeadlineAt = model.operatorDeadlineAt, model.status == .arbitration {
                    statusChip(title: "運営", value: operatorDeadlineAt.formatted(date: .abbreviated, time: .shortened))
                } else if let resolvedAt = model.resolvedAt, model.status == .resolved || model.status == .withdrawn {
                    statusChip(title: "完了", value: resolvedAt.formatted(date: .abbreviated, time: .shortened))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(model.statusDescription)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(MegrumTheme.ink)
                Text(model.nextActionText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.72), lineWidth: 1)
        }
    }

    private func statusChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct DisputeTimelineView: View {
    var entries: [DisputeTimelineEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        marker(for: entry)
                        if index < entries.count - 1 {
                            Rectangle()
                                .fill(lineColor(after: entry))
                                .frame(width: 2)
                                .frame(minHeight: 28)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                        Text(entry.detail)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                        if let date = entry.date {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted.opacity(0.76))
                        }
                    }
                    .padding(.bottom, index < entries.count - 1 ? 16 : 0)
                }
            }
        }
    }

    private func marker(for entry: DisputeTimelineEvent) -> some View {
        Image(systemName: markerSymbol(for: entry.state))
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(markerForeground(for: entry))
            .frame(width: 24, height: 24)
            .background(markerBackground(for: entry), in: Circle())
    }

    private func markerSymbol(for state: DisputeTimelineEventState) -> String {
        switch state {
        case .completed:
            "checkmark"
        case .current:
            "circle.fill"
        case .pending:
            "circle"
        }
    }

    private func markerForeground(for entry: DisputeTimelineEvent) -> Color {
        switch entry.state {
        case .completed, .current:
            .white
        case .pending:
            MegrumTheme.muted
        }
    }

    private func markerBackground(for entry: DisputeTimelineEvent) -> Color {
        switch entry.state {
        case .completed:
            MegrumTheme.ok
        case .current:
            entry.status.tint
        case .pending:
            MegrumTheme.muted.opacity(0.14)
        }
    }

    private func lineColor(after entry: DisputeTimelineEvent) -> Color {
        entry.state == .pending ? MegrumTheme.muted.opacity(0.18) : MegrumTheme.lavender.opacity(0.38)
    }
}

private struct DisputeMessageRow: View {
    var message: DisputeDetailMessageModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(message.senderName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
                Text(message.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(MegrumTheme.muted)
            }

            Text(message.body)
                .font(.body)
                .foregroundStyle(MegrumTheme.ink)

            if !message.photoURLs.isEmpty {
                Label("\(message.photoURLs.count)件の写真", systemImage: "photo.on.rectangle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct DisputeEvidenceGroupView: View {
    var group: DisputeEvidenceGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(group.title, systemImage: "photo.stack.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
                Text(group.ownerName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }

            ForEach(Array(group.photoURLs.enumerated()), id: \.offset) { index, url in
                if let link = URL(string: url), link.scheme != nil {
                    Link(destination: link) {
                        HStack {
                            Label("証跡写真 \(index + 1)", systemImage: "photo")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    }
                } else {
                    Label("証跡写真 \(index + 1)", systemImage: "photo")
                        .foregroundStyle(MegrumTheme.muted)
                }
            }
            .font(.callout.weight(.semibold))
        }
        .padding(.vertical, 4)
    }
}

private struct DisputeReplyComposer: View {
    @Binding var draft: DisputeReplyDraft
    var isSubmitting: Bool
    var onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $draft.body)
                .frame(minHeight: 124)
                .overlay(alignment: .topLeading) {
                    if draft.body.isEmpty {
                        Text("事実関係、到着時刻、チャットで確認できる内容を書いてください")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted.opacity(0.68))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }

            Toggle("証跡やチャット内容も確認してほしい", isOn: $draft.includesEvidenceNote)

            if let validationMessage = draft.validationMessage, !draft.normalizedBody.isEmpty {
                Text(validationMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            Button(action: onSubmit) {
                Group {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("反論を送信", systemImage: "paperplane.fill")
                    }
                }
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(MegrumTheme.lavender, in: Capsule())
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!draft.isSubmittable || isSubmitting)
            .opacity(draft.isSubmittable ? 1 : 0.45)
        }
        .padding(.vertical, 6)
    }
}

private struct TradeRequestSheet: View {
    var kind: TradeRequestKind
    var onSubmit: (TradeRequestDraft) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var draft: TradeRequestDraft
    @State private var isSubmitting = false

    init(kind: TradeRequestKind, onSubmit: @escaping (TradeRequestDraft) async -> Bool) {
        self.kind = kind
        self.onSubmit = onSubmit
        self._draft = State(initialValue: TradeRequestDraft(kind: kind))
    }

    var body: some View {
        Form {
            Section {
                Label(kind.title, systemImage: kind.systemImage)
                    .font(.headline)
                    .foregroundStyle(MegrumTheme.ink)

                if kind == .late {
                    Stepper(value: $draft.estimatedDelayMinutes, in: 5...180, step: 5) {
                        LabeledContent("遅れる見込み", value: "\(draft.estimatedDelayMinutes)分")
                    }
                }
            } footer: {
                Text(kind.acknowledgementText)
            }

            Section("理由") {
                TextEditor(text: $draft.reason)
                    .frame(minHeight: 132)
                    .overlay(alignment: .topLeading) {
                        if draft.reason.isEmpty {
                            Text(kind.reasonPlaceholder)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted.opacity(0.68))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section {
                Toggle(kind.acknowledgementText, isOn: $draft.acknowledgesImpact)
            }

            if let message = draft.systemMessageBody {
                Section("取引チャットへの反映文") {
                    Text(message)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(MegrumTheme.ink)
                }
            }
        }
        .navigationTitle(kind.title)
        .megrumInlineNavigationTitle()
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    submit()
                } label: {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("送信")
                    }
                }
                .disabled(!draft.isSubmittable || isSubmitting)
            }
        }
    }

    private func submit() {
        guard draft.isSubmittable, !isSubmitting else {
            return
        }

        Task {
            isSubmitting = true
            let sent = await onSubmit(draft)
            isSubmitting = false
            if sent {
                dismiss()
            }
        }
    }
}

#if DEBUG
@MainActor
private enum DisputeDetailPreviewData {
    enum PreviewError: LocalizedError {
        case failed

        var errorDescription: String? {
            "通信状況を確認して、もう一度お試しください。"
        }
    }

    static let submittedAt = Date(timeIntervalSince1970: 1_800)

    static var model: DisputeDetailModel {
        DisputeDetailModel(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
            proposalID: UUID(uuidString: "30000000-0000-0000-0000-000000000101")!,
            ticketNo: "DPT-260531-ABCDEF12",
            status: .replyWindow,
            category: .noshow,
            reporterName: "あなた",
            respondentName: "相手",
            factMemo: "待ち合わせ時刻を過ぎても到着連絡がありませんでした。",
            submittedAt: submittedAt,
            replyDeadlineAt: submittedAt.addingTimeInterval(86_400),
            messages: [
                DisputeDetailMessageModel(
                    id: UUID(uuidString: "30000000-0000-0000-0000-000000000201")!,
                    senderName: "相手",
                    body: "到着予定は取引チャットで共有済みです。",
                    createdAt: submittedAt.addingTimeInterval(1_200)
                )
            ]
        )
    }

    static func store(state: DisputeDetailLoadState) -> DisputeDetailStore {
        DisputeDetailStore(
            initialState: state,
            detail: {
                switch state {
                case .loading:
                    try await Task.sleep(nanoseconds: 30_000_000_000)
                    return model
                case .failed:
                    throw PreviewError.failed
                case .empty:
                    return nil
                default:
                    return model
                }
            },
            reply: { draft in
                let message = DisputeDetailMessageModel(
                    senderName: "あなた",
                    body: draft.normalizedBody,
                    createdAt: submittedAt.addingTimeInterval(1_800)
                )
                return model.replacing(messages: model.messages + [message])
            },
            withdraw: {
                model.replacing(
                    status: .withdrawn,
                    resolvedAt: submittedAt.addingTimeInterval(2_400),
                    resolutionSummary: "申告は取り下げられました。"
                )
            }
        )
    }
}

struct DisputeDetailScreen_Previews: PreviewProvider {
    @MainActor
    static var previews: some View {
        Group {
            NavigationStack {
                DisputeDetailScreen(store: DisputeDetailPreviewData.store(state: .loading))
            }
            .previewDisplayName("Loading")

            NavigationStack {
                DisputeDetailScreen(store: DisputeDetailPreviewData.store(state: .loaded(DisputeDetailPreviewData.model)))
            }
            .previewDisplayName("Reply / Withdraw")

            NavigationStack {
                DisputeDetailScreen(store: DisputeDetailPreviewData.store(state: .empty))
            }
            .previewDisplayName("Empty")

            NavigationStack {
                DisputeDetailScreen(store: DisputeDetailPreviewData.store(state: .failed("通信状況を確認して、もう一度お試しください。")))
            }
            .previewDisplayName("Error")
        }
    }
}
#endif
