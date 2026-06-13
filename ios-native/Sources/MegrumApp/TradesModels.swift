import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

enum TradeStageRouteRequestResolver {
    static func resolve(current: TradeStage, requested: TradeStage?) -> TradeStage {
        requested ?? current
    }
}

struct TradeDetailRoute: Identifiable, Hashable {
    var proposalID: UUID

    var id: UUID { proposalID }
}

struct TradeCardPresentation: Equatable {
    var partnerHandle: String
    var partnerInitial: String
    var updatedText: String
    var directionText: String
    var isReceived: Bool
    var statusText: String
    var responseText: String?
    var needsAction: Bool
    var tone: Tone
    var meetupSummaryText: String

    enum Tone: Equatable {
        case action
        case live
        case idle
    }

    init(
        proposal: TradeProposal,
        viewerID: UUID?,
        profilesByUserID: [UUID: PublicUserProfile],
        now: Date = .now
    ) {
        let partnerID = viewerID.flatMap { proposal.partnerID(for: $0) }
            ?? proposal.receiverID
        let handle = profilesByUserID[partnerID]?.profile.handle
            ?? Self.fallbackHandle(for: partnerID)
        self.partnerHandle = handle
        self.partnerInitial = String(handle.prefix(1)).uppercased()
        self.updatedText = Self.relativeTimeText(from: proposal.createdAt, now: now)
        self.isReceived = viewerID.map { proposal.receiverID == $0 } ?? false
        self.directionText = isReceived ? "届いた" : "送った"
        self.needsAction = Self.needsAction(proposal: proposal, viewerID: viewerID)
        self.statusText = Self.statusText(for: proposal.status, needsAction: needsAction)
        self.responseText = Self.responseText(for: proposal.status, needsAction: needsAction)
        self.tone = needsAction ? .action : (proposal.status == .agreed ? .live : .idle)
        self.meetupSummaryText = Self.meetupSummaryText(for: proposal)
    }

    private static func fallbackHandle(for userID: UUID) -> String {
        "user_\(userID.uuidString.prefix(4).lowercased())"
    }

    private static func needsAction(proposal: TradeProposal, viewerID: UUID?) -> Bool {
        guard let viewerID else {
            return false
        }
        switch proposal.status {
        case .sent:
            return proposal.receiverID == viewerID
        case .negotiating:
            return proposal.receiverID == viewerID
        case .agreementOneSide:
            return !proposal.agreementBy(viewerID)
        case .agreed:
            return false
        case .draft, .completed, .cancelled, .rejected, .expired:
            return false
        }
    }

    static func statusText(for status: ProposalStatus, needsAction: Bool) -> String {
        switch status {
        case .draft:
            return "下書き"
        case .sent:
            return needsAction ? "新着打診" : "送信済み"
        case .negotiating:
            return needsAction ? "返信が届いています" : "ネゴ中"
        case .agreementOneSide:
            return needsAction ? "合意待ち" : "相手の合意待ち"
        case .agreed:
            return needsAction ? "要確認" : "取引予定"
        case .completed:
            return "完了"
        case .cancelled:
            return "キャンセル"
        case .rejected:
            return "見送り"
        case .expired:
            return "期限切れ"
        }
    }

    static func responseText(for status: ProposalStatus, needsAction: Bool) -> String? {
        switch status {
        case .sent, .negotiating, .agreementOneSide:
            return needsAction ? "要対応" : "相手待ち"
        default:
            return nil
        }
    }

    private static func relativeTimeText(from date: Date, now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        if seconds < 60 {
            return "たった今"
        }
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)分前"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)時間前"
        }
        return "\(hours / 24)日前"
    }

    private static func meetupSummaryText(for proposal: TradeProposal) -> String {
        switch proposal.exchangeMethod {
        case .hand, .both:
            let candidates = (proposal.meetupCandidates ?? []).filter(\.isValid)
            if let primary = candidates.first {
                return TradeMeetupSummaryCopy.displayText(
                    primaryText: TradeMeetupSummaryCopy.primaryText(for: primary),
                    additionalCandidateCount: max(0, candidates.count - 1)
                )
            }
            let primary = proposal.status == .agreed
                ? "横浜アリーナ 北口 × 今日 18:15-18:45"
                : "横浜アリーナ × 候補確認中"
            return TradeMeetupSummaryCopy.displayText(primaryText: primary, additionalCandidateCount: 0)
        case .mail:
            return "住所確認中"
        }
    }
}

