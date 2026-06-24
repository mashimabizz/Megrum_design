import Foundation
import MegrumCore

public enum SupabaseListingClientError: Error, Equatable, Sendable {
    case emptyUpdate
    case emptyItems
}

public struct SupabaseListingUpdateInput: Equatable, Sendable {
    public var haveItems: [ListingItemQuantity]?
    public var haveLogic: ListingLogic?
    public var haveMinimumCount: Int?
    public var status: IndividualListingStatus?
    public var note: String?
    public var clearsNote: Bool

    public init(
        haveItems: [ListingItemQuantity]? = nil,
        haveLogic: ListingLogic? = nil,
        haveMinimumCount: Int? = nil,
        status: IndividualListingStatus? = nil,
        note: String? = nil,
        clearsNote: Bool = false
    ) {
        self.haveItems = haveItems
        self.haveLogic = haveLogic
        self.haveMinimumCount = haveMinimumCount
        self.status = status
        self.note = note
        self.clearsNote = clearsNote
    }
}

public struct SupabaseListingWishOptionUpdateInput: Equatable, Sendable {
    public var wishItems: [ListingItemQuantity]?
    public var logic: ListingLogic?
    public var minimumCount: Int?
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
        minimumCount: Int? = nil,
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
        self.minimumCount = minimumCount
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
                    haveMinimumCount: input.haveMinimumCount,
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
            minimumCount: input.wishMinimumCount,
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

    public func archiveListing(userID: UUID, listingID: UUID) async throws {
        let rows: [ListingRow] = try await client.updateRows(
            in: "listings",
            values: ListingStatusPayload(status: IndividualListingStatus.closed.rawValue),
            select: ListingRow.select,
            queryItems: ownedListingQueryItems(userID: userID, listingID: listingID)
        )
        guard !rows.isEmpty else {
            throw SupabaseRESTError.unexpectedStatus(-1)
        }
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
