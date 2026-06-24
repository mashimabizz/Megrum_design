import Foundation
import MegrumCore

public final class SupabaseGoodsInventoryClient: @unchecked Sendable {
    public static let goodsPhotoBucket = "goods-photos"
    public static let maxGoodsPhotoUploadBytes = 10 * 1_024 * 1_024

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

    public func loadGoodsTypes(limit: Int = 40) async throws -> [GoodsType] {
        let rows: [GoodsTypeRow] = try await client.fetchRows(
            from: "goods_types_master",
            select: GoodsTypeRow.select,
            queryItems: goodsTypeQueryItems(limit: limit)
        )
        return rows.map(\.goodsType)
    }

    public func createGoodsEntry(userID: UUID, input: GoodsEntryInput, photoURLs: [String] = []) async throws -> GoodsItem {
        try validateCreateInput(input)
        let normalizedPhotoURLs = normalizedPhotoURLs(photoURLs)
        let rows: [GoodsInventoryRow] = try await client.upsertRows(
            into: "goods_inventory",
            values: [GoodsEntryPayload(userID: userID, input: input, photoURLs: normalizedPhotoURLs)],
            select: GoodsInventoryRow.select
        )
        var item = rows.first?.goodsItem ?? GoodsItem(
            id: UUID(),
            ownerID: userID,
            kind: input.kind,
            status: input.status ?? .active,
            groupID: input.groupID,
            memberID: input.memberID,
            goodsTypeID: input.goodsTypeID,
            title: SupabaseTextNormalizer.trimmed(input.title),
            imageURL: normalizedPhotoURLs.compactMap(URL.init(string:)).first,
            quantity: max(1, min(input.quantity, 999))
        )
        let tags = try await syncGoodsTagsIfNeeded(inventoryID: item.id, tagNames: input.tagNames)
        item.tags = tags
        return item
    }

    public func searchGoods(viewerID: UUID, input: GoodsSearchInput) async throws -> [GoodsItem] {
        let rows: [GoodsInventoryRow]
        do {
            rows = try await client.fetchRows(
                from: "goods_inventory",
                select: GoodsInventoryRow.select,
                queryItems: searchQueryItems(viewerID: viewerID, input: input, availability: .marketAvailableQuantity)
            )
        } catch let error as SupabaseRESTError where error == .unexpectedStatus(400) {
            rows = try await client.fetchRows(
                from: "goods_inventory",
                select: GoodsInventoryRow.legacySelect,
                queryItems: searchQueryItems(viewerID: viewerID, input: input, availability: .quantity)
            )
        }
        return try await goodsItemsWithTags(from: rows)
    }

    public func loadPublicTradeGoods(userID: UUID, limit: Int = 60) async throws -> [GoodsItem] {
        let rows: [GoodsInventoryRow]
        do {
            rows = try await client.fetchRows(
                from: "goods_inventory",
                select: GoodsInventoryRow.select,
                queryItems: publicTradeGoodsQueryItems(
                    userID: userID,
                    limit: limit,
                    availability: .marketAvailableQuantity
                )
            )
        } catch let error as SupabaseRESTError where error == .unexpectedStatus(400) {
            rows = try await client.fetchRows(
                from: "goods_inventory",
                select: GoodsInventoryRow.legacySelect,
                queryItems: publicTradeGoodsQueryItems(userID: userID, limit: limit, availability: .quantity)
            )
        }
        return try await goodsItemsWithTags(from: rows)
    }

    public func archiveGoodsItem(userID: UUID, itemID: UUID) async throws -> GoodsItem? {
        let rows: [GoodsInventoryRow] = try await client.updateRows(
            in: "goods_inventory",
            values: GoodsInventoryStatusPayload(status: "archived"),
            select: GoodsInventoryRow.select,
            queryItems: ownedItemQueryItems(userID: userID, itemID: itemID)
        )
        guard let row = rows.first else {
            return nil
        }
        return try await goodsItemsWithTags(from: [row]).first
    }

    public func updateGoodsItem(userID: UUID, itemID: UUID, input: GoodsInventoryUpdateInput) async throws -> GoodsItem? {
        let payload = try GoodsInventoryUpdatePayload(input: input)
        let rows: [GoodsInventoryRow] = try await client.updateRows(
            in: "goods_inventory",
            values: payload,
            select: GoodsInventoryRow.select,
            queryItems: ownedItemQueryItems(userID: userID, itemID: itemID)
        )
        guard var item = rows.first?.goodsItem else {
            return nil
        }
        if let tagNames = input.tagNames {
            item.tags = try await syncGoodsTagsIfNeeded(inventoryID: item.id, tagNames: tagNames)
        } else {
            item.tags = try await loadGoodsTags(inventoryIDs: [item.id])[item.id] ?? []
        }
        return item
    }

    public func deleteGoodsItem(userID: UUID, itemID: UUID) async throws {
        try await client.deleteRows(
            from: "goods_inventory",
            queryItems: ownedItemQueryItems(userID: userID, itemID: itemID)
        )
    }

    public func uploadGoodsPhoto(userID: UUID, imageData: Data, contentType: String) async throws -> String {
        guard imageData.count <= Self.maxGoodsPhotoUploadBytes else {
            throw SupabaseGoodsInventoryClientError.imageTooLarge
        }
        let normalizedContentType = try normalizedImageContentType(contentType)
        let path = goodsPhotoPath(userID: userID, contentType: normalizedContentType)
        try await client.uploadObject(
            bucket: Self.goodsPhotoBucket,
            path: path,
            data: imageData,
            contentType: normalizedContentType,
            upsert: false
        )
        return try client.publicStorageObjectURL(bucket: Self.goodsPhotoBucket, path: path).absoluteString
    }

    public func loadGoodsTags(inventoryIDs: [UUID]) async throws -> [UUID: [GoodsTag]] {
        let ids = Array(Set(inventoryIDs))
        guard !ids.isEmpty else {
            return [:]
        }
        let rows: [GoodsInventoryTagRow] = try await client.fetchRows(
            from: "goods_inventory_tags",
            select: GoodsInventoryTagRow.select,
            queryItems: [
                URLQueryItem(
                    name: "inventory_id",
                    value: "in.(\(ids.map { $0.uuidString.lowercased() }.sorted().joined(separator: ",")))"
                ),
                URLQueryItem(name: "order", value: "created_at.asc")
            ]
        )
        return rows.reduce(into: [:]) { result, row in
            guard let tag = row.tag?.goodsTag else {
                return
            }
            result[row.inventoryId, default: []].append(tag)
        }
    }

    @discardableResult
    public func attachGoodsTag(inventoryID: UUID, rawLabel: String) async throws -> GoodsTag {
        guard let normalizedLabel = normalizedTagName(rawLabel) else {
            throw SupabaseGoodsInventoryClientError.emptyTag
        }
        let tagID: UUID = try await client.rpcValue(
            function: "attach_inventory_tag",
            payload: AttachInventoryTagPayload(inventoryID: inventoryID, rawLabel: normalizedLabel)
        )
        return GoodsTag(id: tagID, name: normalizedLabel)
    }

    public func detachGoodsTag(inventoryID: UUID, tagID: UUID) async throws {
        try await client.rpcVoid(
            function: "detach_inventory_tag",
            payload: DetachInventoryTagPayload(inventoryID: inventoryID, tagID: tagID)
        )
    }
}