struct TradeMeetupSummaryCopy: Equatable, Sendable {
    static func primaryText(for candidate: ProposalMeetupInput, calendar: Calendar = .current) -> String {
        let place = candidate.normalizedPlaceName.nilIfEmpty ?? "候補確認中"
        return "\(place) × \(timeText(candidate.startAt, calendar: calendar))-\(timeText(candidate.endAt, calendar: calendar))"
    }

    static func displayText(primaryText: String, additionalCandidateCount: Int) -> String {
        let trimmed = primaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "候補確認中" : trimmed
        guard additionalCandidateCount > 0 else {
            return base
        }
        return "\(base) / 他\(additionalCandidateCount)件の候補"
    }

    private static func timeText(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}

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

enum TradeArrivalQuickAction: String, CaseIterable, Identifiable {
    case enroute
    case arrived
    case left

    var id: String { rawValue }

    var title: String {
        switch self {
        case .enroute:
            "向かっています"
        case .arrived:
            "到着しました"
        case .left:
            "離れました"
        }
    }

    var messageBody: String {
        title
    }

    var tradeStatus: TradeArrivalStatus {
        switch self {
        case .enroute:
            .enroute
        case .arrived:
            .arrived
        case .left:
            .left
        }
    }

    var systemImage: String {
        switch self {
        case .enroute:
            "figure.walk"
        case .arrived:
            "checkmark.circle.fill"
        case .left:
            "arrow.turn.up.left"
        }
    }
}

enum TradeUnavailableChatAction: String, Identifiable {
    case location
    case outfitPhoto

    var id: String { rawValue }

    var title: String {
        switch self {
        case .location:
            "現在地を共有"
        case .outfitPhoto:
            "服装写真を共有"
        }
    }

    var systemImage: String {
        switch self {
        case .location:
            "location.fill"
        case .outfitPhoto:
            "person.crop.rectangle"
        }
    }

    var description: String {
        switch self {
        case .location:
            "現在地を取得できませんでした。端末の位置情報許可を確認してください。"
        case .outfitPhoto:
            "服装写真を送信できませんでした。写真の選択権限と通信状態を確認してください。"
        }
    }
}

enum TradeAssistanceRequestKind: String, CaseIterable, Identifiable, Sendable {
    case late
    case cancel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .late:
            "遅刻を申請"
        case .cancel:
            "キャンセル申請"
        }
    }

    var systemImage: String {
        switch self {
        case .late:
            "clock.badge.exclamationmark"
        case .cancel:
            "xmark.circle"
        }
    }

    var messagePrefix: String {
        switch self {
        case .late:
            "遅刻申請"
        case .cancel:
            "キャンセル申請"
        }
    }

    var reasonPlaceholder: String {
        switch self {
        case .late:
            "遅れる理由"
        case .cancel:
            "キャンセルが必要な理由"
        }
    }

    var notePlaceholder: String {
        switch self {
        case .late:
            "待ち合わせ場所への向かい方や到着見込みなど（任意）"
        case .cancel:
            "相手への補足や代替案など（任意）"
        }
    }

    var acknowledgementText: String {
        switch self {
        case .late:
            "遅刻連絡が相手の判断材料になることを確認しました。"
        case .cancel:
            "キャンセル申請後も相手の確認が必要なことを確認しました。"
        }
    }

    var placeholder: String {
        reasonPlaceholder
    }

    var menuAccessibilityLabel: String {
        switch self {
        case .late:
            "遅刻申請を開く"
        case .cancel:
            "キャンセル申請を開く"
        }
    }

    var reasonAccessibilityLabel: String {
        switch self {
        case .late:
            "遅刻理由"
        case .cancel:
            "キャンセル理由"
        }
    }

    var noteAccessibilityLabel: String {
        switch self {
        case .late:
            "遅刻申請の補足"
        case .cancel:
            "キャンセル申請の補足"
        }
    }

    var acknowledgementAccessibilityLabel: String {
        switch self {
        case .late:
            "遅刻申請の確認事項"
        case .cancel:
            "キャンセル申請の確認事項"
        }
    }

    func systemMessageBody(from memo: String) -> String {
        let draft = TradeAssistanceRequestDraft(
            kind: self,
            reason: memo,
            acknowledgesImpact: true
        )
        return draft.systemIntent?.messageBody ?? messagePrefix
    }
}

