import Foundation
import MegrumCore

public extension PreviewMegrumRepository {
    func loadMessages(proposalID: UUID, limit: Int) async throws -> [TradeMessage] {
        NativePreviewData.messages[proposalID] ?? []
    }

    func sendMessage(_ input: TradeMessageCreateInput) async throws -> TradeMessage {
        TradeMessage(
            id: UUID(),
            proposalID: input.proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .text,
            body: input.body
        )
    }

    func sendPhotoMessage(_ input: TradePhotoMessageCreateInput) async throws -> TradeMessage {
        let photoURL = try await PreviewTradePhotoLocalStore.shared.storeChatPhoto(input)
        return TradeMessage(
            id: UUID(),
            proposalID: input.proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: input.messageType,
            body: input.body.nilIfBlank,
            photoURL: photoURL
        )
    }

    func sendSystemMessage(proposalID: UUID, body: String) async throws -> TradeMessage {
        TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .system,
            body: body
        )
    }

    func sendLateNoticeMessage(
        proposalID: UUID,
        lateMinutes: Int,
        reason: String,
        note: String?
    ) async throws -> TradeMessage {
        let normalizedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedReason.isEmpty else {
            throw MegrumRepositoryError.unsupportedMutation
        }
        let normalizedNote = note.nilIfBlank
        let body = "\(Self.lateMinutesLabel(lateMinutes))遅れる旨が通知されました\n理由：\(normalizedReason)\(normalizedNote.map { "\n\($0)" } ?? "")"
        var meta = [
            "action": "late_notice",
            "notified_by": NativePreviewData.viewerID.uuidString.lowercased(),
            "late_minutes": "\(lateMinutes)",
            "reason": normalizedReason
        ]
        if let normalizedNote {
            meta["note"] = normalizedNote
        }
        return TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .system,
            body: body,
            meta: meta
        )
    }

    func sendCancelRequestMessage(
        proposalID: UUID,
        reason: String,
        note: String?
    ) async throws -> TradeMessage {
        let normalizedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedReason.isEmpty else {
            throw MegrumRepositoryError.unsupportedMutation
        }
        let normalizedNote = note.nilIfBlank
        let body = "取引キャンセルが申請されました\n理由：\(normalizedReason)\(normalizedNote.map { "\n\($0)" } ?? "")"
        var meta = [
            "action": "cancel_requested",
            "requested_by": NativePreviewData.viewerID.uuidString.lowercased(),
            "reason": normalizedReason
        ]
        if let normalizedNote {
            meta["note"] = normalizedNote
        }
        return TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .system,
            body: body,
            meta: meta
        )
    }

    func sendLocationMessage(proposalID: UUID, latitude: Double, longitude: Double, label: String, body: String?) async throws -> TradeMessage {
        TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .location,
            body: body.nilIfBlank ?? label,
            locationLatitude: latitude,
            locationLongitude: longitude,
            locationLabel: label
        )
    }

    func sendArrivalStatusMessage(proposalID: UUID, status: TradeArrivalStatus, body: String?) async throws -> TradeMessage {
        TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .arrivalStatus,
            body: body.nilIfBlank ?? status.defaultBody,
            meta: ["status": status.rawValue]
        )
    }

    private static func lateMinutesLabel(_ minutes: Int) -> String {
        switch minutes {
        case 60:
            "1時間"
        case 90:
            "1時間以上"
        default:
            "\(minutes)分"
        }
    }
}
