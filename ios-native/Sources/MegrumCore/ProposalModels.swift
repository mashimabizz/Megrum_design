import Foundation

public enum ProposalMatchType: String, Codable, Sendable, CaseIterable, Identifiable {
    case perfect
    case forward
    case backward

    public var id: String { rawValue }
}

public struct ProposalMeetupInput: Equatable, Codable, Hashable, Sendable {
    public var startAt: Date
    public var endAt: Date
    public var placeName: String
    public var latitude: Double
    public var longitude: Double

    public init(
        startAt: Date,
        endAt: Date,
        placeName: String,
        latitude: Double,
        longitude: Double
    ) {
        self.startAt = startAt
        self.endAt = endAt
        self.placeName = placeName
        self.latitude = latitude
        self.longitude = longitude
    }

    public var normalizedPlaceName: String {
        placeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var isValid: Bool {
        startAt < endAt
            && !normalizedPlaceName.isEmpty
            && latitude.isFinite
            && longitude.isFinite
            && (-90...90).contains(latitude)
            && (-180...180).contains(longitude)
    }
}

public struct ProposalCreateInput: Equatable, Sendable {
    public var receiverID: UUID
    public var senderGoodsIDs: [UUID]
    public var receiverGoodsIDs: [UUID]
    public var exchangeMethod: ExchangeMethod
    public var conditionTags: [String]
    public var message: String?
    public var matchType: ProposalMatchType
    public var status: ProposalStatus
    public var meetup: ProposalMeetupInput?
    public var meetupCandidates: [ProposalMeetupInput]
    public var exposeCalendar: Bool
    public var listingID: UUID?
    public var cashOffer: Bool
    public var cashAmount: Int?
    public var cashAmountSide: ProposalCashSide?

    public init(
        receiverID: UUID,
        senderGoodsIDs: [UUID],
        receiverGoodsIDs: [UUID],
        exchangeMethod: ExchangeMethod = .mail,
        conditionTags: [String] = [],
        message: String? = nil,
        matchType: ProposalMatchType = .forward,
        status: ProposalStatus = .sent,
        meetup: ProposalMeetupInput? = nil,
        meetupCandidates: [ProposalMeetupInput] = [],
        exposeCalendar: Bool = false,
        listingID: UUID? = nil,
        cashOffer: Bool = false,
        cashAmount: Int? = nil,
        cashAmountSide: ProposalCashSide? = nil
    ) {
        self.receiverID = receiverID
        self.senderGoodsIDs = senderGoodsIDs
        self.receiverGoodsIDs = receiverGoodsIDs
        self.exchangeMethod = exchangeMethod
        self.conditionTags = conditionTags
        self.message = message
        self.matchType = matchType
        self.status = status
        self.meetup = meetup
        self.meetupCandidates = meetupCandidates
        self.exposeCalendar = exposeCalendar
        self.listingID = listingID
        self.cashAmount = cashAmount.map { max(0, $0) }.flatMap { $0 > 0 ? $0 : nil }
        self.cashAmountSide = self.cashAmount == nil ? nil : (cashAmountSide ?? Self.inferredCashSide(senderGoodsIDs: senderGoodsIDs, receiverGoodsIDs: receiverGoodsIDs))
        self.cashOffer = cashOffer || self.cashAmount != nil
    }

    public var requiresMeetupBeforeSending: Bool {
        status != .draft && (exchangeMethod == .hand || exchangeMethod == .both)
    }

    private static func inferredCashSide(senderGoodsIDs: [UUID], receiverGoodsIDs: [UUID]) -> ProposalCashSide? {
        if senderGoodsIDs.isEmpty, !receiverGoodsIDs.isEmpty {
            return .sender
        }
        if receiverGoodsIDs.isEmpty, !senderGoodsIDs.isEmpty {
            return .receiver
        }
        return nil
    }
}

public enum ProposalCashSide: String, Codable, Sendable, CaseIterable, Identifiable {
    case sender
    case receiver

    public var id: String { rawValue }
}

public struct TradeProposal: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var senderID: UUID
    public var receiverID: UUID
    public var listingID: UUID?
    public var status: ProposalStatus
    public var exchangeMethod: ExchangeMethod
    public var senderGoodsIDs: [UUID]
    public var receiverGoodsIDs: [UUID]
    public var conditionTags: [String]
    public var cashOffer: Bool
    public var cashAmount: Int?
    public var cashAmountSide: ProposalCashSide?
    public var agreedBySender: Bool
    public var agreedByReceiver: Bool
    public var evidencePhotoURL: URL?
    public var evidenceTakenAt: Date?
    public var evidenceTakenBy: UUID?
    public var approvedBySender: Bool
    public var approvedByReceiver: Bool
    public var completedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date?
    public var meetupCandidates: [ProposalMeetupInput]?

