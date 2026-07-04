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
    public var haveIsCashOffer: Bool?
    public var haveCashAmount: Int?
    public var clearsHaveCashAmount: Bool
    public var status: IndividualListingStatus?
    public var note: String?
    public var clearsNote: Bool

    public init(
        haveItems: [ListingItemQuantity]? = nil,
        haveLogic: ListingLogic? = nil,
        haveMinimumCount: Int? = nil,
        haveIsCashOffer: Bool? = nil,
        haveCashAmount: Int? = nil,
        clearsHaveCashAmount: Bool = false,
        status: IndividualListingStatus? = nil,
        note: String? = nil,
        clearsNote: Bool = false
    ) {
        self.haveItems = haveItems
        self.haveLogic = haveLogic
        self.haveMinimumCount = haveMinimumCount
        self.haveIsCashOffer = haveIsCashOffer
        self.haveCashAmount = haveCashAmount
        self.clearsHaveCashAmount = clearsHaveCashAmount
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
    let client: SupabaseRESTClient
    let encoder: JSONEncoder

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

        var optionPayloads = [ListingWishOptionPayload(listingID: listingRow.id, position: 1, input: input)]
        for (index, option) in input.additionalOptions.prefix(4).enumerated() {
            optionPayloads.append(
                ListingWishOptionPayload(listingID: listingRow.id, position: index + 2, option: option)
            )
        }
        let optionRows: [ListingWishOptionRow] = try await client.insertRows(
            into: "listing_wish_options",
            values: optionPayloads,
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
                    haveIsCashOffer: input.haveIsCashOffer,
                    haveCashAmount: input.haveCashAmount,
                    clearsHaveCashAmount: input.haveCashAmount == nil,
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

        var optionRows: [ListingWishOptionRow]
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

        // 編集後の選択肢一覧で全置換する：先頭以外の既存選択肢を消し、
        // additionalOptions を position 2〜 で入れ直す。
        if let primaryRowID = optionRows.first?.id {
            try await client.deleteRows(
                from: "listing_wish_options",
                queryItems: [
                    URLQueryItem(name: "listing_id", value: "eq.\(listingID.uuidString.lowercased())"),
                    URLQueryItem(name: "id", value: "neq.\(primaryRowID.uuidString.lowercased())")
                ]
            )
        }
        if !input.additionalOptions.isEmpty {
            let additionalPayloads = input.additionalOptions.prefix(4).enumerated().map { index, option in
                ListingWishOptionPayload(listingID: listingID, position: index + 2, option: option)
            }
            let additionalRows: [ListingWishOptionRow] = try await client.insertRows(
                into: "listing_wish_options",
                values: Array(additionalPayloads),
                select: ListingWishOptionRow.select
            )
            optionRows.append(contentsOf: additionalRows)
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
}