enum TradeLateDelayBucket: Int, CaseIterable, Identifiable, Equatable, Sendable {
    case ten = 10
    case twenty = 20
    case thirty = 30
    case sixty = 60
    case ninety = 90

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .ten, .twenty, .thirty:
            "\(rawValue)分"
        case .sixty:
            "1時間"
        case .ninety:
            "1時間以上"
        }
    }

    var accessibilityLabel: String {
        "遅れる見込み \(title)"
    }
}

struct TradeAssistanceSystemIntent: Equatable, Sendable {
    enum Action: String, Equatable, Sendable {
        case lateNotice = "late_notice"
        case cancelRequested = "cancel_requested"
    }

    var kind: TradeAssistanceRequestKind
    var action: Action
    var delayBucket: TradeLateDelayBucket?
    var reason: String
    var note: String?
    var acknowledgedImpact: Bool

    var lateMinutes: Int? {
        delayBucket?.rawValue
    }

    var metadata: [String: String] {
        var values = [
            "action": action.rawValue,
            "reason": reason
        ]
        if let lateMinutes {
            values["late_minutes"] = "\(lateMinutes)"
        }
        if let note {
            values["note"] = note
        }
        return values
    }

    var messageBody: String {
        let noteSuffix = note.map { "\n\($0)" } ?? ""
        switch kind {
        case .late:
            let delay = delayBucket?.title ?? TradeLateDelayBucket.ten.title
            return "\(delay)遅れる旨が通知されました\n理由：\(reason)\(noteSuffix)"
        case .cancel:
            return "取引キャンセルが申請されました\n理由：\(reason)\(noteSuffix)"
        }
    }
}

struct TradeArrivalStatusSendIntent: Equatable, Sendable {
    var action: TradeArrivalQuickAction

    var messageType: TradeMessageType {
        .arrivalStatus
    }

    var status: TradeArrivalStatus {
        action.tradeStatus
    }

    var body: String {
        action.messageBody
    }

    var metadata: [String: String] {
        ["status": status.rawValue]
    }
}

struct TradeLocationShareIntent: Equatable, Sendable {
    var coordinate: MegrumLocationCoordinate
    var label: String = "現在地"
    var body: String?

    var messageType: TradeMessageType {
        .location
    }

    var normalizedLabel: String {
        label.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSubmittable: Bool {
        !normalizedLabel.isEmpty
            && coordinate.latitude.isFinite
            && coordinate.longitude.isFinite
            && (-90...90).contains(coordinate.latitude)
            && (-180...180).contains(coordinate.longitude)
    }
}

struct TradeOutfitPhotoSendIntent: Equatable, Sendable {
    var imageContentType: String
    var body: String = "服装写真を共有しました"

    var messageType: TradeMessageType {
        .outfitPhoto
    }
}

struct TradeChatInputAvailability: Equatable, Sendable {
    var canSendMessages: Bool

    init(status: ProposalStatus) {
        self.canSendMessages = [.sent, .negotiating, .agreementOneSide, .agreed].contains(status)
    }

