import Foundation
import MegrumCore

struct ProposalCreatePayload: Encodable, Sendable {
    var senderId: UUID
    var receiverId: UUID
    var matchType: String
    var senderHaveIds: [UUID]
    var senderHaveQtys: [Int]
    var receiverHaveIds: [UUID]
    var receiverHaveQtys: [Int]
    var message: String?
    var messageTone: String
    var status: String
    var lastActionAt: String
    var expiresAt: String?
    var exchangeMethod: String
    var optionTags: [String]
    var exposeCalendar: Bool
    var listingId: UUID?
    var cashOffer: Bool
    var cashAmount: Int?
    var cashAmountSide: String?
    var meetupStartAt: String?
    var meetupEndAt: String?
    var meetupPlaceName: String?
    var meetupLat: Double?
    var meetupLng: Double?
    var meetupCandidates: [ProposalMeetupCandidatePayload]
    var agreedBySender: Bool

    init(senderID: UUID, input: ProposalCreateInput, now: Date) throws {
        let meetupCandidates = Self.normalizedMeetupCandidates(for: input)
        let meetup = meetupCandidates.first
        if input.requiresMeetupBeforeSending {
            guard meetup?.isValid == true else {
                throw SupabaseProposalClientError.missingMeetup
            }
        }
        let expiresAt = Calendar(identifier: .gregorian).date(byAdding: .day, value: 7, to: now)
        self.senderId = senderID
        self.receiverId = input.receiverID
        self.matchType = input.matchType.rawValue
        self.senderHaveIds = input.senderGoodsIDs
        self.senderHaveQtys = input.senderGoodsIDs.map { _ in 1 }
        self.receiverHaveIds = input.receiverGoodsIDs
        self.receiverHaveQtys = input.receiverGoodsIDs.map { _ in 1 }
        self.message = SupabaseTextNormalizer.optional(input.message)
        self.messageTone = "standard"
        self.status = input.status.rawValue
        self.lastActionAt = SupabaseDateEncoding.isoTimestamp(now)
        self.expiresAt = input.status == .draft ? nil : expiresAt.map(SupabaseDateEncoding.isoTimestamp)
        self.exchangeMethod = input.exchangeMethod.rawValue
        self.optionTags = input.conditionTags
        self.exposeCalendar = input.requiresMeetupBeforeSending && input.exposeCalendar
        self.listingId = input.listingID
        self.cashOffer = input.cashOffer
        self.cashAmount = input.cashAmount
        self.cashAmountSide = input.cashAmountSide?.rawValue
        self.meetupStartAt = meetup.map { SupabaseDateEncoding.isoTimestamp($0.startAt) }
        self.meetupEndAt = meetup.map { SupabaseDateEncoding.isoTimestamp($0.endAt) }
        self.meetupPlaceName = SupabaseTextNormalizer.optional(meetup?.normalizedPlaceName)
        self.meetupLat = meetup?.latitude
        self.meetupLng = meetup?.longitude
        self.meetupCandidates = meetupCandidates.map(ProposalMeetupCandidatePayload.init)
        self.agreedBySender = [.sent, .negotiating, .agreementOneSide, .agreed].contains(input.status)
    }

    private static func normalizedMeetupCandidates(for input: ProposalCreateInput) -> [ProposalMeetupInput] {
        var candidates = input.meetupCandidates.filter(\.isValid)
        if let meetup = input.meetup, meetup.isValid {
            candidates.removeAll { $0.isSameMeetup(as: meetup) }
            candidates.insert(meetup, at: 0)
        }
        return Array(candidates.prefix(3))
    }
}

struct ProposalMeetupCandidatePayload: Encodable, Sendable {
    var startAt: String
    var endAt: String
    var placeName: String
    var lat: Double
    var lng: Double
    var mode: String

    init(meetup: ProposalMeetupInput) {
        self.startAt = SupabaseDateEncoding.isoTimestamp(meetup.startAt)
        self.endAt = SupabaseDateEncoding.isoTimestamp(meetup.endAt)
        self.placeName = meetup.normalizedPlaceName
        self.lat = meetup.latitude
        self.lng = meetup.longitude
        self.mode = "scheduled"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode([
            "startAt": ProposalMeetupCandidateValue.string(startAt),
            "endAt": .string(endAt),
            "placeName": .string(placeName),
            "lat": .double(lat),
            "lng": .double(lng),
            "mode": .string(mode)
        ])
    }
}

