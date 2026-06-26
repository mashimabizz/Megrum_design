import Foundation
import MegrumCore

struct ProposalRow: Decodable, Sendable {
    static let select = [
        "id",
        "sender_id",
        "receiver_id",
        "listing_id",
        "status",
        "exchange_method",
        "sender_mailing_address",
        "receiver_mailing_address",
        "sender_payment_settings",
        "receiver_payment_settings",
        "sender_have_ids",
        "receiver_have_ids",
        "cash_offer",
        "cash_amount",
        "cash_amount_side",
        "option_tags",
        "agreed_by_sender",
        "agreed_by_receiver",
        "evidence_photo_url",
        "evidence_taken_at",
        "evidence_taken_by",
        "approved_by_sender",
        "approved_by_receiver",
        "completed_at",
        "meetup_start_at",
        "meetup_end_at",
        "meetup_place_name",
        "meetup_lat",
        "meetup_lng",
        "meetup_candidates",
        "created_at",
        "updated_at"
    ].joined(separator: ",")

    static let legacySelect = [
        "id",
        "sender_id",
        "receiver_id",
        "listing_id",
        "status",
        "exchange_method",
        "sender_mailing_address",
        "receiver_mailing_address",
        "sender_have_ids",
        "receiver_have_ids",
        "cash_offer",
        "cash_amount",
        "cash_amount_side",
        "option_tags",
        "agreed_by_sender",
        "agreed_by_receiver",
        "evidence_photo_url",
        "evidence_taken_at",
        "evidence_taken_by",
        "approved_by_sender",
        "approved_by_receiver",
        "completed_at",
        "meetup_start_at",
        "meetup_end_at",
        "meetup_place_name",
        "meetup_lat",
        "meetup_lng",
        "meetup_candidates",
        "created_at",
        "updated_at"
    ].joined(separator: ",")

    var id: UUID
    var senderId: UUID
    var receiverId: UUID
    var listingId: UUID?
    var status: String
    var exchangeMethod: String?
    var senderMailingAddress: TradeMailingAddressSnapshot?
    var receiverMailingAddress: TradeMailingAddressSnapshot?
    var senderPaymentSettings: TradePaymentSettingsSnapshot?
    var receiverPaymentSettings: TradePaymentSettingsSnapshot?
    var senderHaveIds: [UUID]?
    var receiverHaveIds: [UUID]?
    var cashOffer: Bool?
    var cashAmount: Int?
    var cashAmountSide: String?
    var optionTags: [String]?
    var agreedBySender: Bool?
    var agreedByReceiver: Bool?
    var evidencePhotoUrl: String?
    var evidenceTakenAt: Date?
    var evidenceTakenBy: UUID?
    var approvedBySender: Bool?
    var approvedByReceiver: Bool?
    var completedAt: Date?
    var meetupStartAt: Date?
    var meetupEndAt: Date?
    var meetupPlaceName: String?
    var meetupLat: Double?
    var meetupLng: Double?
    var meetupCandidates: [ProposalMeetupCandidateRow]?
    var createdAt: Date?
    var updatedAt: Date?

    var proposal: TradeProposal? {
        guard let proposalStatus = ProposalStatus(rawValue: status) else {
            return nil
        }
        return TradeProposal(
            id: id,
            senderID: senderId,
            receiverID: receiverId,
            listingID: listingId,
            status: proposalStatus,
            exchangeMethod: ExchangeMethod(rawValue: exchangeMethod ?? "hand") ?? .hand,
            senderGoodsIDs: senderHaveIds ?? [],
            receiverGoodsIDs: receiverHaveIds ?? [],
            conditionTags: optionTags ?? [],
            cashOffer: cashOffer ?? false,
            cashAmount: cashAmount,
            cashAmountSide: cashAmountSide.flatMap(ProposalCashSide.init(rawValue:)),
            agreedBySender: agreedBySender ?? false,
            agreedByReceiver: agreedByReceiver ?? false,
            evidencePhotoURL: evidencePhotoUrl.flatMap(URL.init(string:)),
            evidenceTakenAt: evidenceTakenAt,
            evidenceTakenBy: evidenceTakenBy,
            approvedBySender: approvedBySender ?? false,
            approvedByReceiver: approvedByReceiver ?? false,
            completedAt: completedAt,
            createdAt: createdAt ?? .now,
            updatedAt: updatedAt,
            meetupCandidates: normalizedMeetupCandidates,
            senderMailingAddress: senderMailingAddress,
            receiverMailingAddress: receiverMailingAddress,
            senderPaymentSettings: senderPaymentSettings,
            receiverPaymentSettings: receiverPaymentSettings
        )
    }

    private var mirroredMeetup: ProposalMeetupInput? {
        guard let meetupStartAt,
              let meetupEndAt,
              let placeName = SupabaseTextNormalizer.optional(meetupPlaceName),
              let meetupLat,
              let meetupLng
        else {
            return nil
        }
        let meetup = ProposalMeetupInput(
            startAt: meetupStartAt,
            endAt: meetupEndAt,
            placeName: placeName,
            latitude: meetupLat,
            longitude: meetupLng
        )
        return meetup.isValid ? meetup : nil
    }

    private var normalizedMeetupCandidates: [ProposalMeetupInput]? {
        var candidates = meetupCandidates?
            .map(\.meetupInput)
            .filter(\.isValid) ?? []
        if let mirroredMeetup {
            candidates.removeAll { $0.isSameMeetup(as: mirroredMeetup) }
            candidates.insert(mirroredMeetup, at: 0)
        }
        return candidates.isEmpty ? nil : Array(candidates.prefix(3))
    }
}

struct ProposalMeetupCandidateRow: Decodable, Sendable {
    var startAt: Date
    var endAt: Date
    var placeName: String
    var lat: Double
    var lng: Double

    var meetupInput: ProposalMeetupInput {
        ProposalMeetupInput(
            startAt: startAt,
            endAt: endAt,
            placeName: placeName,
            latitude: lat,
            longitude: lng
        )
    }
}

struct EvidencePhotoAckRow: Decodable, Sendable {
    var id: UUID
}

struct EvidencePhotoPositionRow: Decodable, Sendable {
    var position: Int?
}

struct EvidencePhotoRow: Decodable, Sendable {
    static let select = "id,proposal_id,photo_url,position,taken_at,taken_by,approved_by_sender,approved_by_receiver"
    static let legacySelect = "id,proposal_id,photo_url,position,taken_at,taken_by"

    var id: UUID
    var proposalId: UUID
    var photoUrl: String
    var position: Int?
    var takenAt: Date?
    var takenBy: UUID
    var approvedBySender: Bool?
    var approvedByReceiver: Bool?

    var evidencePhoto: TradeEvidencePhoto? {
        guard let url = URL(string: photoUrl) else {
            return nil
        }
        return TradeEvidencePhoto(
            id: id,
            proposalID: proposalId,
            photoURL: url,
            position: position ?? 1,
            takenAt: takenAt,
            takenBy: takenBy,
            approvedBySender: approvedBySender ?? false,
            approvedByReceiver: approvedByReceiver ?? false
        )
    }
}

struct ProposalSystemMessageAckRow: Decodable, Sendable {
    var id: UUID
}

struct EvaluationInsertRow: Decodable, Sendable {
    var id: UUID
    var raterId: UUID
    var stars: Int
    var comment: String?
    var createdAt: Date?

    var evaluation: UserEvaluation {
        UserEvaluation(
            id: id,
            raterID: raterId,
            raterHandle: "me",
            raterDisplayName: "自分",
            stars: stars,
            comment: comment,
            createdAt: createdAt ?? .now
        )
    }
}
