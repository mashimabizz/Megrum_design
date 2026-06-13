import Foundation
import MegrumCore

public enum SupabaseListingClientError: Error, Equatable, Sendable {
    case emptyUpdate
    case emptyItems
}

public struct SupabaseListingUpdateInput: Equatable, Sendable {
    public var haveItems: [ListingItemQuantity]?
    public var haveLogic: ListingLogic?
    public var status: IndividualListingStatus?
    public var note: String?
    public var clearsNote: Bool

    public init(
        haveItems: [ListingItemQuantity]? = nil,
        haveLogic: ListingLogic? = nil,
        status: IndividualListingStatus? = nil,
        note: String? = nil,
        clearsNote: Bool = false
    ) {
        self.haveItems = haveItems
        self.haveLogic = haveLogic
        self.status = status
        self.note = note
        self.clearsNote = clearsNote
    }
}

public struct SupabaseListingWishOptionUpdateInput: Equatable, Sendable {
    public var wishItems: [ListingItemQuantity]?
    public var logic: ListingLogic?
    public var exchangeType: IndividualListingExchangeType?
    public var isCashOffer: Bool?
    public var cashAmount: Int?
    public var clearsCashAmount: Bool
    public var wishGroupID: UUID?
    public var wishGoodsTypeID: UUID?
    public var clearsWishConditionIDs: Bool

    public init(
        wishItems: [ListingItemQuantity]? = nil,
        logic: ListingLogic? = nil,
        exchangeType: IndividualListingExchangeType? = nil,
        isCashOffer: Bool? = nil,
        cashAmount: Int? = nil,
        clearsCashAmount: Bool = false,
        wishGroupID: UUID? = nil,
        wishGoodsTypeID: UUID? = nil,
        clearsWishConditionIDs: Bool = false
    ) {
        self.wishItems = wishItems
        self.logic = logic
        self.exchangeType = exchangeType
        self.isCashOffer = isCashOffer
        self.cashAmount = cashAmount
        self.clearsCashAmount = clearsCashAmount
        self.wishGroupID = wishGroupID
        self.wishGoodsTypeID = wishGoodsTypeID
        self.clearsWishConditionIDs = clearsWishConditionIDs
    }
}