    public init(
        id: UUID,
        senderID: UUID,
        receiverID: UUID,
        listingID: UUID? = nil,
        status: ProposalStatus,
        exchangeMethod: ExchangeMethod,
        senderGoodsIDs: [UUID],
        receiverGoodsIDs: [UUID],
        conditionTags: [String] = [],
        cashOffer: Bool = false,
        cashAmount: Int? = nil,
        cashAmountSide: ProposalCashSide? = nil,
        agreedBySender: Bool = false,
        agreedByReceiver: Bool = false,
        evidencePhotoURL: URL? = nil,
        evidenceTakenAt: Date? = nil,
        evidenceTakenBy: UUID? = nil,
        approvedBySender: Bool = false,
        approvedByReceiver: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        meetupCandidates: [ProposalMeetupInput]? = nil
    ) {
        self.id = id
        self.senderID = senderID
        self.receiverID = receiverID
        self.listingID = listingID
        self.status = status
        self.exchangeMethod = exchangeMethod
        self.senderGoodsIDs = senderGoodsIDs
        self.receiverGoodsIDs = receiverGoodsIDs
        self.conditionTags = conditionTags
        self.cashOffer = cashOffer
        self.cashAmount = cashAmount.map { max(0, $0) }
        self.cashAmountSide = cashAmount == nil ? nil : cashAmountSide
        self.agreedBySender = agreedBySender
        self.agreedByReceiver = agreedByReceiver
        self.evidencePhotoURL = evidencePhotoURL
        self.evidenceTakenAt = evidenceTakenAt
        self.evidenceTakenBy = evidenceTakenBy
        self.approvedBySender = approvedBySender
        self.approvedByReceiver = approvedByReceiver
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.meetupCandidates = meetupCandidates
    }

    public func isParticipant(_ userID: UUID) -> Bool {
        senderID == userID || receiverID == userID
    }

    public func isSender(_ userID: UUID) -> Bool {
        senderID == userID
    }

    public func agreementBy(_ userID: UUID) -> Bool {
        isSender(userID) ? agreedBySender : agreedByReceiver
    }

    public func partnerAgreement(for userID: UUID) -> Bool {
        isSender(userID) ? agreedByReceiver : agreedBySender
    }

    public func approvedBy(_ userID: UUID) -> Bool {
        isSender(userID) ? approvedBySender : approvedByReceiver
    }

    public func partnerApproved(for userID: UUID) -> Bool {
        isSender(userID) ? approvedByReceiver : approvedBySender
    }

    public func partnerID(for userID: UUID) -> UUID? {
        if senderID == userID {
            return receiverID
        }
        if receiverID == userID {
            return senderID
        }
        return nil
    }

    public func goodsOffered(by userID: UUID) -> [UUID]? {
        if senderID == userID {
            return senderGoodsIDs
        }
        if receiverID == userID {
            return receiverGoodsIDs
        }
        return nil
    }

    public func goodsRequested(by userID: UUID) -> [UUID]? {
        if senderID == userID {
            return receiverGoodsIDs
        }
        if receiverID == userID {
            return senderGoodsIDs
        }
        return nil
    }

    public var allowsCounterProposal: Bool {
        [.sent, .negotiating, .agreementOneSide].contains(status)
    }

    public func canCreateCounterProposal(from userID: UUID?) -> Bool {
        guard
            let userID,
            isParticipant(userID),
            allowsCounterProposal,
            let senderGoodsIDs = goodsOffered(by: userID),
            let receiverGoodsIDs = goodsRequested(by: userID)
        else {
            return false
        }

        return !senderGoodsIDs.isEmpty && !receiverGoodsIDs.isEmpty
    }

    public func counterProposalInput(
        from userID: UUID,
        exchangeMethod: ExchangeMethod,
        conditionTags: [String],
        message: String?
    ) -> ProposalCreateInput? {
        guard
            canCreateCounterProposal(from: userID),
            let receiverID = partnerID(for: userID),
            let senderGoodsIDs = goodsOffered(by: userID),
            let receiverGoodsIDs = goodsRequested(by: userID)
        else {
            return nil
        }

        return ProposalCreateInput(
            receiverID: receiverID,
            senderGoodsIDs: senderGoodsIDs,
            receiverGoodsIDs: receiverGoodsIDs,
            exchangeMethod: exchangeMethod,
            conditionTags: conditionTags,
            message: message,
            status: .negotiating,
            listingID: listingID
        )
    }
}
