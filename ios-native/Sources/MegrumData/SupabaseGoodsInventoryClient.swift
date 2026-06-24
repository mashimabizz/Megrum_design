import Foundation
import MegrumCore

public enum SupabaseGoodsInventoryClientError: Error, Equatable, Sendable {
    case emptyTitle
    case invalidQuantity
    case emptyUpdate
    case emptyTag
    case imageTooLarge
    case unsupportedImageContentType
}

public enum GoodsInventoryStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case active
    case keep
    case reserved
    case traded
    case archived

    public var id: String { rawValue }
}

public struct GoodsInventoryUpdateInput: Equatable, Sendable {
    public var title: String?
    public var groupID: UUID?
    public var characterID: UUID?
    public var clearsCharacterID: Bool
    public var goodsTypeID: UUID?
    public var quantity: Int?
    public var status: GoodsInventoryStatus?
    public var photoURLs: [String]?
    public var tagNames: [String]?

    public init(
        title: String? = nil,
        groupID: UUID? = nil,
        characterID: UUID? = nil,
        clearsCharacterID: Bool = false,
        goodsTypeID: UUID? = nil,
        quantity: Int? = nil,
        status: GoodsInventoryStatus? = nil,
        photoURLs: [String]? = nil,
        tagNames: [String]? = nil
    ) {
        self.title = title
        self.groupID = groupID
        self.characterID = characterID
        self.clearsCharacterID = clearsCharacterID
        self.goodsTypeID = goodsTypeID
        self.quantity = quantity
        self.status = status
        self.photoURLs = photoURLs
        self.tagNames = tagNames
    }
}

public final class SupabaseGoodsInventoryClient: @unchecked Sendable {
    public static let goodsPhotoBucket = "goods-photos"
    public static let maxGoodsPhotoUploadBytes = 10 * 1_024 * 1_024

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