public final class SupabaseListingClient: @unchecked Sendable {
    private let client: SupabaseRESTClient
    private let encoder: JSONEncoder

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
        self.encoder = Self.makeEncoder()
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
        self.encoder = Self.makeEncoder()
    }

    public func loadListings(userID: UUID) async throws -> [IndividualListing] {
        try await loadListings(userID: userID, publicOnly: false)
    }

    public func loadPublicListings(userID: UUID) async throws -> [IndividualListing] {
        try await loadListings(userID: userID, publicOnly: true)
    }

    private func loadListings(userID: UUID, publicOnly: Bool) async throws -> [IndividualListing] {
        let rows: [ListingRow] = try await client.fetchRows(
            from: "listings",
            select: ListingRow.select,
            queryItems: listingQueryItems(userID: userID, publicOnly: publicOnly)
        )
        let listingIDs = rows.map(\.id)
        let optionRows: [ListingWishOptionRow] = listingIDs.isEmpty
            ? []
            : try await client.fetchRows(
                from: "listing_wish_options",
                select: ListingWishOptionRow.select,
                queryItems: optionQueryItems(listingIDs: listingIDs)
            )
        let optionsByListingID = Dictionary(grouping: optionRows.map(\.option), by: \.listingID)
        return rows.map { row in
            row.listing(options: optionsByListingID[row.id, default: []])
        }
    }

    public func createListing(userID: UUID, input: IndividualListingCreateInput) async throws -> IndividualListing {
        let listingRows: [ListingRow] = try await client.insertRows(
            into: "listings",
            values: [ListingPayload(userID: userID, input: input)],
            select: ListingRow.select
        )
        guard let listingRow = listingRows.first else {
            throw SupabaseRESTError.unexpectedStatus(-1)
        }

        let optionRows: [ListingWishOptionRow] = try await client.insertRows(
            into: "listing_wish_options",
            values: [ListingWishOptionPayload(listingID: listingRow.id, position: 1, input: input)],
            select: ListingWishOptionRow.select
        )
        return listingRow.listing(options: optionRows.map(\.option))
    }

    public func updateListing(
        userID: UUID,
        listingID: UUID,
        primaryOptionID: UUID?,
        input: IndividualListingCreateInput,
        status: IndividualListingStatus
    ) async throws -> IndividualListing {
        let listingRows: [ListingRow] = try await client.updateRows(
            in: "listings",
            values: try ListingUpdatePayload(
                input: SupabaseListingUpdateInput(
                    haveItems: input.haveItems,
                    haveLogic: input.haveLogic,
                    status: status,
                    note: input.note,
                    clearsNote: input.note == nil
                )
            ),
            select: ListingRow.select,
            queryItems: ownedListingQueryItems(userID: userID, listingID: listingID)
        )
        guard let listingRow = listingRows.first else {
            throw SupabaseRESTError.unexpectedStatus(-1)
        }

        let optionInput = SupabaseListingWishOptionUpdateInput(
            wishItems: input.wishItems,
            logic: input.wishLogic,
            exchangeType: input.exchangeType,
            isCashOffer: input.isCashOffer,
            cashAmount: input.cashAmount,
            clearsCashAmount: input.cashAmount == nil,
            wishGroupID: input.wishGroupID,
            wishGoodsTypeID: input.wishGoodsTypeID,
            clearsWishConditionIDs: input.wishGroupID == nil && input.wishGoodsTypeID == nil
        )

        let optionRows: [ListingWishOptionRow]
        if let primaryOptionID {
            optionRows = try await client.updateRows(
                in: "listing_wish_options",
                values: try ListingWishOptionUpdatePayload(input: optionInput),
                select: ListingWishOptionRow.select,
                queryItems: listingWishOptionQueryItems(listingID: listingID, optionID: primaryOptionID)
            )
        } else {
            optionRows = try await client.insertRows(
                into: "listing_wish_options",
                values: [ListingWishOptionPayload(listingID: listingID, position: 1, input: input)],
                select: ListingWishOptionRow.select
            )
        }

        return listingRow.listing(options: optionRows.map(\.option))
    }

    public func makeLoadListingsRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/listings",
            queryItems: [
                URLQueryItem(name: "select", value: ListingRow.select)
            ] + listingQueryItems(userID: userID, publicOnly: false)
        )
    }

    public func makeLoadPublicListingsRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/listings",
            queryItems: [
                URLQueryItem(name: "select", value: ListingRow.select)
            ] + listingQueryItems(userID: userID, publicOnly: true)
        )
    }

    public func makeLoadListingWishOptionsRequest(listingIDs: [UUID]) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/listing_wish_options",
            queryItems: [
                URLQueryItem(name: "select", value: ListingWishOptionRow.select)
            ] + optionQueryItems(listingIDs: listingIDs)
        )
    }

    public func makeCreateListingRequest(userID: UUID, input: IndividualListingCreateInput) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "listings",
            values: [ListingPayload(userID: userID, input: input)],
            select: ListingRow.select
        )
    }

    public func makeCreateListingWishOptionRequest(
        listingID: UUID,
        position: Int,
        input: IndividualListingCreateInput
    ) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "listing_wish_options",
            values: [ListingWishOptionPayload(listingID: listingID, position: position, input: input)],
            select: ListingWishOptionRow.select
        )
    }

    public func makeUpdateListingRequest(
        userID: UUID,
        listingID: UUID,
        input: SupabaseListingUpdateInput
    ) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/listings",
            queryItems: [
                URLQueryItem(name: "select", value: ListingRow.select)
            ] + ownedListingQueryItems(userID: userID, listingID: listingID),
            method: "PATCH",
            body: encoder.encode(ListingUpdatePayload(input: input)),
            prefer: "return=representation"
        )
    }

    public func makeUpdateListingWishOptionRequest(
        listingID: UUID,
        optionID: UUID,
        input: SupabaseListingWishOptionUpdateInput
    ) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/listing_wish_options",
            queryItems: [
                URLQueryItem(name: "select", value: ListingWishOptionRow.select)
            ] + listingWishOptionQueryItems(listingID: listingID, optionID: optionID),
            method: "PATCH",
            body: encoder.encode(ListingWishOptionUpdatePayload(input: input)),
            prefer: "return=representation"
        )
    }

    public func makeArchiveListingRequest(userID: UUID, listingID: UUID) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/listings",
            queryItems: [
                URLQueryItem(name: "select", value: ListingRow.select)
            ] + ownedListingQueryItems(userID: userID, listingID: listingID),
            method: "PATCH",
            body: encoder.encode(ListingStatusPayload(status: IndividualListingStatus.closed.rawValue)),
            prefer: "return=representation"
        )
    }

    public func makeDeleteListingRequest(userID: UUID, listingID: UUID) throws -> URLRequest {
        try client.makeDeleteRequest(
            from: "listings",
            queryItems: ownedListingQueryItems(userID: userID, listingID: listingID)
        )
    }

    private func listingQueryItems(userID: UUID, publicOnly: Bool) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: publicOnly ? "eq.active" : "in.(active,paused,matched)"),
            URLQueryItem(name: "order", value: "updated_at.desc")
        ]
    }

    private func optionQueryItems(listingIDs: [UUID]) -> [URLQueryItem] {
        let ids = listingIDs
            .map { $0.uuidString.lowercased() }
            .joined(separator: ",")
        return [
            URLQueryItem(name: "listing_id", value: "in.(\(ids))"),
            URLQueryItem(name: "order", value: "position.asc,created_at.asc")
        ]
    }

    private func ownedListingQueryItems(userID: UUID, listingID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(listingID.uuidString.lowercased())"),
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())")
        ]
    }

    private func listingWishOptionQueryItems(listingID: UUID, optionID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(optionID.uuidString.lowercased())"),
            URLQueryItem(name: "listing_id", value: "eq.\(listingID.uuidString.lowercased())")
        ]
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

