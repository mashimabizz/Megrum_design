import Foundation
import MegrumCore

public final class SupabaseListingClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
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

private struct ListingWishOptionPayload: Encodable, Sendable {
    var listingId: UUID
    var position: Int
    var wishIds: [UUID]
    var wishQtys: [Int]
    var logic: String
    var exchangeType: String
    var isCashOffer: Bool
    var cashAmount: Int?

    init(listingID: UUID, position: Int, input: IndividualListingCreateInput) {
        self.listingId = listingID
        self.position = max(1, min(position, 5))
        self.wishIds = input.wishItems.map(\.itemID)
        self.wishQtys = input.wishItems.map { max(1, min($0.quantity, 99)) }
        self.logic = input.wishLogic.rawValue
        self.exchangeType = input.exchangeType.rawValue
        self.isCashOffer = false
        self.cashAmount = nil
    }
}

private func itemQuantities(ids: [UUID], quantities: [Int]) -> [ListingItemQuantity] {
    ids.enumerated().map { index, id in
        ListingItemQuantity(itemID: id, quantity: quantities.indices.contains(index) ? quantities[index] : 1)
    }
}