    init(proposal: TradeProposal) {
        self.init(status: proposal.status)
    }
}

struct TradeDetailHeroPresentation: Equatable, Sendable {
    var partnerHandle: String
    var partnerInitial: String
    var partnerMetaText: String
    var relationText: String
    var statusLabel: String
    var agreementLabel: String
    var guidanceText: String
    var myAgreementText: String
    var partnerAgreementText: String
    var myAgreementDone: Bool
    var partnerAgreementDone: Bool
    var exchangeMethodText: String
    var summaryText: String

    init(
        proposal: TradeProposal,
        viewerID: UUID?,
        profilesByUserID: [UUID: PublicUserProfile]
    ) {
        let partnerID = viewerID.flatMap { proposal.partnerID(for: $0) }
            ?? proposal.receiverID
        let profile = profilesByUserID[partnerID]?.profile
        let handle = profile?.handle
            ?? "user_\(partnerID.uuidString.prefix(4).lowercased())"
        self.partnerHandle = handle
        self.partnerInitial = String(handle.prefix(1)).uppercased()
        self.exchangeMethodText = proposal.exchangeMethod.displayName
        let area = profile?.prefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.partnerMetaText = area.map { "未共有・\($0)" } ?? "未共有"

        let isSender = viewerID.map { proposal.senderID == $0 } ?? false
        let isReceiver = viewerID.map { proposal.receiverID == $0 } ?? false
        self.relationText = Self.relationText(isSender: isSender, isReceiver: isReceiver)

        let myAgreed = viewerID.map { proposal.agreementBy($0) } ?? false
        let partnerAgreed = viewerID.map { proposal.partnerAgreement(for: $0) } ?? false
        self.myAgreementDone = myAgreed
        self.partnerAgreementDone = partnerAgreed
        self.myAgreementText = myAgreed ? "私 合意済" : "私 未合意"
        self.partnerAgreementText = partnerAgreed ? "相手 合意済" : "相手 未合意"
        self.statusLabel = Self.statusLabel(for: proposal.status, isSender: isSender, isReceiver: isReceiver, myAgreed: myAgreed)
        self.agreementLabel = Self.agreementLabel(for: proposal.status, isSender: isSender, myAgreed: myAgreed)
        self.guidanceText = Self.guidanceText(for: proposal.status, isSender: isSender, myAgreed: myAgreed, partnerAgreed: partnerAgreed)
        self.summaryText = Self.summaryText(for: proposal, viewerID: viewerID)
    }

    private static func relationText(isSender: Bool, isReceiver: Bool) -> String {
        if isSender {
            return "あなたから送った打診"
        }
        if isReceiver {
            return "相手から届いた打診"
        }
        return "取引のやりとり"
    }

    private static func statusLabel(
        for status: ProposalStatus,
        isSender: Bool,
        isReceiver: Bool,
        myAgreed: Bool
    ) -> String {
        switch status {
        case .draft:
            return "下書き"
        case .sent:
            return isReceiver ? "新着打診" : "相手待ち"
        case .negotiating:
            return "ネゴ中"
        case .agreementOneSide:
            return myAgreed ? "相手待ち" : "合意待ち"
        case .agreed:
            return "取引予定"
        case .completed:
            return "完了"
        case .cancelled:
            return "キャンセル"
        case .rejected:
            return "見送り"
        case .expired:
            return "期限切れ"
        }
    }

    private static func agreementLabel(for status: ProposalStatus, isSender: Bool, myAgreed: Bool) -> String {
        switch status {
        case .completed:
            return "完了"
        case .agreed:
            return "合意済"
        case .agreementOneSide:
            return myAgreed ? "相手の合意待ち" : "あなたの合意待ち"
        case .negotiating:
            return "相談中"
        case .sent:
            return isSender ? "返信待ち" : "未合意"
        case .rejected:
            return "見送り"
        case .cancelled:
            return "キャンセル"
        case .expired:
            return "期限切れ"
        case .draft:
            return "下書き"
        }
    }