enum ProposalMeetupCandidateValue: Encodable, Sendable {
    case string(String)
    case double(Double)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        }
    }
}

extension ProposalMeetupInput {
    func isSameMeetup(as other: ProposalMeetupInput) -> Bool {
        startAt == other.startAt
            && endAt == other.endAt
            && normalizedPlaceName == other.normalizedPlaceName
            && latitude == other.latitude
            && longitude == other.longitude
    }
}

struct ProposalResponseRPCPayload: Encodable, Sendable {
    var pProposalID: UUID
    var pAction: String
    var pAcceptedExchangeMethod: String?

    init(proposalID: UUID, action: String, acceptedExchangeMethod: String?) {
        self.pProposalID = proposalID
        self.pAction = action
        self.pAcceptedExchangeMethod = acceptedExchangeMethod
    }
}

struct ProposalApprovalRPCPayload: Encodable, Sendable {
    var pProposalID: UUID
    var pPhotoID: UUID?

    init(proposalID: UUID, photoID: UUID? = nil) {
        self.pProposalID = proposalID
        self.pPhotoID = photoID
    }
}

struct ProposalAgreementUpdatePayload: Encodable, Sendable {
    var agreedBySender: Bool
    var agreedByReceiver: Bool
    var status: String
    var exchangeMethod: String?
}

struct ProposalStatusUpdatePayload: Encodable, Sendable {
    var status: String
}

struct ProposalEvidenceUpdatePayload: Encodable, Sendable {
    var evidencePhotoURL: String?
    var evidenceTakenAt: String
    var evidenceTakenBy: UUID
    var approvedBySender: Bool
    var approvedByReceiver: Bool
}

struct ProposalEvidenceReplacementPayload: Encodable, Sendable {
    var photo: TradeEvidencePhoto?

    enum CodingKeys: String, CodingKey {
        case evidencePhotoURL
        case evidenceTakenAt
        case evidenceTakenBy
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let photo {
            try container.encode(photo.photoURL.absoluteString, forKey: .evidencePhotoURL)
            if let takenAt = photo.takenAt {
                try container.encode(SupabaseDateEncoding.isoTimestamp(takenAt), forKey: .evidenceTakenAt)
            } else {
                try container.encodeNil(forKey: .evidenceTakenAt)
            }
            try container.encode(photo.takenBy, forKey: .evidenceTakenBy)
        } else {
            try container.encodeNil(forKey: .evidencePhotoURL)
            try container.encodeNil(forKey: .evidenceTakenAt)
            try container.encodeNil(forKey: .evidenceTakenBy)
        }
    }
}

struct ProposalApprovalUpdatePayload: Encodable, Sendable {
    var approvedBySender: Bool
    var approvedByReceiver: Bool
    var status: String?
    var completedAt: String?
}

struct ProposalCancelApprovalUpdatePayload: Encodable, Sendable {
    var status = ProposalStatus.cancelled.rawValue
    var lastActionAt: String

    init(now: Date) {
        self.lastActionAt = SupabaseDateEncoding.isoTimestamp(now)
    }
}

struct EvidencePhotoInsertPayload: Encodable, Sendable {
    var proposalID: UUID
    var photoURL: String
    var position: Int
    var takenAt: String
    var takenBy: UUID
    var approvedBySender: Bool
    var approvedByReceiver: Bool
}

struct LegacyEvidencePhotoInsertPayload: Encodable, Sendable {
    var proposalID: UUID
    var photoURL: String
    var position: Int
    var takenAt: String
    var takenBy: UUID
}

struct ProposalSystemMessagePayload: Encodable, Sendable {
    var proposalID: UUID
    var senderID: UUID
    var messageType = TradeMessageType.system.rawValue
    var body: String
    var meta: [String: ProposalSystemMessageMetadataValue]?

    init(proposalID: UUID, senderID: UUID, body: String, meta: [String: String] = [:]) {
        self.proposalID = proposalID
        self.senderID = senderID
        self.body = body
        self.meta = meta.isEmpty ? nil : meta.mapValues(ProposalSystemMessageMetadataValue.string)
    }
}

enum ProposalSystemMessageMetadataValue: Encodable, Sendable {
    case string(String)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        }
    }
}

struct EvaluationInsertPayload: Encodable, Sendable {
    var proposalID: UUID
    var raterID: UUID
    var rateeID: UUID
    var stars: Int
    var comment: String?
}
