import Foundation
import MegrumCore

extension SupabaseListingClient {
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
}
