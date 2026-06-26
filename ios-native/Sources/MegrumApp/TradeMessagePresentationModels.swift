import CoreGraphics
import Foundation
import MegrumCore

struct TradeEvaluationPromptState: Equatable, Sendable {
    var hasSubmittedEvaluation: Bool
    var hasPartnerSubmittedEvaluation: Bool
    var revealedEvaluations: [TradeCompletedEvaluationPresentation]
    var shouldRevealEvaluations: Bool {
        hasSubmittedEvaluation && hasPartnerSubmittedEvaluation && revealedEvaluations.count >= 2
    }

    init(
        proposal: TradeProposal,
        viewerID: UUID?,
        messages: [TradeMessage],
        localSubmission: Bool = false
    ) {
        guard proposal.status == .completed, let viewerID else {
            self.hasSubmittedEvaluation = false
            self.hasPartnerSubmittedEvaluation = false
            self.revealedEvaluations = []
            return
        }

        let evaluationMessages = messages.filter { TradeEvaluationSystemMessage.isEvaluationNotice($0) }
        self.hasSubmittedEvaluation = localSubmission || evaluationMessages.contains { message in
            message.senderID == viewerID
        }
        self.hasPartnerSubmittedEvaluation = evaluationMessages.contains { message in
            message.senderID != viewerID
        }
        self.revealedEvaluations = messages
            .compactMap { TradeEvaluationSystemMessage.evaluation(from: $0, viewerID: viewerID) }
            .sorted { lhs, rhs in
                if lhs.isMine != rhs.isMine {
                    return lhs.isMine
                }
                return lhs.createdAt < rhs.createdAt
            }
    }
}

struct TradeCompletedEvaluationPresentation: Identifiable, Equatable, Sendable {
    var id: String { raterID?.uuidString ?? "\(displayName)-\(createdAt.timeIntervalSince1970)" }
    var raterID: UUID?
    var displayName: String
    var roleTag: String
    var stars: Int
    var comment: String?
    var createdAt: Date
    var isMine: Bool
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
            title = "取引更新"
            systemImage = "doc.viewfinder"
            body = TradeEvidenceSystemMessage.displayBody(for: message)
            detail = nil
            return
        }
        if TradeCompletionSystemMessage.isCompletionNotice(message) {
            title = "取引完了"
            systemImage = "checkmark.seal.fill"
            body = "取引が完了しました"
            detail = nil
            return
        }
        if TradeEvaluationSystemMessage.isEvaluationNotice(message) {
            title = isMine == true ? "評価を送りました" : "評価が届きました"
            systemImage = "star.bubble.fill"
            body = fallbackBody
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
    static let legacyBody = "取引証跡が追加されました"

    static func body(actorDisplayName: String?, actorHandle: String?) -> String {
        "\(actorName(displayName: actorDisplayName, handle: actorHandle))が取引証跡をアップロードしました"
    }

    static func isEvidenceNotice(_ message: TradeMessage) -> Bool {
        guard message.messageType == .system else {
            return false
        }
        let normalizedBody = message.body?.trimmingCharacters(in: .whitespacesAndNewlines)
        return message.meta["action"] == action
            || message.meta["event_type"] == action
            || normalizedBody == legacyBody
            || normalizedBody?.hasSuffix("が証跡写真を撮りました") == true
            || normalizedBody?.hasSuffix("が取引証跡をアップロードしました") == true
    }

    static func displayBody(for message: TradeMessage) -> String {
        let normalizedBody = message.body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        guard normalizedBody != legacyBody else {
            return "取引証跡が追加されました"
        }
        return normalizedBody ?? "取引証跡が追加されました"
    }
}

enum TradeCompletionSystemMessage {
    static let action = "trade_completed"
    static let body = "取引が完了しました"

    static func isCompletionNotice(_ message: TradeMessage) -> Bool {
        message.messageType == .system
            && (
                message.meta["action"] == action
                    || message.meta["event_type"] == action
                    || message.body?.trimmingCharacters(in: .whitespacesAndNewlines) == body
                    || message.body?.trimmingCharacters(in: .whitespacesAndNewlines) == "両者が承認しました。取引完了"
            )
    }
}

enum TradeEvaluationSystemMessage {
    static let action = "evaluation_submitted"
    private static let legacyBody = "取引評価を送信しました"

    static func body(actorDisplayName: String?, actorHandle: String?) -> String {
        "\(actorName(displayName: actorDisplayName, handle: actorHandle))の評価が完了しました"
    }

    static func isEvaluationNotice(_ message: TradeMessage) -> Bool {
        guard message.messageType == .system else {
            return false
        }
        let normalizedBody = message.body?.trimmingCharacters(in: .whitespacesAndNewlines)
        return message.meta["action"] == action
            || message.meta["event_type"] == action
            || normalizedBody == legacyBody
            || normalizedBody == "評価が完了しました"
            || normalizedBody?.hasSuffix("の評価が完了しました") == true
    }

    static func evaluation(from message: TradeMessage, viewerID: UUID) -> TradeCompletedEvaluationPresentation? {
        guard isEvaluationNotice(message), let starsText = message.meta["stars"], let stars = Int(starsText) else {
            return nil
        }
        let isMine = message.senderID == viewerID
        let displayName = normalized(message.meta["rater_display_name"])
            ?? normalized(message.meta["rater_handle"]).map { "@\($0)" }
            ?? (isMine ? "あなた" : "相手")
        return TradeCompletedEvaluationPresentation(
            raterID: message.senderID,
            displayName: displayName,
            roleTag: isMine ? "あなた" : "相手",
            stars: min(max(stars, 1), 5),
            comment: normalized(message.meta["comment"]),
            createdAt: message.createdAt,
            isMine: isMine
        )
    }

    private static func normalized(_ value: String?) -> String? {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
    }
}

private func actorName(displayName: String?, handle: String?) -> String {
    displayName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        ?? handle?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank.map { "@\($0)" }
        ?? "ユーザー"
}

enum TradeCounterProposalSystemMessage {
    private static let counterProposalSuffix = "が条件を変えて再出品しました"
    private static let legacyBody = "再打診しました"

    static func body(actorDisplayName: String?, actorHandle: String?) -> String {
        let actorName = normalized(actorDisplayName)
            ?? normalized(actorHandle).map { "@\($0)" }
            ?? "ユーザー"
        return "\(actorName)が条件を変えて再出品しました"
    }

    static func isCounterProposalNotice(_ message: TradeMessage) -> Bool {
        guard message.messageType == .system, let body = normalized(message.body) else {
            return false
        }
        return body.hasSuffix(counterProposalSuffix) || body == legacyBody
    }

    private static func normalized(_ value: String?) -> String? {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
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

enum TradePhotoMessageLayout {
    static func isPhotoMessage(_ messageType: TradeMessageType) -> Bool {
        messageType == .photo || messageType == .outfitPhoto
    }

    static func thumbnailSize(for messageType: TradeMessageType) -> CGSize {
        switch messageType {
        case .outfitPhoto:
            CGSize(width: 142, height: 188)
        case .photo:
            CGSize(width: 150, height: 150)
        case .text, .location, .arrivalStatus, .system:
            CGSize(width: 150, height: 150)
        }
    }

    static func label(for messageType: TradeMessageType) -> String? {
        switch messageType {
        case .photo:
            "写真"
        case .outfitPhoto:
            "服装写真"
        case .text, .location, .arrivalStatus, .system:
            nil
        }
    }
}
