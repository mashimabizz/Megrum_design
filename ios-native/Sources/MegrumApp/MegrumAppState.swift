import Combine
import Foundation
import MegrumCore

public struct MegrumAppSnapshot: Sendable {
    public var viewer: UserProfile
    public var inventory: [GoodsItem]
    public var wishes: [WishItem]
    public var proposals: [TradeProposal]
    public var grooms: [GroomPost]
    public var threads: [BoardThread]

    public init(
        viewer: UserProfile,
        inventory: [GoodsItem],
        wishes: [WishItem],
        proposals: [TradeProposal],
        grooms: [GroomPost],
        threads: [BoardThread]
    ) {
        self.viewer = viewer
        self.inventory = inventory
        self.wishes = wishes
        self.proposals = proposals
        self.grooms = grooms
        self.threads = threads
    }
}

public struct AccountSetupInput: Equatable, Sendable {
    public var displayName: String
    public var prefecture: String?
    public var oshiSelections: [AccountSetupOshiInput]

    public init(displayName: String, prefecture: String? = nil, oshiSelections: [AccountSetupOshiInput] = []) {
        self.displayName = displayName
        self.prefecture = prefecture
        self.oshiSelections = oshiSelections
    }
}

public struct AccountSetupOshiInput: Equatable, Sendable {
    public var groupID: UUID?
    public var characterID: UUID?
    public var kind: OshiKind
    public var priority: Int

    public init(groupID: UUID?, characterID: UUID?, kind: OshiKind, priority: Int = 1) {
        self.groupID = groupID
        self.characterID = characterID
        self.kind = kind
        self.priority = priority
    }
}

public enum MegrumRepositoryError: Error, Equatable, Sendable {
    case unsupportedMutation
}

public protocol MegrumRepository: Sendable {
    func loadInitialSnapshot() async throws -> MegrumAppSnapshot
    func loadOshiGroups(searchText: String?, limit: Int) async throws -> [OshiGroup]
    func loadOshiCharacters(groupID: UUID, limit: Int) async throws -> [OshiCharacter]
    func loadGoodsTypes(limit: Int) async throws -> [GoodsType]
    func createGoodsEntry(_ input: GoodsEntryInput) async throws -> GoodsItem
    func searchGoods(_ input: GoodsSearchInput) async throws -> [GoodsItem]
    func createProposal(_ input: ProposalCreateInput) async throws -> TradeProposal
    func loadMessages(proposalID: UUID, limit: Int) async throws -> [TradeMessage]
    func sendMessage(_ input: TradeMessageCreateInput) async throws -> TradeMessage
    func loadGrooms(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost]
    func createGroomPost(_ input: GroomPostCreateInput) async throws -> GroomPost
    func markGroomViewed(postID: UUID) async throws
    func setGroomLiked(postID: UUID, isLiked: Bool) async throws
    func sendGroomReply(_ input: GroomReplyCreateInput) async throws -> GroomReply
    func loadMeguriMessages() async throws -> [MeguriMessage]
    func sendMeguriMessage(_ input: MeguriMessageCreateInput) async throws -> MeguriMessage
    func markMeguriMessagesRead(peerID: UUID, readAt: Date) async throws -> [MeguriMessage]
    func loadBoardThreads(latitude: Double?, longitude: Double?, prefecture: String?, scope: BoardThread.Audience) async throws -> [BoardThread]
    func loadBoardReplies(threadID: UUID, latitude: Double?, longitude: Double?, prefecture: String?, scope: BoardThread.Audience) async throws -> [BoardReply]
    func sendBoardReply(_ input: BoardReplyCreateInput) async throws -> BoardReply
    func createBoardThread(_ input: BoardThreadCreateInput) async throws -> BoardThread
    func loadMailingAddress() async throws -> MailingAddress?
    func saveMailingAddress(_ address: MailingAddress) async throws -> MailingAddress
    func lookupAddress(postalCode: String) async throws -> PostalCodeAddress?
    func loadBlockedUsers() async throws -> [BlockedUser]
    func unblockUser(_ userID: UUID) async throws
    func loadNotifications(limit: Int) async throws -> [MegrumNotification]
    func markNotificationRead(_ notificationID: UUID) async throws -> MegrumNotification?
    func markAllNotificationsRead() async throws -> [MegrumNotification]
    func loadPushNotificationsEnabled() async throws -> Bool
    func setPushNotificationsEnabled(_ enabled: Bool) async throws -> Bool
    func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile
}

public extension MegrumRepository {
    func loadOshiGroups(searchText: String?, limit: Int) async throws -> [OshiGroup] {
        []
    }

    func loadOshiCharacters(groupID: UUID, limit: Int) async throws -> [OshiCharacter] {
        []
    }

    func loadGoodsTypes(limit: Int) async throws -> [GoodsType] {
        []
    }

