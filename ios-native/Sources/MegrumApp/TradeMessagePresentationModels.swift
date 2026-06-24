import Foundation
import MegrumCore

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

    init(message: TradeMessage, isMine: Bool? = nil) {
        let fallbackBody = message.body.nilIfBlank ?? "取引が更新されました"
        if let disputeSummary = TradeDisputeSummary(message: message) {
            title = "申告受付"
            systemImage = "exclamationmark.bubble"
            body = disputeSummary.body
            detail = disputeSummary.bannerBody
            return
        }
        if TradeEvidenceSystemMessage.isEvidenceNotice(message) {
            title = isMine == true ? "取引証跡を送りました" : "取引証跡が届きました"
            systemImage = "doc.viewfinder"
            body = "タップして証跡写真を確認"
            detail = nil
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

enum TradeEvidenceSystemMessage {
    static let action = "evidence_added"
    private static let legacyBody = "取引証跡が追加されました"

    static func isEvidenceNotice(_ message: TradeMessage) -> Bool {
        message.messageType == .system
            && (message.meta["action"] == action || message.body?.trimmingCharacters(in: .whitespacesAndNewlines) == legacyBody)
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
            title = message.locationLabel.nilIfBlank ?? "現在地共有"
            systemImage = "location.fill"
            body = Self.locationBody(message: message)
            detail = "位置情報"
        case .arrivalStatus:
            title = "到着ステータス"
            systemImage = "checkmark.circle.fill"
            body = message.body.nilIfBlank ?? "到着状況を共有しました"
            detail = message.meta["status"].flatMap(Self.arrivalDetail(for:))
        default:
            title = "取引メッセージ"
            systemImage = "info.circle.fill"
            body = message.body.nilIfBlank ?? "取引が更新されました"
            detail = nil
        }
    }

    private static func locationBody(message: TradeMessage) -> String {
        if let body = message.body.nilIfBlank {
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
