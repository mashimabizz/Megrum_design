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
