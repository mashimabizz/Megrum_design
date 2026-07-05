import Foundation
import MegrumCore

extension SupabaseGoodsInventoryClient {
    public func makeUploadGoodsPhotoRequest(userID: UUID, path: String, data: Data, contentType: String) throws -> URLRequest {
        guard data.count <= Self.maxGoodsPhotoUploadBytes else {
            throw SupabaseGoodsInventoryClientError.imageTooLarge
        }
        return try client.makeStorageObjectUploadRequest(
            bucket: Self.goodsPhotoBucket,
            path: path,
            data: data,
            contentType: normalizedImageContentType(contentType),
            upsert: false
        )
    }

    public func makeAttachGoodsTagRequest(inventoryID: UUID, rawLabel: String) throws -> URLRequest {
        guard let normalizedLabel = normalizedTagName(rawLabel) else {
            throw SupabaseGoodsInventoryClientError.emptyTag
        }
        return try client.makeRPCRequest(
            function: "attach_inventory_tag",
            payload: AttachInventoryTagPayload(inventoryID: inventoryID, rawLabel: normalizedLabel)
        )
    }

    public func makeDetachGoodsTagRequest(inventoryID: UUID, tagID: UUID) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "detach_inventory_tag",
            payload: DetachInventoryTagPayload(inventoryID: inventoryID, tagID: tagID)
        )
    }

    public func makeLoadGoodsTagsRequest(inventoryIDs: [UUID]) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory_tags",
            queryItems: [
                URLQueryItem(name: "select", value: GoodsInventoryTagRow.select),
                URLQueryItem(
                    name: "inventory_id",
                    value: "in.(\(inventoryIDs.map { $0.uuidString.lowercased() }.sorted().joined(separator: ",")))"
                ),
                URLQueryItem(name: "order", value: "created_at.asc")
            ]
        )
    }

    public func makeLoadGoodsTypesRequest(limit: Int = 100) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_types_master",
            queryItems: [
                URLQueryItem(name: "select", value: GoodsTypeRow.select)
            ] + goodsTypeQueryItems(limit: limit)
        )
    }

    public func makeCreateGoodsEntryRequest(userID: UUID, input: GoodsEntryInput, photoURLs: [String] = []) throws -> URLRequest {
        try validateCreateInput(input)
        return try client.makeMutationRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [
                URLQueryItem(name: "select", value: GoodsInventoryRow.select)
            ],
            method: "POST",
            body: encoder.encode([GoodsEntryPayload(userID: userID, input: input, photoURLs: normalizedPhotoURLs(photoURLs))]),
            prefer: "resolution=merge-duplicates,return=representation"
        )
    }

    public func makeSearchGoodsRequest(viewerID: UUID, input: GoodsSearchInput) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [
                URLQueryItem(name: "select", value: GoodsInventoryRow.select)
            ] + searchQueryItems(viewerID: viewerID, input: input, availability: .marketAvailableQuantity)
        )
    }

    public func makeLegacySearchGoodsRequest(viewerID: UUID, input: GoodsSearchInput) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [
                URLQueryItem(name: "select", value: GoodsInventoryRow.legacySelect)
            ] + searchQueryItems(viewerID: viewerID, input: input, availability: .quantity)
        )
    }

    public func makeLoadPublicTradeGoodsRequest(userID: UUID, limit: Int = 60) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [
                URLQueryItem(name: "select", value: GoodsInventoryRow.select)
            ] + publicTradeGoodsQueryItems(userID: userID, limit: limit, availability: .marketAvailableQuantity)
        )
    }

    public func makeLegacyLoadPublicTradeGoodsRequest(userID: UUID, limit: Int = 60) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [
                URLQueryItem(name: "select", value: GoodsInventoryRow.legacySelect)
            ] + publicTradeGoodsQueryItems(userID: userID, limit: limit, availability: .quantity)
        )
    }

    public func makeArchiveGoodsItemRequest(userID: UUID, itemID: UUID) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [
                URLQueryItem(name: "select", value: GoodsInventoryRow.select)
            ] + ownedItemQueryItems(userID: userID, itemID: itemID),
            method: "PATCH",
            body: encoder.encode(GoodsInventoryStatusPayload(status: "archived")),
            prefer: "return=representation"
        )
    }

    public func makeUpdateGoodsItemRequest(userID: UUID, itemID: UUID, input: GoodsInventoryUpdateInput) throws -> URLRequest {
        let payload = try GoodsInventoryUpdatePayload(input: input)
        return try client.makeMutationRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [
                URLQueryItem(name: "select", value: GoodsInventoryRow.select)
            ] + ownedItemQueryItems(userID: userID, itemID: itemID),
            method: "PATCH",
            body: encoder.encode(payload),
            prefer: "return=representation"
        )
    }

    public func makeDeleteGoodsItemRequest(userID: UUID, itemID: UUID) throws -> URLRequest {
        try client.makeDeleteRequest(
            from: "goods_inventory",
            queryItems: ownedItemQueryItems(userID: userID, itemID: itemID)
        )
    }
}