    private static func guidanceText(
        for status: ProposalStatus,
        isSender: Bool,
        myAgreed: Bool,
        partnerAgreed: Bool
    ) -> String {
        switch status {
        case .sent:
            return isSender
                ? "相手の返答を待っています。必要ならメッセージや再打診で条件を補足できます。"
                : "内容を確認して、承諾・再打診・見送りを選べます。"
        case .negotiating:
            return "条件を相談中です。双方が納得した内容で合意すると取引予定に進みます。"
        case .agreementOneSide:
            if myAgreed && !partnerAgreed {
                return "あなたは合意済みです。相手の合意を待っています。"
            }
            return "相手は合意済みです。この内容で進める場合は合意してください。"
        case .agreed:
            return "取引成立済みです。チャット、現在地、服装写真、証跡撮影をここから使えます。"
        case .completed:
            return "取引完了済みです。証跡と評価を確認できます。"
        case .rejected:
            return "この打診は見送りになりました。"
        case .cancelled:
            return "この取引はキャンセル済みです。"
        case .expired:
            return "この打診は期限切れです。"
        case .draft:
            return "下書きの打診です。"
        }
    }

    private static func summaryText(for proposal: TradeProposal, viewerID: UUID?) -> String {
        let offeredCount = viewerID.flatMap { proposal.goodsOffered(by: $0)?.count } ?? proposal.senderGoodsIDs.count
        let requestedCount = viewerID.flatMap { proposal.goodsRequested(by: $0)?.count } ?? proposal.receiverGoodsIDs.count
        return "ゆずる \(offeredCount)点 / 求める \(requestedCount)点"
    }
}

struct TradeEvaluationPromptState: Equatable, Sendable {
    var hasSubmittedEvaluation: Bool

    init(
        proposal: TradeProposal,
        viewerID: UUID?,
        messages: [TradeMessage],
        localSubmission: Bool = false
    ) {
        guard proposal.status == .completed, let viewerID else {
            self.hasSubmittedEvaluation = false
            return
        }
        self.hasSubmittedEvaluation = localSubmission || messages.contains { message in
            Self.isViewerEvaluationMessage(message, viewerID: viewerID)
        }
    }

    private static func isViewerEvaluationMessage(_ message: TradeMessage, viewerID: UUID) -> Bool {
        guard message.senderID == viewerID, message.messageType == .system else {
            return false
        }
        if message.meta["action"] == "evaluation_submitted" || message.meta["event_type"] == "evaluation_submitted" {
            return true
        }
        return message.body?.contains("取引評価を送信しました") == true
    }
}

struct TradeAssistanceRequestDraft: Equatable, Sendable {
    var kind: TradeAssistanceRequestKind
    var delayBucket: TradeLateDelayBucket = .ten
    var reason: String = ""
    var note: String = ""
    var acknowledgesImpact = false

