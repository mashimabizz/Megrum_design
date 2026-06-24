import Foundation
import MegrumCore

public extension PreviewMegrumRepository {
    func createProposal(_ input: ProposalCreateInput) async throws -> TradeProposal {
        TradeProposal(
            id: UUID(),
            senderID: NativePreviewData.viewerID,
            receiverID: input.receiverID,
            status: input.status,
            exchangeMethod: input.exchangeMethod,
            senderGoodsIDs: input.senderGoodsIDs,
            receiverGoodsIDs: input.receiverGoodsIDs,
            conditionTags: input.conditionTags,
            cashOffer: input.cashOffer,
            cashAmount: input.cashAmount,
            cashAmountSide: input.cashAmountSide,
            agreedBySender: [.sent, .negotiating, .agreementOneSide, .agreed].contains(input.status),
            agreedByReceiver: input.status == .agreed
        )
    }

    func agreeProposal(proposalID: UUID, acceptedExchangeMethod: ExchangeMethod?) async throws -> TradeProposal {
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.partnerID,
                receiverID: NativePreviewData.viewerID,
                status: .sent,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: []
            )
        let resolvedExchangeMethod = try resolvedAcceptanceExchangeMethod(for: proposal, selectedMethod: acceptedExchangeMethod)
        let agreedBySender = proposal.isSender(NativePreviewData.viewerID) ? true : (proposal.agreedBySender || proposal.status == .sent)
        let agreedByReceiver = proposal.isSender(NativePreviewData.viewerID) ? proposal.agreedByReceiver : true
        return TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: agreedBySender && agreedByReceiver ? .agreed : .agreementOneSide,
            exchangeMethod: resolvedExchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
            cashAmountSide: proposal.cashAmountSide,
            agreedBySender: agreedBySender,
            agreedByReceiver: agreedByReceiver,
            evidencePhotoURL: proposal.evidencePhotoURL,
            evidenceTakenAt: proposal.evidenceTakenAt,
            evidenceTakenBy: proposal.evidenceTakenBy,
            approvedBySender: proposal.approvedBySender,
            approvedByReceiver: proposal.approvedByReceiver,
            completedAt: proposal.completedAt,
            createdAt: proposal.createdAt
        )
    }

    func rejectProposal(proposalID: UUID) async throws -> TradeProposal {
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.partnerID,
                receiverID: NativePreviewData.viewerID,
                status: .sent,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: []
            )
        return TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: .rejected,
            exchangeMethod: proposal.exchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
            cashAmountSide: proposal.cashAmountSide,
            agreedBySender: proposal.agreedBySender,
            agreedByReceiver: proposal.agreedByReceiver,
            evidencePhotoURL: proposal.evidencePhotoURL,
            evidenceTakenAt: proposal.evidenceTakenAt,
            evidenceTakenBy: proposal.evidenceTakenBy,
            approvedBySender: proposal.approvedBySender,
            approvedByReceiver: proposal.approvedByReceiver,
            completedAt: proposal.completedAt,
            createdAt: proposal.createdAt
        )
    }

    func approveTradeCancel(proposalID: UUID) async throws -> (proposal: TradeProposal, message: TradeMessage) {
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.partnerID,
                receiverID: NativePreviewData.viewerID,
                status: .agreed,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: []
            )
        let cancelled = TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: .cancelled,
            exchangeMethod: proposal.exchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
            cashAmountSide: proposal.cashAmountSide,
            agreedBySender: proposal.agreedBySender,
            agreedByReceiver: proposal.agreedByReceiver,
            evidencePhotoURL: proposal.evidencePhotoURL,
            evidenceTakenAt: proposal.evidenceTakenAt,
            evidenceTakenBy: proposal.evidenceTakenBy,
            approvedBySender: proposal.approvedBySender,
            approvedByReceiver: proposal.approvedByReceiver,
            completedAt: proposal.completedAt,
            createdAt: proposal.createdAt
        )
        let message = TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .system,
            body: "キャンセル申請に同意しました",
            meta: [
                "action": "cancel_approved",
                "approved_by": NativePreviewData.viewerID.uuidString.lowercased()
            ]
        )
        return (cancelled, message)
    }

    func addTradeEvidence(_ input: TradeEvidenceCreateInput) async throws -> TradeProposal {
        let proposal = NativePreviewData.proposals.first { $0.id == input.proposalID }
            ?? NativePreviewData.proposals.first
            ?? TradeProposal(
                id: input.proposalID,
                senderID: NativePreviewData.viewerID,
                receiverID: NativePreviewData.partnerID,
                status: .agreed,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: []
            )
        return TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: .agreed,
            exchangeMethod: proposal.exchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
            cashAmountSide: proposal.cashAmountSide,
            agreedBySender: proposal.agreedBySender,
            agreedByReceiver: proposal.agreedByReceiver,
            evidencePhotoURL: URL(string: "https://example.com/evidence.jpg")!,
            evidenceTakenAt: .now,
            evidenceTakenBy: NativePreviewData.viewerID,
            approvedBySender: proposal.approvedBySender,
            approvedByReceiver: proposal.approvedByReceiver,
            completedAt: proposal.completedAt,
            createdAt: proposal.createdAt
        )
    }

    func approveTradeEvidence(proposalID: UUID) async throws -> TradeProposal {
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.viewerID,
                receiverID: NativePreviewData.partnerID,
                status: .agreed,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: [],
                evidencePhotoURL: URL(string: "https://example.com/evidence.jpg")!
            )
        let approvedBySender = proposal.isSender(NativePreviewData.viewerID) ? true : proposal.approvedBySender
        let approvedByReceiver = proposal.isSender(NativePreviewData.viewerID) ? proposal.approvedByReceiver : true
        return TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: approvedBySender && approvedByReceiver ? .completed : .agreed,
            exchangeMethod: proposal.exchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
            cashAmountSide: proposal.cashAmountSide,
            agreedBySender: proposal.agreedBySender,
            agreedByReceiver: proposal.agreedByReceiver,
            evidencePhotoURL: proposal.evidencePhotoURL ?? URL(string: "https://example.com/evidence.jpg")!,
            evidenceTakenAt: proposal.evidenceTakenAt ?? .now,
            evidenceTakenBy: proposal.evidenceTakenBy ?? NativePreviewData.viewerID,
            approvedBySender: approvedBySender,
            approvedByReceiver: approvedByReceiver,
            completedAt: approvedBySender && approvedByReceiver ? .now : proposal.completedAt,
            createdAt: proposal.createdAt
        )
    }

    func loadTradeEvidencePhotos(proposalID: UUID) async throws -> [TradeEvidencePhoto] {
        [
            TradeEvidencePhoto(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000e101")!,
                proposalID: proposalID,
                photoURL: URL(string: "https://picsum.photos/seed/megrum-evidence-1/640/480")!,
                position: 1,
                takenAt: .now,
                takenBy: NativePreviewData.viewerID
            ),
            TradeEvidencePhoto(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000e102")!,
                proposalID: proposalID,
                photoURL: URL(string: "https://picsum.photos/seed/megrum-evidence-2/640/480")!,
                position: 2,
                takenAt: .now.addingTimeInterval(-120),
                takenBy: NativePreviewData.partnerID
            )
        ]
    }

    func deleteTradeEvidencePhoto(proposalID: UUID, photoID: UUID) async throws -> TradeProposal {
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.viewerID,
                receiverID: NativePreviewData.partnerID,
                status: .agreed,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: []
            )
        return proposal
    }

    func submitTradeEvaluation(_ input: TradeEvaluationCreateInput) async throws -> UserEvaluation {
        UserEvaluation(
            id: UUID(),
            raterID: NativePreviewData.viewerID,
            raterHandle: NativePreviewData.viewer.handle,
            raterDisplayName: NativePreviewData.viewer.displayName,
            stars: input.stars,
            comment: input.comment
        )
    }

    func fileTradeDispute(_ input: TradeDisputeCreateInput) async throws -> TradeDisputeTicket {
        TradeDisputeTicket(
            id: UUID(),
            proposalID: input.proposalID,
            ticketNo: "DPT-260531-0001",
            status: "submitted"
        )
    }

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
        TradeMessage(
            id: UUID(),
            proposalID: input.proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: input.messageType,
            body: input.body.nilIfBlank,
            photoURL: URL(string: "https://preview.megrum.local/chat/\(UUID().uuidString.lowercased()).jpg")
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

private func resolvedAcceptanceExchangeMethod(
    for proposal: TradeProposal,
    selectedMethod: ExchangeMethod?
) throws -> ExchangeMethod {
    switch proposal.exchangeMethod {
    case .both:
        guard let selectedMethod, selectedMethod != .both else {
            throw MegrumRepositoryError.unsupportedMutation
        }
        return selectedMethod
    case .hand, .mail:
        if let selectedMethod, selectedMethod != proposal.exchangeMethod {
            throw MegrumRepositoryError.unsupportedMutation
        }
        return proposal.exchangeMethod
    }
}