    public func makeLoadGoodsTypesRequest(limit: Int = 40) throws -> URLRequest {
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

    private func goodsTypeQueryItems(limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "order", value: "display_order.asc,name.asc"),
            URLQueryItem(name: "limit", value: "\(boundedLimit(limit))")
        ]
    }

    private func boundedLimit(_ limit: Int, upperBound: Int = 100) -> Int {
        max(1, min(limit, upperBound))
    }

    private enum AvailabilityQueryMode {
        case marketAvailableQuantity
        case quantity

        var queryItem: URLQueryItem {
            switch self {
            case .marketAvailableQuantity:
                URLQueryItem(name: "market_available_qty", value: "gt.0")
            case .quantity:
                URLQueryItem(name: "quantity", value: "gt.0")
            }
        }
    }

    private func searchQueryItems(
        viewerID: UUID,
        input: GoodsSearchInput,
        availability: AvailabilityQueryMode
    ) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "kind", value: "eq.for_trade"),
            URLQueryItem(name: "status", value: "in.(active,reserved)"),
            availability.queryItem,
            URLQueryItem(name: "user_id", value: "neq.\(viewerID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "updated_at.desc"),
            URLQueryItem(name: "limit", value: "\(max(1, min(input.limit, 100)))")
        ]

        let query = SupabaseTextNormalizer.trimmed(input.query)
        if !query.isEmpty {
            queryItems.append(URLQueryItem(name: "title", value: "ilike.*\(query)*"))
        }
        if let groupID = input.groupID {
            queryItems.append(URLQueryItem(name: "group_id", value: "eq.\(groupID.uuidString.lowercased())"))
        }
        if let memberID = input.memberID {
            queryItems.append(URLQueryItem(name: "character_id", value: "eq.\(memberID.uuidString.lowercased())"))
        }
        if let goodsTypeID = input.goodsTypeID {
            queryItems.append(URLQueryItem(name: "goods_type_id", value: "eq.\(goodsTypeID.uuidString.lowercased())"))
        }
        return queryItems
    }

    private func publicTradeGoodsQueryItems(
        userID: UUID,
        limit: Int,
        availability: AvailabilityQueryMode
    ) -> [URLQueryItem] {
        [
            URLQueryItem(name: "kind", value: "eq.for_trade"),
            URLQueryItem(name: "status", value: "in.(active,reserved)"),
            availability.queryItem,
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "updated_at.desc"),
            URLQueryItem(name: "limit", value: "\(max(1, min(limit, 100)))")
        ]
    }

    private func ownedItemQueryItems(userID: UUID, itemID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(itemID.uuidString.lowercased())"),
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "neq.traded")
        ]
    }

    private func validateCreateInput(_ input: GoodsEntryInput) throws {
        guard !SupabaseTextNormalizer.trimmed(input.title).isEmpty else {
            throw SupabaseGoodsInventoryClientError.emptyTitle
        }
    }

    private func normalizedPhotoURLs(_ photoURLs: [String]) -> [String] {
        SupabaseTextNormalizer.nonEmptyValues(photoURLs)
    }

    private func goodsItemsWithTags(from rows: [GoodsInventoryRow]) async throws -> [GoodsItem] {
        let tagMap = try await loadGoodsTags(inventoryIDs: rows.map(\.id))
        return rows.map { row in
            var item = row.goodsItem
            item.tags = tagMap[row.id] ?? []
            return item
        }
    }

    private func syncGoodsTagsIfNeeded(inventoryID: UUID, tagNames: [String]) async throws -> [GoodsTag] {
        let desiredNames = normalizedTagNames(tagNames)
        let existingTags = try await loadGoodsTags(inventoryIDs: [inventoryID])[inventoryID] ?? []
        let existingByName = existingTags.reduce(into: [String: GoodsTag]()) { result, tag in
            let key = tag.name.lowercased()
            if result[key] == nil {
                result[key] = tag
            }
        }
        let desiredKeys = Set(desiredNames.map { $0.lowercased() })

        for tag in existingTags where !desiredKeys.contains(tag.name.lowercased()) {
            try await detachGoodsTag(inventoryID: inventoryID, tagID: tag.id)
        }

        var synced: [GoodsTag] = []
        for name in desiredNames {
            if let existing = existingByName[name.lowercased()] {
                synced.append(existing)
            } else {
                synced.append(try await attachGoodsTag(inventoryID: inventoryID, rawLabel: name))
            }
        }
        return synced
    }

    private func normalizedTagNames(_ tagNames: [String]) -> [String] {
        tagNames.reduce(into: []) { result, raw in
            guard result.count < 5, let normalized = normalizedTagName(raw) else {
                return
            }
            if !result.contains(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
                result.append(normalized)
            }
        }
    }

    private func normalizedTagName(_ raw: String) -> String? {
        let normalized = SupabaseTextNormalizer.trimmed(raw)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#＃"))
        let label = SupabaseTextNormalizer.trimmed(normalized)
        return label.isEmpty ? nil : String(label.prefix(50))
    }

    private func normalizedImageContentType(_ contentType: String) throws -> String {
        switch SupabaseTextNormalizer.trimmed(contentType).lowercased() {
        case "image/jpeg", "image/jpg":
            "image/jpeg"
        case "image/png":
            "image/png"
        case "image/webp":
            "image/webp"
        case "image/gif":
            "image/gif"
        default:
            throw SupabaseGoodsInventoryClientError.unsupportedImageContentType
        }
    }

    private func goodsPhotoPath(userID: UUID, contentType: String) -> String {
        let milliseconds = Int(Date().timeIntervalSince1970 * 1_000)
        return [
            userID.uuidString.lowercased(),
            "\(milliseconds)_\(UUID().uuidString.lowercased()).\(fileExtension(for: contentType))"
        ].joined(separator: "/")
    }

    private func fileExtension(for contentType: String) -> String {
        switch contentType {
        case "image/png":
            "png"
        case "image/webp":
            "webp"
        case "image/gif":
            "gif"
        default:
            "jpg"
        }
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
