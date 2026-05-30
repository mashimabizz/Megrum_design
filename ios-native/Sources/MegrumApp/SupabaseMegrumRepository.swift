import Foundation
import MegrumCore
import MegrumData

public struct SupabaseMegrumRepository: MegrumRepository {
    private let client: SupabaseRESTClient
    private let viewerID: UUID

    public init(client: SupabaseRESTClient, viewerID: UUID) {
        self.client = client
        self.viewerID = viewerID
    }

    public func loadInitialSnapshot() async throws -> MegrumAppSnapshot {
        async let viewer = loadViewer()
        async let inventory = loadGoods(kind: "for_trade")
        async let wishes = loadWishes()
        async let proposals = loadProposals()

        return MegrumAppSnapshot(
            viewer: try await viewer,
            inventory: try await inventory,
            wishes: try await wishes,
            proposals: try await proposals,
            grooms: [],
            threads: []
        )
    }

    private func loadViewer() async throws -> UserProfile {
        let rows: [UserRow] = try await client.fetchRows(
            from: "users",
            select: "id,handle,display_name,avatar_url,primary_area,account_status",
            queryItems: [
                URLQueryItem(name: "id", value: "eq.\(viewerID.uuidString.lowercased())"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        return rows.first?.profile ?? UserProfile(
            id: viewerID,
            handle: "megrum",
            displayName: "Megrum",
            prefecture: nil,
            accountStatus: .onboarding
        )
    }

    public func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        let rows: [UserRow] = try await client.updateRows(
            in: "users",
            values: UserProfileUpdatePayload(
                displayName: input.displayName,
                primaryArea: input.prefecture,
                accountStatus: AccountStatus.active.rawValue
            ),
            select: "id,handle,display_name,avatar_url,primary_area,account_status",
            queryItems: [
                URLQueryItem(name: "id", value: "eq.\(viewerID.uuidString.lowercased())"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        return rows.first?.profile ?? UserProfile(
            id: viewerID,
            handle: "megrum",
            displayName: input.displayName,
            prefecture: input.prefecture,
            accountStatus: .active
        )
    }

    private func loadGoods(kind: String) async throws -> [GoodsItem] {
        let rows: [GoodsInventoryRow] = try await client.fetchRows(
            from: "goods_inventory",
            select: "id,user_id,group_id,character_id,goods_type_id,title,photo_urls,quantity",
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(viewerID.uuidString.lowercased())"),
                URLQueryItem(name: "kind", value: "eq.\(kind)"),
                URLQueryItem(name: "status", value: kind == "for_trade" ? "eq.active" : "neq.archived")
            ]
        )
        return rows.compactMap(\.goodsItem)
    }

    private func loadWishes() async throws -> [WishItem] {
        let rows: [GoodsInventoryRow] = try await client.fetchRows(
            from: "goods_inventory",
            select: "id,user_id,group_id,character_id,goods_type_id,title",
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(viewerID.uuidString.lowercased())"),
                URLQueryItem(name: "kind", value: "eq.wanted"),
                URLQueryItem(name: "status", value: "neq.archived")
            ]
        )
        return rows.compactMap(\.wishItem)
    }

    private func loadProposals() async throws -> [TradeProposal] {
        let viewer = viewerID.uuidString.lowercased()
        let rows: [ProposalRow] = try await client.fetchRows(
            from: "proposals",
            select: "id,sender_id,receiver_id,status,exchange_method,sender_have_ids,receiver_have_ids,condition_tags,created_at",
            queryItems: [
                URLQueryItem(name: "or", value: "(sender_id.eq.\(viewer),receiver_id.eq.\(viewer))"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ]
        )
        return rows.compactMap(\.proposal)
    }
}

private struct UserRow: Decodable, Sendable {
    var id: UUID
    var handle: String?
    var displayName: String?
    var avatarUrl: URL?
    var primaryArea: String?
    var accountStatus: String?

    var profile: UserProfile {
        UserProfile(
            id: id,
            handle: handle ?? "unknown",
            displayName: displayName ?? handle ?? "Megrum",
            avatarURL: avatarUrl,
            prefecture: primaryArea,
            accountStatus: AccountStatus(rawValue: accountStatus ?? "") ?? .active
        )
    }
}

private struct UserProfileUpdatePayload: Encodable, Sendable {
    var displayName: String
    var primaryArea: String?
    var accountStatus: String
}

private struct GoodsInventoryRow: Decodable, Sendable {
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
            quantity: quantity ?? 1
        )
    }

    var wishItem: WishItem {
        WishItem(
            id: id,
            ownerID: userId,
            groupID: groupId,
            memberID: characterId,
            goodsTypeID: goodsTypeId,
            title: title,
            tags: []
        )
    }
}

private struct ProposalRow: Decodable, Sendable {
    var id: UUID
    var senderId: UUID
    var receiverId: UUID
    var status: String
    var exchangeMethod: String?
    var senderHaveIds: [UUID]?
    var receiverHaveIds: [UUID]?
    var conditionTags: [String]?
    var createdAt: Date?

    var proposal: TradeProposal? {
        guard let proposalStatus = ProposalStatus(rawValue: status) else {
            return nil
        }
        return TradeProposal(
            id: id,
            senderID: senderId,
            receiverID: receiverId,
            status: proposalStatus,
            exchangeMethod: ExchangeMethod(rawValue: exchangeMethod ?? "hand") ?? .hand,
            senderGoodsIDs: senderHaveIds ?? [],
            receiverGoodsIDs: receiverHaveIds ?? [],
            conditionTags: conditionTags ?? [],
            createdAt: createdAt ?? .now
        )
    }
}