    func createGoodsEntry(_ input: GoodsEntryInput) async throws -> GoodsItem {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func searchGoods(_ input: GoodsSearchInput) async throws -> [GoodsItem] {
        []
    }

    func createProposal(_ input: ProposalCreateInput) async throws -> TradeProposal {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadMessages(proposalID: UUID, limit: Int) async throws -> [TradeMessage] {
        []
    }

    func sendMessage(_ input: TradeMessageCreateInput) async throws -> TradeMessage {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadGrooms(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost] {
        []
    }

    func createGroomPost(_ input: GroomPostCreateInput) async throws -> GroomPost {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func markGroomViewed(postID: UUID) async throws {}

    func setGroomLiked(postID: UUID, isLiked: Bool) async throws {}

    func sendGroomReply(_ input: GroomReplyCreateInput) async throws -> GroomReply {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadMeguriMessages() async throws -> [MeguriMessage] {
        []
    }

    func sendMeguriMessage(_ input: MeguriMessageCreateInput) async throws -> MeguriMessage {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func markMeguriMessagesRead(peerID: UUID, readAt: Date) async throws -> [MeguriMessage] {
        []
    }

    func loadBoardThreads(latitude: Double?, longitude: Double?, prefecture: String?, scope: BoardThread.Audience) async throws -> [BoardThread] {
        []
    }

    func loadBoardReplies(threadID: UUID, latitude: Double?, longitude: Double?, prefecture: String?, scope: BoardThread.Audience) async throws -> [BoardReply] {
        []
    }

    func sendBoardReply(_ input: BoardReplyCreateInput) async throws -> BoardReply {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func createBoardThread(_ input: BoardThreadCreateInput) async throws -> BoardThread {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadMailingAddress() async throws -> MailingAddress? {
        nil
    }

    func saveMailingAddress(_ address: MailingAddress) async throws -> MailingAddress {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func lookupAddress(postalCode: String) async throws -> PostalCodeAddress? {
        nil
    }

    func loadBlockedUsers() async throws -> [BlockedUser] {
        []
    }

    func unblockUser(_ userID: UUID) async throws {}

    func loadNotifications(limit: Int) async throws -> [MegrumNotification] {
        []
    }

    func markNotificationRead(_ notificationID: UUID) async throws -> MegrumNotification? {
        nil
    }

    func markAllNotificationsRead() async throws -> [MegrumNotification] {
        []
    }

    func loadPushNotificationsEnabled() async throws -> Bool {
        true
    }

    func setPushNotificationsEnabled(_ enabled: Bool) async throws -> Bool {
        enabled
    }

    func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        throw MegrumRepositoryError.unsupportedMutation
    }
}

public struct PreviewMegrumRepository: MegrumRepository {
    public init() {}

    public func loadInitialSnapshot() async throws -> MegrumAppSnapshot {
        MegrumAppSnapshot(
            viewer: NativePreviewData.viewer,
            inventory: NativePreviewData.inventory,
            wishes: NativePreviewData.wishes,
            proposals: NativePreviewData.proposals,
            grooms: NativePreviewData.grooms,
            threads: NativePreviewData.threads
        )
    }

    public func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        UserProfile(
            id: NativePreviewData.viewer.id,
            handle: NativePreviewData.viewer.handle,
            displayName: input.displayName,
            avatarURL: NativePreviewData.viewer.avatarURL,
            prefecture: input.prefecture,
            accountStatus: .active
        )
    }

    public func loadOshiGroups(searchText: String?, limit: Int) async throws -> [OshiGroup] {
        let groups = NativePreviewData.oshiGroups
        guard let searchText = searchText?.trimmingCharacters(in: .whitespacesAndNewlines), !searchText.isEmpty else {
            return Array(groups.prefix(limit))
        }
        return Array(groups.filter { $0.name.localizedCaseInsensitiveContains(searchText) }.prefix(limit))
    }

    public func loadOshiCharacters(groupID: UUID, limit: Int) async throws -> [OshiCharacter] {
        Array(NativePreviewData.oshiCharacters.filter { $0.groupID == groupID }.prefix(limit))
    }

    public func loadGoodsTypes(limit: Int) async throws -> [GoodsType] {
        Array(NativePreviewData.goodsTypes.prefix(limit))
    }

    public func createGoodsEntry(_ input: GoodsEntryInput) async throws -> GoodsItem {
        GoodsItem(
            id: UUID(),
            ownerID: NativePreviewData.viewerID,
            groupID: input.groupID,
            goodsTypeID: input.goodsTypeID,
            title: input.title,
            quantity: input.quantity
        )
    }

    public func searchGoods(_ input: GoodsSearchInput) async throws -> [GoodsItem] {
        let query = input.query.trimmingCharacters(in: .whitespacesAndNewlines)
        return NativePreviewData.inventory.filter { item in
            guard item.ownerID != NativePreviewData.viewerID else {
                return false
            }
            let matchesQuery = query.isEmpty
                || item.title.localizedCaseInsensitiveContains(query)
                || item.tags.contains { $0.name.localizedCaseInsensitiveContains(query) }
            let matchesGroup = input.groupID == nil || item.groupID == input.groupID
            let matchesGoodsType = input.goodsTypeID == nil || item.goodsTypeID == input.goodsTypeID
            return matchesQuery && matchesGroup && matchesGoodsType
        }
        .prefix(max(0, input.limit))
        .map { $0 }
    }

    public func createProposal(_ input: ProposalCreateInput) async throws -> TradeProposal {
        TradeProposal(
            id: UUID(),
            senderID: NativePreviewData.viewerID,
            receiverID: input.receiverID,
            status: input.status,
            exchangeMethod: input.exchangeMethod,
            senderGoodsIDs: input.senderGoodsIDs,
            receiverGoodsIDs: input.receiverGoodsIDs,
            conditionTags: input.conditionTags
        )
    }

    public func loadMessages(proposalID: UUID, limit: Int) async throws -> [TradeMessage] {
        NativePreviewData.messages[proposalID] ?? []
    }

    public func sendMessage(_ input: TradeMessageCreateInput) async throws -> TradeMessage {
        TradeMessage(
            id: UUID(),
            proposalID: input.proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .text,
            body: input.body
        )
    }

    public func loadGrooms(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost] {
        NativePreviewData.grooms
    }

    public func createGroomPost(_ input: GroomPostCreateInput) async throws -> GroomPost {
        GroomPost(
            id: UUID(),
            authorID: NativePreviewData.viewerID,
            imageURL: URL(string: "https://example.com/native-groom-preview.jpg")!,
            latitude: input.latitude ?? NativePreviewData.grooms.first?.latitude ?? 35.681236,
            longitude: input.longitude ?? NativePreviewData.grooms.first?.longitude ?? 139.767125
        )
    }

    public func markGroomViewed(postID: UUID) async throws {}

    public func setGroomLiked(postID: UUID, isLiked: Bool) async throws {}

    public func sendGroomReply(_ input: GroomReplyCreateInput) async throws -> GroomReply {
        GroomReply(
            id: UUID(),
            groomPostID: input.groomPostID,
            senderID: input.senderID,
            recipientID: input.recipientID,
            body: input.body,
            groomImageURL: input.groomImageURL
        )
    }

    public func loadMeguriMessages() async throws -> [MeguriMessage] {
        NativePreviewData.meguriMessages
    }

    public func sendMeguriMessage(_ input: MeguriMessageCreateInput) async throws -> MeguriMessage {
        MeguriMessage(
            id: UUID(),
            senderID: input.senderID,
            recipientID: input.recipientID,
            sourceGroomReplyID: input.sourceGroomReplyID,
            body: input.body
        )
    }

    public func markMeguriMessagesRead(peerID: UUID, readAt: Date) async throws -> [MeguriMessage] {
        NativePreviewData.meguriMessages.compactMap { message in
            guard message.senderID == peerID, message.recipientID == NativePreviewData.viewerID, message.readAt == nil else {
                return nil
            }
            var next = message
            next.readAt = readAt
            return next
        }
    }

    public func loadBoardThreads(latitude: Double?, longitude: Double?, prefecture: String?, scope: BoardThread.Audience) async throws -> [BoardThread] {
        NativePreviewData.threads.filter { thread in
            switch scope {
            case .nearby3km:
                return thread.audience == .nearby3km
            case .samePrefecture:
                return thread.prefecture == prefecture || prefecture == nil
            case .sameSpot, .global:
                return thread.audience == scope
            }
        }
    }

    public func loadBoardReplies(threadID: UUID, latitude: Double?, longitude: Double?, prefecture: String?, scope: BoardThread.Audience) async throws -> [BoardReply] {
        NativePreviewData.boardReplies[threadID] ?? []
    }

    public func sendBoardReply(_ input: BoardReplyCreateInput) async throws -> BoardReply {
        BoardReply(
            id: UUID(),
            threadID: input.threadID,
            authorID: NativePreviewData.viewerID,
            body: input.body.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    public func createBoardThread(_ input: BoardThreadCreateInput) async throws -> BoardThread {
        BoardThread(
            id: UUID(),
            authorID: NativePreviewData.viewerID,
            title: input.title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: input.body.trimmingCharacters(in: .whitespacesAndNewlines),
            audience: input.audience,
            latitude: input.latitude,
            longitude: input.longitude,
            prefecture: input.prefecture
        )
    }

    public func loadMailingAddress() async throws -> MailingAddress? {
        NativePreviewData.mailingAddress
    }

    public func saveMailingAddress(_ address: MailingAddress) async throws -> MailingAddress {
        address
    }

    public func lookupAddress(postalCode: String) async throws -> PostalCodeAddress? {
        guard normalizedPostalCode(postalCode) == "1000001" else {
            return nil
        }
        return PostalCodeAddress(
            postalCode: "1000001",
            prefecture: "東京都",
            city: "千代田区",
            town: "千代田"
        )
    }

    public func loadBlockedUsers() async throws -> [BlockedUser] {
        NativePreviewData.blockedUsers
    }

    public func unblockUser(_ userID: UUID) async throws {}

    public func loadNotifications(limit: Int) async throws -> [MegrumNotification] {
        Array(NativePreviewData.notifications.prefix(limit))
    }

    public func markNotificationRead(_ notificationID: UUID) async throws -> MegrumNotification? {
        guard var notification = NativePreviewData.notifications.first(where: { $0.id == notificationID }) else {
            return nil
        }
        notification.readAt = notification.readAt ?? .now
        return notification
    }

    public func markAllNotificationsRead() async throws -> [MegrumNotification] {
        NativePreviewData.notifications.map { notification in
            var next = notification
            next.readAt = next.readAt ?? .now
            return next
        }
    }

    public func loadPushNotificationsEnabled() async throws -> Bool {
        true
    }

    public func setPushNotificationsEnabled(_ enabled: Bool) async throws -> Bool {
        enabled
    }
}

@MainActor
public final class MegrumAppState: ObservableObject {
    @Published public private(set) var viewer: UserProfile?
    @Published public private(set) var inventory: [GoodsItem] = []
    @Published public private(set) var wishes: [WishItem] = []
    @Published public private(set) var proposals: [TradeProposal] = []
    @Published public private(set) var messagesByProposalID: [UUID: [TradeMessage]] = [:]
    @Published public private(set) var boardRepliesByThreadID: [UUID: [BoardReply]] = [:]
    @Published public private(set) var groomRepliesByPostID: [UUID: [GroomReply]] = [:]
    @Published public private(set) var meguriMessages: [MeguriMessage] = []
    @Published public private(set) var grooms: [GroomPost] = []
    @Published public private(set) var likedGroomIDs: Set<UUID> = []
    @Published public private(set) var threads: [BoardThread] = []
    @Published public private(set) var oshiGroups: [OshiGroup] = []
    @Published public private(set) var oshiCharacters: [OshiCharacter] = []
    @Published public private(set) var goodsTypes: [GoodsType] = []
    @Published public private(set) var searchResults: [SearchResultItem] = []
    @Published public private(set) var mailingAddress: MailingAddress?
    @Published public private(set) var blockedUsers: [BlockedUser] = []
    @Published public private(set) var notifications: [MegrumNotification] = []
    @Published public private(set) var pushNotificationsEnabled = true
    @Published public private(set) var isLoading = false
    @Published public private(set) var isLoadingOshiGroups = false
    @Published public private(set) var isLoadingOshiCharacters = false
    @Published public private(set) var isLoadingGoodsTypes = false
    @Published public private(set) var isSearchingGoods = false
    @Published public private(set) var isLoadingMailingAddress = false
    @Published public private(set) var isLoadingBlockedUsers = false
    @Published public private(set) var isLoadingNotifications = false
    @Published public private(set) var isLoadingPushNotificationSetting = false
    @Published public private(set) var isLoadingMeguri = false
    @Published public private(set) var isLoadingMeguriMessages = false
    @Published public private(set) var isLookingUpPostalCode = false
    @Published public private(set) var isSavingMailingAddress = false
    @Published public private(set) var isCreatingGoodsEntry = false
    @Published public private(set) var isCreatingProposal = false
    @Published public private(set) var isCreatingGroomPost = false
    @Published public private(set) var isCreatingBoardThread = false
    @Published public private(set) var loadingMessagesProposalID: UUID?
    @Published public private(set) var sendingMessageProposalID: UUID?
    @Published public private(set) var sendingGroomReplyPostID: UUID?
    @Published public private(set) var sendingMeguriMessageRecipientID: UUID?
    @Published public private(set) var loadingBoardRepliesThreadID: UUID?
    @Published public private(set) var sendingBoardReplyThreadID: UUID?
    @Published public private(set) var unblockingUserID: UUID?
    @Published public private(set) var isMarkingNotificationsRead = false
    @Published public private(set) var isSavingPushNotificationSetting = false
    @Published public private(set) var isSavingAccountSetup = false
    @Published public private(set) var errorMessage: String?

    private var repository: any MegrumRepository
    private var activeSearchRequestID: UUID?

    public init(repository: any MegrumRepository = PreviewMegrumRepository()) {
        self.repository = repository
    }

    public var unreadNotificationCount: Int {
        notifications.filter(\.isUnread).count
    }

    public func messages(for proposalID: UUID) -> [TradeMessage] {
        messagesByProposalID[proposalID] ?? []
    }

    public func boardReplies(for threadID: UUID) -> [BoardReply] {
        boardRepliesByThreadID[threadID] ?? []
    }

    public func groomReplies(for postID: UUID) -> [GroomReply] {
        groomRepliesByPostID[postID] ?? []
    }

    public func meguriMessages(with peerID: UUID) -> [MeguriMessage] {
        meguriMessages.filter { message in
            message.senderID == peerID || message.recipientID == peerID
        }
    }

    public func isGroomLiked(_ postID: UUID) -> Bool {
        likedGroomIDs.contains(postID)
    }

    public func loadInitialData() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            apply(try await repository.loadInitialSnapshot())
        } catch {
            errorMessage = "データを読み込めませんでした"
        }

        isLoading = false
    }

    public func refresh() async {
        await loadInitialData()
    }

    public func loadMeguriFeed(
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        scope: BoardThread.Audience = .nearby3km
    ) async {
        guard !isLoadingMeguri else {
            return
        }

        let selectedPrefecture = normalizedPrefecture(prefecture) ?? normalizedPrefecture(viewer?.prefecture)
        isLoadingMeguri = true
        errorMessage = nil
        do {
            async let loadedGrooms = repository.loadGrooms(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: 1_000
            )
            async let loadedThreads = repository.loadBoardThreads(
                latitude: latitude,
                longitude: longitude,
                prefecture: selectedPrefecture,
                scope: scope
            )
            grooms = try await loadedGrooms
            threads = try await loadedThreads
        } catch {
            errorMessage = "めぐりを読み込めませんでした"
        }
        isLoadingMeguri = false
    }

    public func createGroomPost(
        imageData: Data,
        imageContentType: String,
        caption: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) async -> Bool {
        guard !isCreatingGroomPost else {
            return false
        }
        guard let viewer else {
            errorMessage = "プロフィールを読み込んでから投稿してください"
            return false
        }
        guard !imageData.isEmpty else {
            errorMessage = "投稿する画像を選択してください"
            return false
        }
        guard let latitude, let longitude else {
            errorMessage = "現在地を確認してから投稿してください"
            return false
        }

        isCreatingGroomPost = true
        errorMessage = nil
        do {
            let post = try await repository.createGroomPost(
                GroomPostCreateInput(
                    authorID: viewer.id,
                    imageData: imageData,
                    imageContentType: imageContentType,
                    caption: caption,
                    latitude: latitude,
                    longitude: longitude
                )
            )
            grooms.removeAll { $0.id == post.id }
            grooms.insert(post, at: 0)
            isCreatingGroomPost = false
            return true
        } catch {
            errorMessage = "グルームを投稿できませんでした"
            isCreatingGroomPost = false
            return false
        }
    }

    public func markGroomViewed(_ postID: UUID) async {
        do {
            try await repository.markGroomViewed(postID: postID)
        } catch {
            errorMessage = "グルームの閲覧状態を更新できませんでした"
        }
    }

    public func setGroomLiked(_ postID: UUID, isLiked: Bool) async {
        let previousLikedIDs = likedGroomIDs
        if isLiked {
            likedGroomIDs.insert(postID)
        } else {
            likedGroomIDs.remove(postID)
        }
        do {
            try await repository.setGroomLiked(postID: postID, isLiked: isLiked)
        } catch {
            likedGroomIDs = previousLikedIDs
            errorMessage = "グルームのいいねを更新できませんでした"
        }
    }

    public func sendGroomReply(
        postID: UUID,
        recipientID: UUID,
        body: String,
        groomImageURL: URL?
    ) async -> Bool {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return false
        }
        guard let viewer else {
            errorMessage = "プロフィールを確認してから返信してください"
            return false
        }
        guard viewer.id != recipientID else {
            errorMessage = "自分のグルームには返信できません"
            return false
        }
        guard sendingGroomReplyPostID != postID else {
            return false
        }

        sendingGroomReplyPostID = postID
        errorMessage = nil
        do {
            let reply = try await repository.sendGroomReply(
                GroomReplyCreateInput(
                    groomPostID: postID,
                    senderID: viewer.id,
                    recipientID: recipientID,
                    body: trimmed,
                    groomImageURL: groomImageURL
                )
            )
            groomRepliesByPostID[postID, default: []].append(reply)
            sendingGroomReplyPostID = nil
            return true
        } catch {
            errorMessage = "グルームに返信できませんでした"
            sendingGroomReplyPostID = nil
            return false
        }
    }

    public func loadMeguriMessages() async {
        guard !isLoadingMeguriMessages else {
            return
        }

        isLoadingMeguriMessages = true
        errorMessage = nil
        do {
            meguriMessages = try await repository.loadMeguriMessages()
        } catch {
            errorMessage = "めぐりメッセージを読み込めませんでした"
        }
        isLoadingMeguriMessages = false
    }

    public func sendMeguriMessage(
        recipientID: UUID,
        body: String,
        sourceGroomReplyID: UUID? = nil
    ) async -> Bool {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return false
        }
        guard let viewer else {
            errorMessage = "プロフィールを確認してから送信してください"
            return false
        }
        guard viewer.id != recipientID else {
            errorMessage = "自分には送信できません"
            return false
        }
        guard sendingMeguriMessageRecipientID != recipientID else {
            return false
        }

        sendingMeguriMessageRecipientID = recipientID
        errorMessage = nil
        do {
            let message = try await repository.sendMeguriMessage(
                MeguriMessageCreateInput(
                    senderID: viewer.id,
                    recipientID: recipientID,
                    sourceGroomReplyID: sourceGroomReplyID,
                    body: trimmed
                )
            )
            meguriMessages.append(message)
            sendingMeguriMessageRecipientID = nil
            return true
        } catch {
            errorMessage = "めぐりメッセージを送信できませんでした"
            sendingMeguriMessageRecipientID = nil
            return false
        }
    }

    public func markMeguriMessagesRead(peerID: UUID) async {
        guard let viewer else {
            return
        }

        let targetIndexes = meguriMessages.indices.filter { index in
            let message = meguriMessages[index]
            return message.senderID == peerID
                && message.recipientID == viewer.id
                && message.readAt == nil
        }
        guard !targetIndexes.isEmpty else {
            return
        }

        let readAt = Date()
        let previous = meguriMessages
        for index in targetIndexes {
            meguriMessages[index].readAt = readAt
        }

        do {
            let updated = try await repository.markMeguriMessagesRead(peerID: peerID, readAt: readAt)
            guard !updated.isEmpty else {
                return
            }
            let updatedByID = Dictionary(uniqueKeysWithValues: updated.map { ($0.id, $0) })
            meguriMessages = meguriMessages.map { updatedByID[$0.id] ?? $0 }
        } catch {
            meguriMessages = previous
            errorMessage = "めぐりメッセージを既読にできませんでした"
        }
    }

    public func loadBoardReplies(
        threadID: UUID,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        scope: BoardThread.Audience = .nearby3km
    ) async {
        guard loadingBoardRepliesThreadID != threadID else {
            return
        }

        let selectedPrefecture = normalizedPrefecture(prefecture) ?? normalizedPrefecture(viewer?.prefecture)
        loadingBoardRepliesThreadID = threadID
        errorMessage = nil
        do {
            boardRepliesByThreadID[threadID] = try await repository.loadBoardReplies(
                threadID: threadID,
                latitude: latitude,
                longitude: longitude,
                prefecture: selectedPrefecture,
                scope: scope
            )
        } catch {
            errorMessage = "掲示板の返信を読み込めませんでした"
        }
        loadingBoardRepliesThreadID = nil
    }

    public func sendBoardReply(
        threadID: UUID,
        body: String,
        prefecture: String? = nil,
        scope: BoardThread.Audience = .nearby3km
    ) async -> Bool {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return false
        }
        guard sendingBoardReplyThreadID != threadID else {
            return false
        }

        let selectedPrefecture = normalizedPrefecture(prefecture) ?? normalizedPrefecture(viewer?.prefecture)
        sendingBoardReplyThreadID = threadID
        errorMessage = nil
        do {
            let reply = try await repository.sendBoardReply(
                BoardReplyCreateInput(
                    threadID: threadID,
                    body: trimmed,
                    prefecture: selectedPrefecture,
                    scope: scope
                )
            )
            boardRepliesByThreadID[threadID, default: []].append(reply)
            sendingBoardReplyThreadID = nil
            return true
        } catch {
            errorMessage = "掲示板に返信できませんでした"
            sendingBoardReplyThreadID = nil
            return false
        }
    }

    public func createBoardThread(
        title: String,
        body: String,
        scope: BoardThread.Audience = .nearby3km,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil
    ) async -> Bool {
        guard !isCreatingBoardThread else {
            return false
        }
        guard let viewer else {
            errorMessage = "プロフィールを読み込んでから投稿してください"
            return false
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "タイトルを入力してください"
            return false
        }
        guard !trimmedBody.isEmpty else {
            errorMessage = "本文を入力してください"
            return false
        }

        let normalizedPrefecture = normalizedPrefecture(prefecture) ?? normalizedPrefecture(viewer.prefecture)
        switch scope {
        case .nearby3km:
            guard latitude != nil, longitude != nil, normalizedPrefecture != nil else {
                errorMessage = "現在地と都道府県を確認してから投稿してください"
                return false
            }
        case .samePrefecture:
            guard normalizedPrefecture != nil else {
                errorMessage = "プロフィールの都道府県を設定してください"
                return false
            }
        case .sameSpot, .global:
            errorMessage = "この公開範囲はまだ作成できません"
            return false
        }

        isCreatingBoardThread = true
        errorMessage = nil
        do {
            let created = try await repository.createBoardThread(
                BoardThreadCreateInput(
                    authorID: viewer.id,
                    title: trimmedTitle,
                    body: trimmedBody,
                    audience: scope,
                    latitude: latitude,
                    longitude: longitude,
                    prefecture: normalizedPrefecture
                )
            )
            threads.removeAll { $0.id == created.id }
            threads.insert(created, at: 0)
            isCreatingBoardThread = false
            return true
        } catch {
            errorMessage = "掲示板を作成できませんでした"
            isCreatingBoardThread = false
            return false
        }
    }

    private func normalizedPrefecture(_ value: String?) -> String? {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
    }

    public func replaceRepository(_ repository: any MegrumRepository) async {
        self.repository = repository
        await loadInitialData()
    }

    public func loadOshiGroups(searchText: String? = nil) async {
        guard !isLoadingOshiGroups else {
            return
        }

        isLoadingOshiGroups = true
        errorMessage = nil
        do {
            oshiGroups = try await repository.loadOshiGroups(searchText: searchText, limit: 30)
        } catch {
            errorMessage = "推しグループを読み込めませんでした"
        }
        isLoadingOshiGroups = false
    }

    public func loadOshiCharacters(group: OshiGroup?) async {
        guard !isLoadingOshiCharacters else {
            return
        }
        guard let group else {
            oshiCharacters = []
            return
        }

        isLoadingOshiCharacters = true
        errorMessage = nil
        do {
            oshiCharacters = try await repository.loadOshiCharacters(groupID: group.id, limit: 80)
        } catch {
            errorMessage = "推しメンバーを読み込めませんでした"
        }
        isLoadingOshiCharacters = false
    }

    public func loadGoodsTypes() async {
        guard !isLoadingGoodsTypes else {
            return
        }

        isLoadingGoodsTypes = true
        errorMessage = nil
        do {
            goodsTypes = try await repository.loadGoodsTypes(limit: 40)
        } catch {
            errorMessage = "グッズ種別を読み込めませんでした"
        }
        isLoadingGoodsTypes = false
    }

    public func createGoodsEntry(_ input: GoodsEntryInput) async -> Bool {
        guard !isCreatingGoodsEntry else {
            return false
        }

        let trimmedTitle = input.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "グッズ名を入力してください"
            return false
        }
        let normalizedInput = GoodsEntryInput(
            kind: input.kind,
            title: trimmedTitle,
            groupID: input.groupID,
            goodsTypeID: input.goodsTypeID,
            quantity: max(1, min(input.quantity, 999))
        )

        isCreatingGoodsEntry = true
        errorMessage = nil
        do {
            let created = try await repository.createGoodsEntry(normalizedInput)
            switch normalizedInput.kind {
            case .inventory:
                inventory.insert(created, at: 0)
            case .wish:
                wishes.insert(
                    WishItem(
                        id: created.id,
                        ownerID: created.ownerID,
                        groupID: created.groupID,
                        memberID: created.memberID,
                        goodsTypeID: created.goodsTypeID,
                        title: created.title,
                        tags: created.tags
                    ),
                    at: 0
                )
            }
            isCreatingGoodsEntry = false
            return true
        } catch {
            errorMessage = "グッズを保存できませんでした"
            isCreatingGoodsEntry = false
            return false
        }
    }

    public func searchGoods(query: String, groupID: UUID? = nil, goodsTypeID: UUID? = nil) async {
        let requestID = UUID()
        activeSearchRequestID = requestID
        isSearchingGoods = true
        errorMessage = nil
        do {
            let items = try await repository.searchGoods(
                GoodsSearchInput(
                    query: query,
                    groupID: groupID,
                    goodsTypeID: goodsTypeID
                )
            )
            let results = items.map { item in
                SearchResultItem(
                    item: item,
                    ownerUserID: item.ownerID,
                    bucket: searchBucket(for: item)
                )
            }
            guard activeSearchRequestID == requestID else {
                return
            }
            searchResults = results
        } catch {
            if activeSearchRequestID == requestID {
                errorMessage = "検索結果を読み込めませんでした"
            }
        }
        if activeSearchRequestID == requestID {
            activeSearchRequestID = nil
            isSearchingGoods = false
        }
    }

    public func createProposal(_ input: ProposalCreateInput) async -> Bool {
        guard !isCreatingProposal else {
            return false
        }
        guard !input.senderGoodsIDs.isEmpty, !input.receiverGoodsIDs.isEmpty else {
            errorMessage = "提示物を選択してください"
            return false
        }

        isCreatingProposal = true
        errorMessage = nil
        do {
            let proposal = try await repository.createProposal(input)
            proposals.insert(proposal, at: 0)
            isCreatingProposal = false
            return true
        } catch {
            errorMessage = "打診を作成できませんでした"
            isCreatingProposal = false
            return false
        }
    }

    public func loadMessages(proposalID: UUID, limit: Int = 80) async {
        guard loadingMessagesProposalID != proposalID else {
            return
        }
        loadingMessagesProposalID = proposalID
        errorMessage = nil
        do {
            messagesByProposalID[proposalID] = try await repository.loadMessages(proposalID: proposalID, limit: limit)
        } catch {
            errorMessage = "メッセージを読み込めませんでした"
        }
        loadingMessagesProposalID = nil
    }

    public func sendMessage(proposalID: UUID, body: String) async -> Bool {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return false
        }
        guard sendingMessageProposalID != proposalID else {
            return false
        }

        sendingMessageProposalID = proposalID
        errorMessage = nil
        do {
            let message = try await repository.sendMessage(
                TradeMessageCreateInput(proposalID: proposalID, body: trimmed)
            )
            messagesByProposalID[proposalID, default: []].append(message)
            sendingMessageProposalID = nil
            return true
        } catch {
            errorMessage = "メッセージを送信できませんでした"
            sendingMessageProposalID = nil
            return false
        }
    }

    public func loadMailingAddress() async {
        guard !isLoadingMailingAddress else {
            return
        }

        isLoadingMailingAddress = true
        errorMessage = nil
        do {
            mailingAddress = try await repository.loadMailingAddress()
        } catch {
            errorMessage = "住所を読み込めませんでした"
        }
        isLoadingMailingAddress = false
    }

    public func saveMailingAddress(_ address: MailingAddress) async -> Bool {
        guard !isSavingMailingAddress else {
            return false
        }
        guard address.isReady else {
            errorMessage = "宛名・郵便番号・都道府県・市区町村・番地を入力してください"
            return false
        }

        isSavingMailingAddress = true
        errorMessage = nil
        do {
            mailingAddress = try await repository.saveMailingAddress(address)
            isSavingMailingAddress = false
            return true
        } catch {
            errorMessage = "住所を保存できませんでした"
            isSavingMailingAddress = false
            return false
        }
    }

    public func lookupPostalCode(_ postalCode: String) async -> PostalCodeAddress? {
        let normalizedPostalCode = normalizedPostalCode(postalCode)
        guard normalizedPostalCode.count == 7 else {
            return nil
        }
        guard !isLookingUpPostalCode else {
            return nil
        }

        isLookingUpPostalCode = true
        errorMessage = nil
        defer {
            isLookingUpPostalCode = false
        }

        do {
            let address = try await repository.lookupAddress(postalCode: normalizedPostalCode)
            if address == nil {
                errorMessage = "郵便番号に一致する住所が見つかりませんでした"
            }
            return address
        } catch {
            errorMessage = "郵便番号から住所を取得できませんでした"
            return nil
        }
    }

    public func loadBlockedUsers() async {
        guard !isLoadingBlockedUsers else {
            return
        }

        isLoadingBlockedUsers = true
        errorMessage = nil
        do {
            blockedUsers = try await repository.loadBlockedUsers()
        } catch {
            errorMessage = "ブロックした人を読み込めませんでした"
        }
        isLoadingBlockedUsers = false
    }

    public func unblockUser(_ userID: UUID) async -> Bool {
        guard unblockingUserID == nil else {
            return false
        }

        unblockingUserID = userID
        errorMessage = nil
        do {
            try await repository.unblockUser(userID)
            blockedUsers.removeAll { $0.userID == userID }
            unblockingUserID = nil
            return true
        } catch {
            errorMessage = "ブロックを解除できませんでした"
            unblockingUserID = nil
            return false
        }
    }

    public func loadNotifications() async {
        guard !isLoadingNotifications else {
            return
        }

        isLoadingNotifications = true
        errorMessage = nil
        do {
            notifications = try await repository.loadNotifications(limit: 100)
        } catch {
            errorMessage = "通知を読み込めませんでした"
        }
        isLoadingNotifications = false
    }

    public func markNotificationRead(_ notificationID: UUID) async {
        guard let index = notifications.firstIndex(where: { $0.id == notificationID }) else {
            return
        }
        guard notifications[index].isUnread else {
            return
        }

        let readAt = Date()
        notifications[index].readAt = readAt
        do {
            if let updated = try await repository.markNotificationRead(notificationID) {
                notifications[index] = updated
            }
        } catch {
            notifications[index].readAt = nil
            errorMessage = "通知を既読にできませんでした"
        }
    }

    public func markAllNotificationsRead() async {
        guard !isMarkingNotificationsRead else {
            return
        }
        guard unreadNotificationCount > 0 else {
            return
        }

        isMarkingNotificationsRead = true
        errorMessage = nil
        let previous = notifications
        let readAt = Date()
        notifications = notifications.map { notification in
            var next = notification
            next.readAt = next.readAt ?? readAt
            return next
        }
        do {
            let updated = try await repository.markAllNotificationsRead()
            if !updated.isEmpty {
                let updatedByID = Dictionary(uniqueKeysWithValues: updated.map { ($0.id, $0) })
                notifications = notifications.map { updatedByID[$0.id] ?? $0 }
            }
        } catch {
            notifications = previous
            errorMessage = "通知を既読にできませんでした"
        }
        isMarkingNotificationsRead = false
    }

    public func loadPushNotificationSetting() async {
        guard !isLoadingPushNotificationSetting else {
            return
        }

        isLoadingPushNotificationSetting = true
        errorMessage = nil
        do {
            pushNotificationsEnabled = try await repository.loadPushNotificationsEnabled()
        } catch {
            errorMessage = "モバイル通知設定を読み込めませんでした"
        }
        isLoadingPushNotificationSetting = false
    }

    @discardableResult
    public func setPushNotificationsEnabled(_ enabled: Bool) async -> Bool {
        guard !isSavingPushNotificationSetting else {
            return false
        }

        let previous = pushNotificationsEnabled
        pushNotificationsEnabled = enabled
        isSavingPushNotificationSetting = true
        errorMessage = nil
        do {
            pushNotificationsEnabled = try await repository.setPushNotificationsEnabled(enabled)
            isSavingPushNotificationSetting = false
            return true
        } catch {
            pushNotificationsEnabled = previous
            errorMessage = "モバイル通知設定を保存できませんでした"
            isSavingPushNotificationSetting = false
            return false
        }
    }

    public func completeAccountSetup(
        displayName: String,
        prefecture: String?,
        oshiSelections: [AccountSetupOshiInput] = []
    ) async -> Bool {
        guard !isSavingAccountSetup else {
            return false
        }
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDisplayName.isEmpty else {
            errorMessage = "表示名を入力してください"
            return false
        }
        guard !oshiSelections.isEmpty else {
            errorMessage = "推しを選択してください"
            return false
        }

        isSavingAccountSetup = true
        errorMessage = nil

        do {
            viewer = try await repository.completeAccountSetup(
                AccountSetupInput(
                    displayName: trimmedDisplayName,
                    prefecture: prefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank,
                    oshiSelections: oshiSelections
                )
            )
            isSavingAccountSetup = false
            return true
        } catch {
            errorMessage = "プロフィールを保存できませんでした"
            isSavingAccountSetup = false
            return false
        }
    }

    private func apply(_ snapshot: MegrumAppSnapshot) {
        viewer = snapshot.viewer
        inventory = snapshot.inventory
        wishes = snapshot.wishes
        proposals = snapshot.proposals
        grooms = snapshot.grooms
        likedGroomIDs = Set(snapshot.grooms.filter(\.liked).map(\.id))
        threads = snapshot.threads
    }

    private func searchBucket(for item: GoodsItem) -> SearchMatchBucket {
        let matchesWish = wishes.contains { wish in
            let groupMatches = wish.groupID == nil || item.groupID == wish.groupID
            let typeMatches = wish.goodsTypeID == nil || item.goodsTypeID == wish.goodsTypeID
            return groupMatches && typeMatches
        }
        return matchesWish ? .possible : .none
    }
}

private extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}

private func normalizedPostalCode(_ value: String) -> String {
    String(value.filter(\.isNumber).prefix(7))
}