private struct ListingRow: Decodable, Sendable {
    static let select = "id,user_id,have_ids,have_qtys,have_logic,have_group_id,have_goods_type_id,status,note,created_at,updated_at"

    var id: UUID
    var userId: UUID
    var haveIds: [UUID]
    var haveQtys: [Int]
    var haveLogic: String
    var haveGroupId: UUID?
    var haveGoodsTypeId: UUID?
    var status: String
    var note: String?
    var createdAt: Date?
    var updatedAt: Date?

    func listing(options: [IndividualListingWishOption]) -> IndividualListing {
        IndividualListing(
            id: id,
            ownerID: userId,
            haves: itemQuantities(ids: haveIds, quantities: haveQtys),
            haveLogic: ListingLogic(rawValue: haveLogic) ?? .all,
            haveGroupID: haveGroupId,
            haveGoodsTypeID: haveGoodsTypeId,
            status: IndividualListingStatus(rawValue: status) ?? .active,
            note: note,
            options: options.sorted { $0.position < $1.position },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private struct ListingWishOptionRow: Decodable, Sendable {
    static let select = "id,listing_id,position,wish_ids,wish_qtys,logic,exchange_type,is_cash_offer,cash_amount,wish_group_id,wish_goods_type_id,created_at,updated_at"

    var id: UUID
    var listingId: UUID
    var position: Int
    var wishIds: [UUID]
    var wishQtys: [Int]
    var logic: String
    var exchangeType: String
    var isCashOffer: Bool
    var cashAmount: Int?
    var wishGroupId: UUID?
    var wishGoodsTypeId: UUID?
    var createdAt: Date?
    var updatedAt: Date?

    var option: IndividualListingWishOption {
        IndividualListingWishOption(
            id: id,
            listingID: listingId,
            position: position,
            wishes: itemQuantities(ids: wishIds, quantities: wishQtys),
            logic: ListingLogic(rawValue: logic) ?? .one,
            exchangeType: IndividualListingExchangeType(rawValue: exchangeType) ?? .any,
            isCashOffer: isCashOffer,
            cashAmount: cashAmount,
            wishGroupID: wishGroupId,
            wishGoodsTypeID: wishGoodsTypeId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private struct ListingPayload: Encodable, Sendable {
    var userId: UUID
    var haveIds: [UUID]
    var haveQtys: [Int]
    var haveLogic: String
    var status: String
    var note: String?

    init(userID: UUID, input: IndividualListingCreateInput) {
        self.userId = userID
        self.haveIds = input.haveItems.map(\.itemID)
        self.haveQtys = input.haveItems.map { max(1, min($0.quantity, 99)) }
        self.haveLogic = input.haveLogic.rawValue
        self.status = IndividualListingStatus.active.rawValue
        self.note = input.note
    }
}

private struct ListingStatusPayload: Encodable, Sendable {
    var status: String
}

private struct ListingUpdatePayload: Encodable, Sendable {
    private var haveIds: [UUID]?
    private var haveQtys: [Int]?
    private var haveLogic: String?
    private var status: String?
    private var note: String??

    init(input: SupabaseListingUpdateInput) throws {
        if let haveItems = input.haveItems {
            guard !haveItems.isEmpty else {
                throw SupabaseListingClientError.emptyItems
            }
            self.haveIds = haveItems.map(\.itemID)
            self.haveQtys = haveItems.map { boundedListingQuantity($0.quantity) }
        }
        self.haveLogic = input.haveLogic?.rawValue
        self.status = input.status?.rawValue
        if let note = input.note {
            let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            self.note = .some(trimmed.isEmpty ? nil : trimmed)
        } else if input.clearsNote {
            self.note = .some(nil)
        }

        guard haveIds != nil || haveLogic != nil || status != nil || note != nil else {
            throw SupabaseListingClientError.emptyUpdate
        }
    }

    enum CodingKeys: String, CodingKey {
        case haveIds
        case haveQtys
        case haveLogic
        case status
        case note
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(haveIds, forKey: .haveIds)
        try container.encodeIfPresent(haveQtys, forKey: .haveQtys)
        try container.encodeIfPresent(haveLogic, forKey: .haveLogic)
        try container.encodeIfPresent(status, forKey: .status)
        if let note {
            switch note {
            case let .some(value):
                try container.encode(value, forKey: .note)
            case .none:
                try container.encodeNil(forKey: .note)
            }
        }
    }
}

private struct ListingWishOptionPayload: Encodable, Sendable {
    var listingId: UUID
    var position: Int
    var wishIds: [UUID]
    var wishQtys: [Int]
    var logic: String
    var exchangeType: String
    var isCashOffer: Bool
    var cashAmount: Int?
    var wishGroupId: UUID?
    var wishGoodsTypeId: UUID?

    init(listingID: UUID, position: Int, input: IndividualListingCreateInput) {
        self.listingId = listingID
        self.position = max(1, min(position, 5))
        self.wishIds = input.wishItems.map(\.itemID)
        self.wishQtys = input.wishItems.map { max(1, min($0.quantity, 99)) }
        self.logic = input.wishLogic.rawValue
        self.exchangeType = input.exchangeType.rawValue
        self.isCashOffer = input.isCashOffer
        self.cashAmount = input.cashAmount
        self.wishGroupId = input.wishGroupID
        self.wishGoodsTypeId = input.wishGoodsTypeID
    }
}

private struct ListingWishOptionUpdatePayload: Encodable, Sendable {
    private var wishIds: [UUID]?
    private var wishQtys: [Int]?
    private var logic: String?
    private var exchangeType: String?
    private var isCashOffer: Bool?
    private var cashAmount: Int??
    private var wishGroupId: UUID??
    private var wishGoodsTypeId: UUID??

    init(input: SupabaseListingWishOptionUpdateInput) throws {
        if let wishItems = input.wishItems {
            self.wishIds = wishItems.map(\.itemID)
            self.wishQtys = wishItems.map { boundedListingQuantity($0.quantity) }
        }
        self.logic = input.logic?.rawValue
        self.exchangeType = input.exchangeType?.rawValue
        self.isCashOffer = input.isCashOffer
        if let cashAmount = input.cashAmount {
            self.cashAmount = .some(max(0, cashAmount))
        } else if input.clearsCashAmount {
            self.cashAmount = .some(nil)
        }
        if let wishGroupID = input.wishGroupID {
            self.wishGroupId = .some(wishGroupID)
        } else if input.clearsWishConditionIDs {
            self.wishGroupId = .some(nil)
        }
        if let wishGoodsTypeID = input.wishGoodsTypeID {
            self.wishGoodsTypeId = .some(wishGoodsTypeID)
        } else if input.clearsWishConditionIDs {
            self.wishGoodsTypeId = .some(nil)
        }

        guard wishIds != nil || logic != nil || exchangeType != nil || isCashOffer != nil || cashAmount != nil || wishGroupId != nil || wishGoodsTypeId != nil else {
            throw SupabaseListingClientError.emptyUpdate
        }
    }

    enum CodingKeys: String, CodingKey {
        case wishIds
        case wishQtys
        case logic
        case exchangeType
        case isCashOffer
        case cashAmount
        case wishGroupId
        case wishGoodsTypeId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(wishIds, forKey: .wishIds)
        try container.encodeIfPresent(wishQtys, forKey: .wishQtys)
        try container.encodeIfPresent(logic, forKey: .logic)
        try container.encodeIfPresent(exchangeType, forKey: .exchangeType)
        try container.encodeIfPresent(isCashOffer, forKey: .isCashOffer)
        if let cashAmount {
            switch cashAmount {
            case let .some(value):
                try container.encode(value, forKey: .cashAmount)
            case .none:
                try container.encodeNil(forKey: .cashAmount)
            }
        }
        if let wishGroupId {
            switch wishGroupId {
            case let .some(value):
                try container.encode(value, forKey: .wishGroupId)
            case .none:
                try container.encodeNil(forKey: .wishGroupId)
            }
        }
        if let wishGoodsTypeId {
            switch wishGoodsTypeId {
            case let .some(value):
                try container.encode(value, forKey: .wishGoodsTypeId)
            case .none:
                try container.encodeNil(forKey: .wishGoodsTypeId)
            }
        }
    }
}

private func itemQuantities(ids: [UUID], quantities: [Int]) -> [ListingItemQuantity] {
    ids.enumerated().map { index, id in
        ListingItemQuantity(itemID: id, quantity: quantities.indices.contains(index) ? quantities[index] : 1)
    }
}

private func boundedListingQuantity(_ quantity: Int) -> Int {
    max(1, min(quantity, 99))
}
