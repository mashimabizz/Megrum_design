import Foundation
import MegrumCore

public enum SupabaseGoodsInventoryClientError: Error, Equatable, Sendable {
    case emptyTitle
    case invalidQuantity
    case emptyUpdate
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

    public init(
        title: String? = nil,
        groupID: UUID? = nil,
        characterID: UUID? = nil,
        clearsCharacterID: Bool = false,
        goodsTypeID: UUID? = nil,
        quantity: Int? = nil,
        status: GoodsInventoryStatus? = nil,
        photoURLs: [String]? = nil
    ) {
        self.title = title
        self.groupID = groupID
        self.characterID = characterID
        self.clearsCharacterID = clearsCharacterID
        self.goodsTypeID = goodsTypeID
        self.quantity = quantity
        self.status = status
        self.photoURLs = photoURLs
    }
}

public final class SupabaseGoodsInventoryClient: @unchecked Sendable {
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
        return rows.first?.goodsItem ?? GoodsItem(
            id: UUID(),
            ownerID: userID,
            groupID: input.groupID,
            memberID: input.memberID,
            goodsTypeID: input.goodsTypeID,
            title: input.title.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: normalizedPhotoURLs.compactMap(URL.init(string:)).first,
            quantity: max(1, min(input.quantity, 999))
        )
    }

    public func searchGoods(viewerID: UUID, input: GoodsSearchInput) async throws -> [GoodsItem] {
        let rows: [GoodsInventoryRow] = try await client.fetchRows(
            from: "goods_inventory",
            select: GoodsInventoryRow.select,
            queryItems: searchQueryItems(viewerID: viewerID, input: input)
        )
        return rows.map(\.goodsItem)
    }

    public func loadPublicTradeGoods(userID: UUID, limit: Int = 60) async throws -> [GoodsItem] {
        let rows: [GoodsInventoryRow] = try await client.fetchRows(
            from: "goods_inventory",
            select: GoodsInventoryRow.select,
            queryItems: publicTradeGoodsQueryItems(userID: userID, limit: limit)
        )
        return rows.map(\.goodsItem)
    }

    public func archiveGoodsItem(userID: UUID, itemID: UUID) async throws -> GoodsItem? {
        let rows: [GoodsInventoryRow] = try await client.updateRows(
            in: "goods_inventory",
            values: GoodsInventoryStatusPayload(status: "archived"),
            select: GoodsInventoryRow.select,
            queryItems: ownedItemQueryItems(userID: userID, itemID: itemID)
        )
        return rows.first?.goodsItem
    }

    public func updateGoodsItem(userID: UUID, itemID: UUID, input: GoodsInventoryUpdateInput) async throws -> GoodsItem? {
        let payload = try GoodsInventoryUpdatePayload(input: input)
        let rows: [GoodsInventoryRow] = try await client.updateRows(
            in: "goods_inventory",
            values: payload,
            select: GoodsInventoryRow.select,
            queryItems: ownedItemQueryItems(userID: userID, itemID: itemID)
        )
        return rows.first?.goodsItem
    }

    public func deleteGoodsItem(userID: UUID, itemID: UUID) async throws {
        try await client.deleteRows(
            from: "goods_inventory",
            queryItems: ownedItemQueryItems(userID: userID, itemID: itemID)
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
            ] + searchQueryItems(viewerID: viewerID, input: input)
        )
    }

    public func makeLoadPublicTradeGoodsRequest(userID: UUID, limit: Int = 60) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [
                URLQueryItem(name: "select", value: GoodsInventoryRow.select)
            ] + publicTradeGoodsQueryItems(userID: userID, limit: limit)
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

    private func searchQueryItems(viewerID: UUID, input: GoodsSearchInput) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "kind", value: "eq.for_trade"),
            URLQueryItem(name: "status", value: "in.(active,reserved)"),
            URLQueryItem(name: "user_id", value: "neq.\(viewerID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "updated_at.desc"),
            URLQueryItem(name: "limit", value: "\(max(1, min(input.limit, 100)))")
        ]

        let query = input.query.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private func publicTradeGoodsQueryItems(userID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "kind", value: "eq.for_trade"),
            URLQueryItem(name: "status", value: "in.(active,reserved)"),
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
        guard !input.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SupabaseGoodsInventoryClientError.emptyTitle
        }
    }

    private func normalizedPhotoURLs(_ photoURLs: [String]) -> [String] {
        photoURLs.compactMap { url in
            let normalized = url.trimmingCharacters(in: .whitespacesAndNewlines)
            return normalized.isEmpty ? nil : normalized
        }
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

private struct GoodsTypeRow: Decodable, Sendable {
    static let select = "id,name,category,display_order"

    var id: UUID
    var name: String
    var category: String?
    var displayOrder: Int?

    var goodsType: GoodsType {
        GoodsType(
            id: id,
            name: name,
            category: category,
            displayOrder: displayOrder ?? 0
        )
    }
}

private struct GoodsInventoryRow: Decodable, Sendable {
    static let select = "id,user_id,group_id,character_id,goods_type_id,title,photo_urls,quantity"

    var id: UUID
    var userId: UUID
    var groupId: UUID?
    var characterId: UUID?
    var goodsTypeId: UUID?
    var title: String
    var photoUrls: [String]?
    var quantity: Int?

    var goodsItem: GoodsItem {
        GoodsItem(
            id: id,
            ownerID: userId,
            groupID: groupId,
            memberID: characterId,
            goodsTypeID: goodsTypeId,
            title: title,
            imageURL: photoUrls?.compactMap(URL.init(string:)).first,
            tags: [],
            quantity: max(1, quantity ?? 1)
        )
    }
}

private struct GoodsEntryPayload: Encodable, Sendable {
    var userId: UUID
    var kind: String
    var groupId: UUID
    var characterId: UUID?
    var goodsTypeId: UUID
    var title: String
    var condition: String?
    var priority: String?
    var flexLevel: String?
    var exchangeType: String
    var quantity: Int
    var status: String?
    var photoUrls: [String]

    init(userID: UUID, input: GoodsEntryInput, photoURLs: [String] = []) {
        self.userId = userID
        self.kind = input.kind.inventoryKind
        self.groupId = input.groupID
        self.characterId = input.memberID
        self.goodsTypeId = input.goodsTypeID
        self.title = input.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.condition = input.kind == .inventory ? "good" : nil
        self.priority = input.kind == .wish ? "second" : nil
        self.flexLevel = input.kind == .wish ? "normal" : nil
        self.exchangeType = "any"
        self.quantity = max(1, min(input.quantity, 999))
        self.status = input.status?.rawValue
        self.photoUrls = photoURLs
    }
}

private struct GoodsInventoryStatusPayload: Encodable, Sendable {
    var status: String
}

private struct GoodsInventoryUpdatePayload: Encodable, Sendable {
    private var title: String?
    private var groupId: UUID?
    private var characterId: UUID??
    private var goodsTypeId: UUID?
    private var quantity: Int?
    private var status: String?
    private var photoUrls: [String]?

    init(input: GoodsInventoryUpdateInput) throws {
        if let title = input.title {
            let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else {
                throw SupabaseGoodsInventoryClientError.emptyTitle
            }
            self.title = normalized
        }
        if let quantity = input.quantity {
            guard (1...999).contains(quantity) else {
                throw SupabaseGoodsInventoryClientError.invalidQuantity
            }
            self.quantity = quantity
        }

        self.groupId = input.groupID
        self.goodsTypeId = input.goodsTypeID
        self.status = input.status?.rawValue
        self.photoUrls = input.photoURLs.map { urls in
            urls.compactMap { url in
                let normalized = url.trimmingCharacters(in: .whitespacesAndNewlines)
                return normalized.isEmpty ? nil : normalized
            }
        }

        if let characterID = input.characterID {
            self.characterId = .some(.some(characterID))
        } else if input.clearsCharacterID {
            self.characterId = .some(nil)
        }

        guard title != nil
            || groupId != nil
            || characterId != nil
            || goodsTypeId != nil
            || quantity != nil
            || status != nil
            || photoUrls != nil
        else {
            throw SupabaseGoodsInventoryClientError.emptyUpdate
        }
    }

    enum CodingKeys: String, CodingKey {
        case title
        case groupId
        case characterId
        case goodsTypeId
        case quantity
        case status
        case photoUrls
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(groupId, forKey: .groupId)
        if let characterId {
            switch characterId {
            case let .some(id):
                try container.encode(id, forKey: .characterId)
            case .none:
                try container.encodeNil(forKey: .characterId)
            }
        }
        try container.encodeIfPresent(goodsTypeId, forKey: .goodsTypeId)
        try container.encodeIfPresent(quantity, forKey: .quantity)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(photoUrls, forKey: .photoUrls)
    }
}
