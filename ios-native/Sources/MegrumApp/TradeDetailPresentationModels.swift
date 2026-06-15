import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

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
