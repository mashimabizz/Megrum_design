import Foundation
import MegrumCore

public enum AccountDeletionReason: String, CaseIterable, Identifiable, Sendable, Codable {
    case notUsing = "not_using"
    case hardToUse = "hard_to_use"
    case tradeConcern = "trade_concern"
    case foundAlternative = "found_alternative"
    case privacyConcern = "privacy_concern"
    case other

    public var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notUsing:
            "使う機会がなくなった"
        case .hardToUse:
            "使い方がわかりにくかった"
        case .tradeConcern:
            "取引に不安があった"
        case .foundAlternative:
            "他のサービスを使う"
        case .privacyConcern:
            "プライバシーが気になった"
        case .other:
            "その他"
        }
    }
}

public struct AccountDeletionRequestInput: Equatable, Sendable {
    public var reasons: [AccountDeletionReason]
    public var note: String?

    public init(reasons: [AccountDeletionReason], note: String? = nil) {
        self.reasons = Self.normalizedReasons(reasons)
        self.note = note
    }

    public var normalized: AccountDeletionRequestInput {
        AccountDeletionRequestInput(
            reasons: Self.normalizedReasons(reasons),
            note: AccountDeletionDraftValidator.normalizedNote(note ?? "")
        )
    }

    private static func normalizedReasons(_ reasons: [AccountDeletionReason]) -> [AccountDeletionReason] {
        reasons.reduce(into: []) { result, reason in
            if !result.contains(reason) {
                result.append(reason)
            }
        }
    }
}

public struct AccountDeletionRequestResult: Equatable, Sendable {
    public var deletionScheduledAt: Date?

    public init(deletionScheduledAt: Date? = nil) {
        self.deletionScheduledAt = deletionScheduledAt
    }
}

enum AccountDeletionDraftValidator {
    static let noteMaxLength = 500
    static let missingReasonMessage = "退会理由を1つ以上選択してください"
    static let noteTooLongMessage = "メモは500文字以内で入力してください"

    static func validationMessage(reasons: [AccountDeletionReason], note: String) -> String? {
        if AccountDeletionRequestInput(reasons: reasons, note: note).reasons.isEmpty {
            return missingReasonMessage
        }
        if note.trimmingCharacters(in: .whitespacesAndNewlines).count > noteMaxLength {
            return noteTooLongMessage
        }
        return nil
    }

    static func normalizedNote(_ value: String) -> String? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return nil
        }
        return String(normalized.prefix(noteMaxLength))
    }
}

enum AccountDeletionEligibility {
    static let ongoingStatuses: Set<ProposalStatus> = [
        .sent,
        .negotiating,
        .agreementOneSide,
        .agreed
    ]

    static func ongoingProposals(
        in proposals: [TradeProposal],
        viewerID: UUID?
    ) -> [TradeProposal] {
        proposals.filter { proposal in
            if let viewerID, !proposal.isParticipant(viewerID) {
                return false
            }
            return ongoingStatuses.contains(proposal.status)
        }
    }

    static func canRequestDeletion(
        proposals: [TradeProposal],
        viewerID: UUID?
    ) -> Bool {
        ongoingProposals(in: proposals, viewerID: viewerID).isEmpty
    }
}