    var normalizedReason: String {
        reason.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedNote: String? {
        note.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    var isSubmittable: Bool {
        !normalizedReason.isEmpty && acknowledgesImpact
    }

    var systemIntent: TradeAssistanceSystemIntent? {
        guard isSubmittable else {
            return nil
        }

        switch kind {
        case .late:
            return TradeAssistanceSystemIntent(
                kind: kind,
                action: .lateNotice,
                delayBucket: delayBucket,
                reason: normalizedReason,
                note: normalizedNote,
                acknowledgedImpact: acknowledgesImpact
            )
        case .cancel:
            return TradeAssistanceSystemIntent(
                kind: kind,
                action: .cancelRequested,
                delayBucket: nil,
                reason: normalizedReason,
                note: normalizedNote,
                acknowledgedImpact: acknowledgesImpact
            )
        }
    }
}

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

struct TradeDayOfBannerPresentation: Equatable, Sendable {
    var myArrivalText: String
    var partnerArrivalText: String
    var myOutfitText: String
    var partnerOutfitText: String
    var promptText: String

    init?(proposal: TradeProposal, messages: [TradeMessage], viewerID: UUID?) {
        guard [.agreed, .completed].contains(proposal.status) else {
            return nil
        }

        let myArrival = viewerID.flatMap { Self.latestArrivalStatus(in: messages, senderID: $0) }
        let partnerArrival = Self.latestPartnerArrivalStatus(in: messages, viewerID: viewerID)
        let hasMyOutfit = viewerID.map { Self.hasOutfitPhoto(in: messages, senderID: $0) } ?? false
        let hasPartnerOutfit = Self.hasPartnerOutfitPhoto(in: messages, viewerID: viewerID)

        self.myArrivalText = Self.arrivalText(myArrival, fallback: "未共有")
        self.partnerArrivalText = Self.arrivalText(partnerArrival, fallback: "未共有")
        self.myOutfitText = hasMyOutfit ? "共有済み" : "未共有"
        self.partnerOutfitText = hasPartnerOutfit ? "共有済み" : "未共有"
        if myArrival == .arrived {
            self.promptText = "必要に応じて現在地や服装写真を更新できます。"
        } else if hasMyOutfit {
            self.promptText = "到着したらステータスを共有すると合流しやすくなります。"
        } else {
            self.promptText = "現在地、到着、服装写真を当日の判断材料として残せます。"
        }
    }

    private static func latestArrivalStatus(in messages: [TradeMessage], senderID: UUID) -> TradeArrivalStatus? {
        messages
            .filter { $0.senderID == senderID && $0.messageType == .arrivalStatus }
            .sorted { $0.createdAt < $1.createdAt }
            .last
            .flatMap { $0.meta["status"].flatMap(TradeArrivalStatus.init(rawValue:)) }
    }

    private static func latestPartnerArrivalStatus(in messages: [TradeMessage], viewerID: UUID?) -> TradeArrivalStatus? {
        messages
            .filter { message in
                message.messageType == .arrivalStatus && viewerID.map { message.senderID != $0 } != false
            }
            .sorted { $0.createdAt < $1.createdAt }
            .last
            .flatMap { $0.meta["status"].flatMap(TradeArrivalStatus.init(rawValue:)) }
    }

    private static func hasOutfitPhoto(in messages: [TradeMessage], senderID: UUID) -> Bool {
        messages.contains { $0.senderID == senderID && $0.messageType == .outfitPhoto }
    }

    private static func hasPartnerOutfitPhoto(in messages: [TradeMessage], viewerID: UUID?) -> Bool {
        messages.contains { message in
            message.messageType == .outfitPhoto && viewerID.map { message.senderID != $0 } != false
        }
    }

    private static func arrivalText(_ status: TradeArrivalStatus?, fallback: String) -> String {
        switch status {
        case .enroute:
            "移動中"
        case .arrived:
            "到着済み"
        case .left:
            "離れました"
        case .none:
            fallback
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

struct TradeSystemMessagePresentation: Equatable, Sendable {
    var title: String
    var systemImage: String
    var body: String
    var detail: String?
    var accessibilityLabel: String {
        [title, body, detail].compactMap(\.self).joined(separator: "。")
    }

    init(message: TradeMessage) {
        let fallbackBody = message.body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "取引が更新されました"
        if let disputeSummary = TradeDisputeSummary(message: message) {
            title = "申告受付"
            systemImage = "exclamationmark.bubble"
            body = disputeSummary.body
            detail = disputeSummary.bannerBody
            return
        }

        switch message.meta["action"] {
        case .some(TradeAssistanceSystemIntent.Action.lateNotice.rawValue):
            title = "遅刻連絡"
            systemImage = "clock.badge.exclamationmark"
            body = Self.operationalBody(message: message, fallbackBody: fallbackBody)
            detail = message.meta["late_minutes"].map { "見込み：\($0)分" }
        case .some(TradeAssistanceSystemIntent.Action.cancelRequested.rawValue):
            title = "キャンセル申請"
            systemImage = "xmark.circle"
            body = Self.operationalBody(message: message, fallbackBody: fallbackBody)
            detail = nil
        case .some("cancel_approved"):
            title = "キャンセル合意"
            systemImage = "checkmark.circle"
            body = Self.operationalBody(message: message, fallbackBody: fallbackBody)
            detail = nil
        default:
            title = "取引更新"
            systemImage = "info.circle.fill"
            body = fallbackBody
            detail = nil
        }
    }

    private static func operationalBody(message: TradeMessage, fallbackBody: String) -> String {
        var lines: [String] = []
        if let reason = message.meta["reason"]?.trimmingCharacters(in: .whitespacesAndNewlines), !reason.isEmpty {
            lines.append("理由：\(reason)")
        }
        if let note = message.meta["note"]?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            lines.append("補足：\(note)")
        }
        return lines.isEmpty ? fallbackBody : lines.joined(separator: "\n")
    }
}

struct TradeCancelApprovalPrompt: Equatable, Sendable {
    var canApprove: Bool

    init(
        message: TradeMessage,
        proposal: TradeProposal,
        viewerID: UUID?,
        messages: [TradeMessage]
    ) {
        guard
            let viewerID,
            proposal.status == .agreed,
            proposal.isParticipant(viewerID),
            message.messageType == .system,
            message.meta["action"] == TradeAssistanceSystemIntent.Action.cancelRequested.rawValue
        else {
            canApprove = false
            return
        }

        let viewerKey = viewerID.uuidString.lowercased()
        let requesterKey = message.meta["requested_by"]?.lowercased()
            ?? message.senderID.uuidString.lowercased()
        let alreadyApproved = messages.contains { $0.meta["action"] == "cancel_approved" }
        canApprove = requesterKey != viewerKey && !alreadyApproved
    }
}

struct TradeOperationalMessagePresentation: Equatable, Sendable {
    var title: String
    var systemImage: String
    var body: String
    var detail: String?

    init(message: TradeMessage) {
        switch message.messageType {
        case .location:
            title = message.locationLabel?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "現在地共有"
            systemImage = "location.fill"
            body = Self.locationBody(message: message)
            detail = "位置情報"
        case .arrivalStatus:
            title = "到着ステータス"
            systemImage = "checkmark.circle.fill"
            body = message.body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "到着状況を共有しました"
            detail = message.meta["status"].flatMap(Self.arrivalDetail(for:))
        default:
            title = "取引メッセージ"
            systemImage = "info.circle.fill"
            body = message.body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "取引が更新されました"
            detail = nil
        }
    }

    private static func locationBody(message: TradeMessage) -> String {
        if let body = message.body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty {
            return body
        }
        if let latitude = message.locationLatitude, let longitude = message.locationLongitude {
            let latText = latitude.formatted(.number.precision(.fractionLength(5)))
            let lngText = longitude.formatted(.number.precision(.fractionLength(5)))
            return "緯度 \(latText) / 経度 \(lngText)"
        }
        return "現在地を共有しました"
    }

    private static func arrivalDetail(for rawStatus: String) -> String? {
        switch TradeArrivalStatus(rawValue: rawStatus) {
        case .enroute:
            "移動中"
        case .arrived:
            "到着済み"
        case .left:
            "離れました"
        case .none:
            nil
        }
    }
}

enum TradeScheduleCalendarMode: String, CaseIterable, Identifiable {
    case fiveDays
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fiveDays:
            "週"
        case .month:
            "月"
        }
    }
}

enum TradePreviewThumbnailStyle {
    static func glyph(for item: GoodsItem) -> String {
        if item.title.contains("スア") {
            return "S"
        }
        if item.title.contains("ニンニン") {
            return "N"
        }
        if item.title.contains("ジョンウ") {
            return "J"
        }
        if item.title.contains("カリナ") {
            return "K"
        }
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.first.map { String($0).uppercased() } ?? "?"
    }

    static func hue(for item: GoodsItem) -> Color {
        switch abs(item.id.hashValue) % 3 {
        case 0:
            return MegrumTheme.lavender.opacity(0.62)
        case 1:
            return MegrumTheme.sky.opacity(0.72)
        default:
            return MegrumTheme.pink.opacity(0.62)
        }
    }
}

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
