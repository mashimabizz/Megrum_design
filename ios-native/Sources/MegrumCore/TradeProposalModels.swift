import Foundation

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
    public var senderMailingAddress: TradeMailingAddressSnapshot?
    public var receiverMailingAddress: TradeMailingAddressSnapshot?
    public var senderPaymentSettings: TradePaymentSettingsSnapshot?
    public var receiverPaymentSettings: TradePaymentSettingsSnapshot?

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
        meetupCandidates: [ProposalMeetupInput]? = nil,
        senderMailingAddress: TradeMailingAddressSnapshot? = nil,
        receiverMailingAddress: TradeMailingAddressSnapshot? = nil,
        senderPaymentSettings: TradePaymentSettingsSnapshot? = nil,
        receiverPaymentSettings: TradePaymentSettingsSnapshot? = nil
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
        self.senderMailingAddress = senderMailingAddress
        self.receiverMailingAddress = receiverMailingAddress
        self.senderPaymentSettings = senderPaymentSettings
        self.receiverPaymentSettings = receiverPaymentSettings
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

    public func mailingAddressSnapshot(for userID: UUID) -> TradeMailingAddressSnapshot? {
        if senderID == userID {
            return senderMailingAddress
        }
        if receiverID == userID {
            return receiverMailingAddress
        }
        return nil
    }

    public func paymentSettingsSnapshot(for userID: UUID) -> TradePaymentSettingsSnapshot? {
        if senderID == userID {
            return senderPaymentSettings
        }
        if receiverID == userID {
            return receiverPaymentSettings
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
