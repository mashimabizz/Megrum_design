import Foundation
import MegrumCore
import MegrumData

public struct SupabaseMegrumRepository: MegrumRepository {
    private let client: SupabaseRESTClient
    private let oshiClient: SupabaseOshiClient
    private let goodsInventoryClient: SupabaseGoodsInventoryClient
    private let mailingAddressClient: SupabaseMailingAddressClient
    private let postalCodeAddressClient: PostalCodeAddressClient
    private let blockClient: SupabaseBlockClient
    private let notificationClient: SupabaseNotificationClient
    private let proposalClient: SupabaseProposalClient
    private let messageClient: SupabaseMessageClient
    private let viewerID: UUID

    public init(client: SupabaseRESTClient, viewerID: UUID) {
        self.client = client
        self.oshiClient = SupabaseOshiClient(client: client)
        self.goodsInventoryClient = SupabaseGoodsInventoryClient(client: client)
        self.mailingAddressClient = SupabaseMailingAddressClient(client: client)
        self.postalCodeAddressClient = PostalCodeAddressClient()
        self.blockClient = SupabaseBlockClient(client: client)
        self.notificationClient = SupabaseNotificationClient(client: client)
        self.proposalClient = SupabaseProposalClient(client: client)
        self.messageClient = SupabaseMessageClient(client: client)
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

    public func loadOshiGroups(searchText: String?, limit: Int) async throws -> [OshiGroup] {
        try await oshiClient.loadGroups(searchText: searchText, limit: limit)
    }

    public func loadOshiCharacters(groupID: UUID, limit: Int) async throws -> [OshiCharacter] {
        try await oshiClient.loadCharacters(groupID: groupID, limit: limit)
    }

    public func loadGoodsTypes(limit: Int) async throws -> [GoodsType] {
        try await goodsInventoryClient.loadGoodsTypes(limit: limit)
    }

    public func createGoodsEntry(_ input: GoodsEntryInput) async throws -> GoodsItem {
        try await goodsInventoryClient.createGoodsEntry(userID: viewerID, input: input)
    }

    public func searchGoods(_ input: GoodsSearchInput) async throws -> [GoodsItem] {
        try await goodsInventoryClient.searchGoods(viewerID: viewerID, input: input)
    }

    public func createProposal(_ input: ProposalCreateInput) async throws -> TradeProposal {
        try await proposalClient.createProposal(senderID: viewerID, input: input)
    }

    public func loadMessages(proposalID: UUID, limit: Int) async throws -> [TradeMessage] {
        try await messageClient.loadMessages(proposalID: proposalID, limit: limit)
    }

    public func sendMessage(_ input: TradeMessageCreateInput) async throws -> TradeMessage {
        try await messageClient.sendTextMessage(senderID: viewerID, input: input)
    }

    public func loadMailingAddress() async throws -> MailingAddress? {
        try await mailingAddressClient.loadAddress(userID: viewerID)
    }

    public func saveMailingAddress(_ address: MailingAddress) async throws -> MailingAddress {
        try await mailingAddressClient.upsertAddress(address)
    }

    public func lookupAddress(postalCode: String) async throws -> PostalCodeAddress? {
        try await postalCodeAddressClient.lookup(postalCode: postalCode)
    }

    public func loadBlockedUsers() async throws -> [BlockedUser] {
        try await blockClient.loadBlockedUsers(blockerID: viewerID)
    }

    public func unblockUser(_ userID: UUID) async throws {
        try await blockClient.unblockUser(blockerID: viewerID, blockedID: userID)
    }

    public func loadNotifications(limit: Int) async throws -> [MegrumNotification] {
        try await notificationClient.loadNotifications(userID: viewerID, limit: limit)
    }

    public func markNotificationRead(_ notificationID: UUID) async throws -> MegrumNotification? {
        try await notificationClient.markNotificationRead(userID: viewerID, notificationID: notificationID)
    }

    public func markAllNotificationsRead() async throws -> [MegrumNotification] {
        try await notificationClient.markAllNotificationsRead(userID: viewerID)
    }

    public func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        let selections = input.oshiSelections.map { selection in
            UserOshiSelection(
                id: UUID(),
                userID: viewerID,
                groupID: selection.groupID,
                characterID: selection.characterID,
                kind: selection.kind,
                priority: selection.priority
            )
        }
        if !selections.isEmpty {
            _ = try await oshiClient.replaceUserSelections(userID: viewerID, selections: selections)
        }

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
        try await proposalClient.loadProposals(viewerID: viewerID)
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
