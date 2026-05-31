import Combine
import Foundation
import MegrumCore

public struct MegrumAppSnapshot: Sendable {
    public var viewer: UserProfile
    public var inventory: [GoodsItem]
    public var wishes: [WishItem]
    public var listings: [IndividualListing]
    public var proposals: [TradeProposal]
    public var grooms: [GroomPost]
    public var threads: [BoardThread]

    public init(
        viewer: UserProfile,
        inventory: [GoodsItem],
        wishes: [WishItem],
        listings: [IndividualListing] = [],
        proposals: [TradeProposal],
        grooms: [GroomPost],
        threads: [BoardThread]
    ) {
        self.viewer = viewer
        self.inventory = inventory
        self.wishes = wishes
        self.listings = listings
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
    func archiveGoodsItem(itemID: UUID) async throws
    func deleteGoodsItem(itemID: UUID) async throws
    func reportGoods(_ input: GoodsReportCreateInput) async throws -> GoodsReportTicket
    func loadIndividualListings() async throws -> [IndividualListing]
    func createIndividualListing(_ input: IndividualListingCreateInput) async throws -> IndividualListing
    func loadPublicTradeGoods(userID: UUID, limit: Int) async throws -> [GoodsItem]
    func loadPublicIndividualListings(userID: UUID) async throws -> [IndividualListing]
    func loadPublicUserProfile(userID: UUID) async throws -> PublicUserProfile?
    func loadUserEvaluations(userID: UUID, limit: Int) async throws -> [UserEvaluation]
    func createProposal(_ input: ProposalCreateInput) async throws -> TradeProposal
    func agreeProposal(proposalID: UUID, acceptedExchangeMethod: ExchangeMethod?) async throws -> TradeProposal
    func rejectProposal(proposalID: UUID) async throws -> TradeProposal
    func addTradeEvidence(_ input: TradeEvidenceCreateInput) async throws -> TradeProposal
    func approveTradeEvidence(proposalID: UUID) async throws -> TradeProposal
    func submitTradeEvaluation(_ input: TradeEvaluationCreateInput) async throws -> UserEvaluation
    func fileTradeDispute(_ input: TradeDisputeCreateInput) async throws -> TradeDisputeTicket
    func loadMessages(proposalID: UUID, limit: Int) async throws -> [TradeMessage]
    func sendMessage(_ input: TradeMessageCreateInput) async throws -> TradeMessage
    func sendLocationMessage(proposalID: UUID, latitude: Double, longitude: Double, label: String, body: String?) async throws -> TradeMessage
    func sendArrivalStatusMessage(proposalID: UUID, status: TradeArrivalStatus, body: String?) async throws -> TradeMessage
    func loadSchedules(for proposal: TradeProposal, startAt: Date, endAt: Date) async throws -> [PersonalSchedule]
    func createSchedule(_ input: PersonalScheduleCreateInput) async throws -> PersonalSchedule
    func loadGrooms(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost]
    func loadGroomMapPosts(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost]
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
    func registerNativePushDeviceToken(_ token: String, appVersion: String?) async throws
    func revokeNativePushDeviceToken(_ token: String, revokedAt: Date) async throws
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

    func archiveGoodsItem(itemID: UUID) async throws {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func deleteGoodsItem(itemID: UUID) async throws {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func reportGoods(_ input: GoodsReportCreateInput) async throws -> GoodsReportTicket {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadIndividualListings() async throws -> [IndividualListing] {
        []
    }

    func createIndividualListing(_ input: IndividualListingCreateInput) async throws -> IndividualListing {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadPublicTradeGoods(userID: UUID, limit: Int) async throws -> [GoodsItem] {
        []
    }

    func loadPublicIndividualListings(userID: UUID) async throws -> [IndividualListing] {
        []
    }

    func loadPublicUserProfile(userID: UUID) async throws -> PublicUserProfile? {
        nil
    }

    func loadUserEvaluations(userID: UUID, limit: Int) async throws -> [UserEvaluation] {
        []
    }

    func createProposal(_ input: ProposalCreateInput) async throws -> TradeProposal {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func agreeProposal(proposalID: UUID, acceptedExchangeMethod: ExchangeMethod?) async throws -> TradeProposal {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func rejectProposal(proposalID: UUID) async throws -> TradeProposal {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func addTradeEvidence(_ input: TradeEvidenceCreateInput) async throws -> TradeProposal {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func approveTradeEvidence(proposalID: UUID) async throws -> TradeProposal {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func submitTradeEvaluation(_ input: TradeEvaluationCreateInput) async throws -> UserEvaluation {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func fileTradeDispute(_ input: TradeDisputeCreateInput) async throws -> TradeDisputeTicket {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadMessages(proposalID: UUID, limit: Int) async throws -> [TradeMessage] {
        []
    }

    func sendMessage(_ input: TradeMessageCreateInput) async throws -> TradeMessage {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func sendLocationMessage(proposalID: UUID, latitude: Double, longitude: Double, label: String, body: String?) async throws -> TradeMessage {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func sendArrivalStatusMessage(proposalID: UUID, status: TradeArrivalStatus, body: String?) async throws -> TradeMessage {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadSchedules(for proposal: TradeProposal, startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        []
    }

    func createSchedule(_ input: PersonalScheduleCreateInput) async throws -> PersonalSchedule {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadGrooms(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost] {
        []
    }

    func loadGroomMapPosts(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost] {
        try await loadGrooms(latitude: latitude, longitude: longitude, radiusMeters: radiusMeters)
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

    func registerNativePushDeviceToken(_ token: String, appVersion: String?) async throws {}

    func revokeNativePushDeviceToken(_ token: String, revokedAt: Date) async throws {}

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
            listings: NativePreviewData.listings,
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
            let matchesMember = input.memberID == nil || item.memberID == input.memberID
            let matchesGoodsType = input.goodsTypeID == nil || item.goodsTypeID == input.goodsTypeID
            return matchesQuery && matchesGroup && matchesMember && matchesGoodsType
        }
        .prefix(max(0, input.limit))
        .map { $0 }
    }

    public func archiveGoodsItem(itemID: UUID) async throws {}

    public func deleteGoodsItem(itemID: UUID) async throws {}

    public func reportGoods(_ input: GoodsReportCreateInput) async throws -> GoodsReportTicket {
        GoodsReportTicket(
            id: UUID(),
            goodsItemID: input.goodsItemID,
            status: "open"
        )
    }

    public func loadIndividualListings() async throws -> [IndividualListing] {
        NativePreviewData.listings
    }

    public func createIndividualListing(_ input: IndividualListingCreateInput) async throws -> IndividualListing {
        let listingID = UUID()
        let option = IndividualListingWishOption(
            id: UUID(),
            listingID: listingID,
            position: 1,
            wishes: input.wishItems,
            logic: input.wishLogic,
            exchangeType: input.exchangeType
        )
        return IndividualListing(
            id: listingID,
            ownerID: NativePreviewData.viewerID,
            haves: input.haveItems,
            haveLogic: input.haveLogic,
            status: .active,
            note: input.note,
            options: [option]
        )
    }

    public func loadPublicTradeGoods(userID: UUID, limit: Int) async throws -> [GoodsItem] {
        Array(NativePreviewData.inventory.filter { item in
            item.ownerID == userID
        }.prefix(max(0, limit)))
    }

    public func loadPublicIndividualListings(userID: UUID) async throws -> [IndividualListing] {
        NativePreviewData.publicListings.filter { listing in
            listing.ownerID == userID && listing.status == .active
        }
    }

    public func loadPublicUserProfile(userID: UUID) async throws -> PublicUserProfile? {
        let profile: UserProfile
        if userID == NativePreviewData.viewerID {
            profile = NativePreviewData.viewer
        } else {
            profile = NativePreviewData.partner
        }

        let evaluations = try await loadUserEvaluations(userID: userID, limit: 100)
        let average = evaluations.isEmpty
            ? nil
            : Double(evaluations.map(\.stars).reduce(0, +)) / Double(evaluations.count)
        return PublicUserProfile(
            profile: profile,
            averageStars: average,
            evaluationCount: evaluations.count,
            completedTradeCount: 12
        )
    }

    public func loadUserEvaluations(userID: UUID, limit: Int) async throws -> [UserEvaluation] {
        Array(NativePreviewData.userEvaluations.prefix(max(0, limit)))
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
            conditionTags: input.conditionTags,
            agreedBySender: [.sent, .negotiating, .agreementOneSide, .agreed].contains(input.status),
            agreedByReceiver: input.status == .agreed
        )
    }

    public func agreeProposal(proposalID: UUID, acceptedExchangeMethod: ExchangeMethod?) async throws -> TradeProposal {
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.partnerID,
                receiverID: NativePreviewData.viewerID,
                status: .sent,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: []
            )
        let resolvedExchangeMethod = try resolvedAcceptanceExchangeMethod(for: proposal, selectedMethod: acceptedExchangeMethod)
        let agreedBySender = proposal.isSender(NativePreviewData.viewerID) ? true : (proposal.agreedBySender || proposal.status == .sent)
        let agreedByReceiver = proposal.isSender(NativePreviewData.viewerID) ? proposal.agreedByReceiver : true
        return TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: agreedBySender && agreedByReceiver ? .agreed : .agreementOneSide,
            exchangeMethod: resolvedExchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            agreedBySender: agreedBySender,
            agreedByReceiver: agreedByReceiver,
            evidencePhotoURL: proposal.evidencePhotoURL,
            evidenceTakenAt: proposal.evidenceTakenAt,
            evidenceTakenBy: proposal.evidenceTakenBy,
            approvedBySender: proposal.approvedBySender,
            approvedByReceiver: proposal.approvedByReceiver,
            completedAt: proposal.completedAt,
            createdAt: proposal.createdAt
        )
    }

    public func rejectProposal(proposalID: UUID) async throws -> TradeProposal {
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.partnerID,
                receiverID: NativePreviewData.viewerID,
                status: .sent,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: []
            )
        return TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: .rejected,
            exchangeMethod: proposal.exchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            agreedBySender: proposal.agreedBySender,
            agreedByReceiver: proposal.agreedByReceiver,
            evidencePhotoURL: proposal.evidencePhotoURL,
            evidenceTakenAt: proposal.evidenceTakenAt,
            evidenceTakenBy: proposal.evidenceTakenBy,
            approvedBySender: proposal.approvedBySender,
            approvedByReceiver: proposal.approvedByReceiver,
            completedAt: proposal.completedAt,
            createdAt: proposal.createdAt
        )
    }

    public func addTradeEvidence(_ input: TradeEvidenceCreateInput) async throws -> TradeProposal {
        let proposal = NativePreviewData.proposals.first { $0.id == input.proposalID }
            ?? NativePreviewData.proposals.first
            ?? TradeProposal(
                id: input.proposalID,
                senderID: NativePreviewData.viewerID,
                receiverID: NativePreviewData.partnerID,
                status: .agreed,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: []
            )
        return TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: .agreed,
            exchangeMethod: proposal.exchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            agreedBySender: proposal.agreedBySender,
            agreedByReceiver: proposal.agreedByReceiver,
            evidencePhotoURL: URL(string: "https://example.com/evidence.jpg")!,
            evidenceTakenAt: .now,
            evidenceTakenBy: NativePreviewData.viewerID,
            approvedBySender: proposal.approvedBySender,
            approvedByReceiver: proposal.approvedByReceiver,
            completedAt: proposal.completedAt,
            createdAt: proposal.createdAt
        )
    }

    public func approveTradeEvidence(proposalID: UUID) async throws -> TradeProposal {
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.viewerID,
                receiverID: NativePreviewData.partnerID,
                status: .agreed,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: [],
                evidencePhotoURL: URL(string: "https://example.com/evidence.jpg")!
            )
        let approvedBySender = proposal.isSender(NativePreviewData.viewerID) ? true : proposal.approvedBySender
        let approvedByReceiver = proposal.isSender(NativePreviewData.viewerID) ? proposal.approvedByReceiver : true
        return TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: approvedBySender && approvedByReceiver ? .completed : .agreed,
            exchangeMethod: proposal.exchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            agreedBySender: proposal.agreedBySender,
            agreedByReceiver: proposal.agreedByReceiver,
            evidencePhotoURL: proposal.evidencePhotoURL ?? URL(string: "https://example.com/evidence.jpg")!,
            evidenceTakenAt: proposal.evidenceTakenAt ?? .now,
            evidenceTakenBy: proposal.evidenceTakenBy ?? NativePreviewData.viewerID,
            approvedBySender: approvedBySender,
            approvedByReceiver: approvedByReceiver,
            completedAt: approvedBySender && approvedByReceiver ? .now : proposal.completedAt,
            createdAt: proposal.createdAt
        )
    }

    public func submitTradeEvaluation(_ input: TradeEvaluationCreateInput) async throws -> UserEvaluation {
        UserEvaluation(
            id: UUID(),
            raterID: NativePreviewData.viewerID,
            raterHandle: NativePreviewData.viewer.handle,
            raterDisplayName: NativePreviewData.viewer.displayName,
            stars: input.stars,
            comment: input.comment
        )
    }

    public func fileTradeDispute(_ input: TradeDisputeCreateInput) async throws -> TradeDisputeTicket {
        TradeDisputeTicket(
            id: UUID(),
            proposalID: input.proposalID,
            ticketNo: "DPT-260531-0001",
            status: "submitted"
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

    public func sendLocationMessage(proposalID: UUID, latitude: Double, longitude: Double, label: String, body: String?) async throws -> TradeMessage {
        TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .location,
            body: body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank ?? label,
            locationLatitude: latitude,
            locationLongitude: longitude,
            locationLabel: label
        )
    }

    public func sendArrivalStatusMessage(proposalID: UUID, status: TradeArrivalStatus, body: String?) async throws -> TradeMessage {
        TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .arrivalStatus,
            body: body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank ?? status.defaultBody,
            meta: ["status": status.rawValue]
        )
    }

    public func loadSchedules(for proposal: TradeProposal, startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        guard proposal.isParticipant(NativePreviewData.viewerID) else {
            return []
        }
        let participantIDs = Set([proposal.senderID, proposal.receiverID])
        return NativePreviewData.schedules
            .filter { participantIDs.contains($0.userID) && $0.overlaps(start: startAt, end: endAt) }
            .sorted { $0.startAt < $1.startAt }
    }

    public func createSchedule(_ input: PersonalScheduleCreateInput) async throws -> PersonalSchedule {
        guard input.isValid else {
            throw MegrumRepositoryError.unsupportedMutation
        }
        return PersonalSchedule(
            id: UUID(),
            userID: NativePreviewData.viewerID,
            title: input.normalizedTitle,
            placeName: input.normalizedPlaceName,
            startAt: input.startAt,
            endAt: input.endAt,
            allDay: input.allDay,
            note: input.normalizedNote
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
                return thread.audience == .samePrefecture && (thread.prefecture == prefecture || prefecture == nil)
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

    public func registerNativePushDeviceToken(_ token: String, appVersion: String?) async throws {}

    public func revokeNativePushDeviceToken(_ token: String, revokedAt: Date) async throws {}
}

private func resolvedAcceptanceExchangeMethod(
    for proposal: TradeProposal,
    selectedMethod: ExchangeMethod?
) throws -> ExchangeMethod {
    switch proposal.exchangeMethod {
    case .both:
        guard let selectedMethod, selectedMethod != .both else {
            throw MegrumRepositoryError.unsupportedMutation
        }
        return selectedMethod
    case .hand, .mail:
        if let selectedMethod, selectedMethod != proposal.exchangeMethod {
            throw MegrumRepositoryError.unsupportedMutation
        }
        return proposal.exchangeMethod
    }
}

@MainActor
public final class MegrumAppState: ObservableObject {
    @Published public private(set) var viewer: UserProfile?
    @Published public private(set) var inventory: [GoodsItem] = []
    @Published public private(set) var wishes: [WishItem] = []
    @Published public private(set) var listings: [IndividualListing] = []
    @Published public private(set) var proposals: [TradeProposal] = []
    @Published public private(set) var messagesByProposalID: [UUID: [TradeMessage]] = [:]
    @Published public private(set) var schedulesByProposalID: [UUID: [PersonalSchedule]] = [:]
    @Published public private(set) var boardRepliesByThreadID: [UUID: [BoardReply]] = [:]
    @Published public private(set) var groomRepliesByPostID: [UUID: [GroomReply]] = [:]
    @Published public private(set) var meguriMessages: [MeguriMessage] = []
    @Published public private(set) var grooms: [GroomPost] = []
    @Published public private(set) var groomMapPosts: [GroomPost] = []
    @Published public private(set) var likedGroomIDs: Set<UUID> = []
    @Published public private(set) var threads: [BoardThread] = []
    @Published public private(set) var oshiGroups: [OshiGroup] = []
    @Published public private(set) var oshiCharacters: [OshiCharacter] = []
    @Published public private(set) var goodsTypes: [GoodsType] = []
    @Published public private(set) var searchResults: [SearchResultItem] = []
    @Published public private(set) var publicProfilesByUserID: [UUID: PublicUserProfile] = [:]
    @Published public private(set) var publicTradeGoodsByUserID: [UUID: [GoodsItem]] = [:]
    @Published public private(set) var publicListingsByUserID: [UUID: [IndividualListing]] = [:]
    @Published public private(set) var userEvaluationsByUserID: [UUID: [UserEvaluation]] = [:]
    @Published public private(set) var mailingAddress: MailingAddress?
    @Published public private(set) var blockedUsers: [BlockedUser] = []
    @Published public private(set) var notifications: [MegrumNotification] = []
    @Published public private(set) var pushNotificationsEnabled = true
    @Published public private(set) var isLoading = false
    @Published public private(set) var isLoadingOshiGroups = false
    @Published public private(set) var isLoadingOshiCharacters = false
    @Published public private(set) var isLoadingGoodsTypes = false
    @Published public private(set) var isSearchingGoods = false
    @Published public private(set) var loadingPublicProfileUserID: UUID?
    @Published public private(set) var loadingPublicExchangeUserID: UUID?
    @Published public private(set) var loadingEvaluationsUserID: UUID?
    @Published public private(set) var isLoadingMailingAddress = false
    @Published public private(set) var isLoadingBlockedUsers = false
    @Published public private(set) var isLoadingNotifications = false
    @Published public private(set) var isLoadingPushNotificationSetting = false
    @Published public private(set) var isRegisteringNativePushDevice = false
    @Published public private(set) var isRevokingNativePushDevice = false
    @Published public private(set) var isLoadingMeguri = false
    @Published public private(set) var isLoadingGroomMap = false
    @Published public private(set) var isLoadingMeguriMessages = false
    @Published public private(set) var isLookingUpPostalCode = false
    @Published public private(set) var isSavingMailingAddress = false
    @Published public private(set) var isCreatingGoodsEntry = false
    @Published public private(set) var isLoadingIndividualListings = false
    @Published public private(set) var isCreatingIndividualListing = false
    @Published public private(set) var mutatingGoodsItemID: UUID?
    @Published public private(set) var reportingGoodsItemID: UUID?
    @Published public private(set) var isCreatingProposal = false
    @Published public private(set) var addingEvidenceProposalID: UUID?
    @Published public private(set) var approvingEvidenceProposalID: UUID?
    @Published public private(set) var respondingProposalID: UUID?
    @Published public private(set) var submittingEvaluationProposalID: UUID?
    @Published public private(set) var filingDisputeProposalID: UUID?
    @Published public private(set) var isCreatingGroomPost = false
    @Published public private(set) var isCreatingBoardThread = false
    @Published public private(set) var loadingMessagesProposalID: UUID?
    @Published public private(set) var loadingSchedulesProposalID: UUID?
    @Published public private(set) var isCreatingSchedule = false
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
    private var registeredNativePushDeviceToken: String?

    public init(repository: any MegrumRepository = PreviewMegrumRepository()) {
        self.repository = repository
    }

    public var unreadNotificationCount: Int {
        notifications.filter(\.isUnread).count
    }

    public func messages(for proposalID: UUID) -> [TradeMessage] {
        messagesByProposalID[proposalID] ?? []
    }

    public func schedules(for proposalID: UUID) -> [PersonalSchedule] {
        schedulesByProposalID[proposalID] ?? []
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

    public func loadGroomMapPosts(
        latitude: Double? = nil,
        longitude: Double? = nil,
        radiusMeters: Int = 3_000
    ) async {
        guard !isLoadingGroomMap else {
            return
        }

        isLoadingGroomMap = true
        errorMessage = nil
        do {
            groomMapPosts = try await repository.loadGroomMapPosts(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters
            )
        } catch {
            errorMessage = "グルームマップを読み込めませんでした"
        }
        isLoadingGroomMap = false
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
            groomMapPosts.removeAll { $0.id == post.id }
            groomMapPosts.insert(post, at: 0)
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
        latitude: Double? = nil,
        longitude: Double? = nil,
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
                    latitude: latitude,
                    longitude: longitude,
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

    public func searchGoods(
        query: String,
        groupID: UUID? = nil,
        memberID: UUID? = nil,
        goodsTypeID: UUID? = nil
    ) async {
        let requestID = UUID()
        activeSearchRequestID = requestID
        isSearchingGoods = true
        errorMessage = nil
        do {
            let items = try await repository.searchGoods(
                GoodsSearchInput(
                    query: query,
                    groupID: groupID,
                    memberID: memberID,
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

    public func archiveGoodsItem(_ itemID: UUID) async -> Bool {
        guard mutatingGoodsItemID != itemID else {
            return false
        }

        mutatingGoodsItemID = itemID
        errorMessage = nil
        do {
            try await repository.archiveGoodsItem(itemID: itemID)
            removeGoodsItemLocally(itemID)
            mutatingGoodsItemID = nil
            return true
        } catch {
            errorMessage = "グッズを非表示にできませんでした"
            mutatingGoodsItemID = nil
            return false
        }
    }

    public func deleteGoodsItem(_ itemID: UUID) async -> Bool {
        guard mutatingGoodsItemID != itemID else {
            return false
        }

        mutatingGoodsItemID = itemID
        errorMessage = nil
        do {
            try await repository.deleteGoodsItem(itemID: itemID)
            removeGoodsItemLocally(itemID)
            mutatingGoodsItemID = nil
            return true
        } catch {
            errorMessage = "グッズを削除できませんでした"
            mutatingGoodsItemID = nil
            return false
        }
    }

    public func reportGoods(
        itemID: UUID,
        reportedUserID: UUID,
        reason: GoodsReportReason,
        note: String
    ) async -> Bool {
        guard reportingGoodsItemID != itemID else {
            return false
        }
        guard viewer?.id != reportedUserID else {
            errorMessage = "自分のグッズは通報できません"
            return false
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        reportingGoodsItemID = itemID
        errorMessage = nil
        do {
            _ = try await repository.reportGoods(
                GoodsReportCreateInput(
                    goodsItemID: itemID,
                    reportedUserID: reportedUserID,
                    reason: reason,
                    note: trimmedNote.nilIfBlank
                )
            )
            reportingGoodsItemID = nil
            return true
        } catch {
            errorMessage = "通報を送信できませんでした"
            reportingGoodsItemID = nil
            return false
        }
    }

    public func loadIndividualListings() async {
        guard !isLoadingIndividualListings else {
            return
        }

        isLoadingIndividualListings = true
        errorMessage = nil
        do {
            listings = try await repository.loadIndividualListings()
        } catch {
            errorMessage = "個別募集を読み込めませんでした"
        }
        isLoadingIndividualListings = false
    }

    public func createIndividualListing(_ input: IndividualListingCreateInput) async -> Bool {
        guard !isCreatingIndividualListing else {
            return false
        }
        guard !input.haveItems.isEmpty, !input.wishItems.isEmpty else {
            errorMessage = "譲るものと求めるものを選択してください"
            return false
        }

        let normalizedInput = IndividualListingCreateInput(
            haveItems: input.haveItems.map { ListingItemQuantity(itemID: $0.itemID, quantity: max(1, min($0.quantity, 99))) },
            haveLogic: input.haveLogic,
            wishItems: input.wishItems.map { ListingItemQuantity(itemID: $0.itemID, quantity: max(1, min($0.quantity, 99))) },
            wishLogic: input.wishLogic,
            exchangeType: input.exchangeType,
            note: input.note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        )

        isCreatingIndividualListing = true
        errorMessage = nil
        do {
            let created = try await repository.createIndividualListing(normalizedInput)
            listings.removeAll { $0.id == created.id }
            listings.insert(created, at: 0)
            isCreatingIndividualListing = false
            return true
        } catch {
            errorMessage = "個別募集を作成できませんでした"
            isCreatingIndividualListing = false
            return false
        }
    }

    public func loadPublicUserProfile(userID: UUID) async {
        guard loadingPublicProfileUserID != userID else {
            return
        }
        loadingPublicProfileUserID = userID
        errorMessage = nil
        do {
            if let profile = try await repository.loadPublicUserProfile(userID: userID) {
                publicProfilesByUserID[userID] = profile
            }
        } catch {
            errorMessage = "プロフィールを読み込めませんでした"
        }
        loadingPublicProfileUserID = nil
    }

    public func loadPublicExchangeContent(userID: UUID) async {
        guard loadingPublicExchangeUserID != userID else {
            return
        }
        loadingPublicExchangeUserID = userID
        errorMessage = nil
        do {
            async let tradeGoods = repository.loadPublicTradeGoods(userID: userID, limit: 60)
            async let listings = repository.loadPublicIndividualListings(userID: userID)
            publicTradeGoodsByUserID[userID] = try await tradeGoods
            publicListingsByUserID[userID] = try await listings
        } catch {
            errorMessage = "プロフィールの交換情報を読み込めませんでした"
        }
        loadingPublicExchangeUserID = nil
    }

    public func loadUserEvaluations(userID: UUID, limit: Int = 50) async {
        guard loadingEvaluationsUserID != userID else {
            return
        }
        loadingEvaluationsUserID = userID
        errorMessage = nil
        do {
            userEvaluationsByUserID[userID] = try await repository.loadUserEvaluations(userID: userID, limit: limit)
        } catch {
            errorMessage = "評価を読み込めませんでした"
        }
        loadingEvaluationsUserID = nil
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

    public func agreeProposal(proposalID: UUID, acceptedExchangeMethod: ExchangeMethod? = nil) async -> Bool {
        guard respondingProposalID != proposalID else {
            return false
        }

        respondingProposalID = proposalID
        errorMessage = nil
        do {
            let proposal = try await repository.agreeProposal(
                proposalID: proposalID,
                acceptedExchangeMethod: acceptedExchangeMethod
            )
            replaceProposal(proposal)
            respondingProposalID = nil
            await loadMessages(proposalID: proposalID)
            return true
        } catch {
            errorMessage = "打診を承諾できませんでした"
            respondingProposalID = nil
            return false
        }
    }

    public func rejectProposal(proposalID: UUID) async -> Bool {
        guard respondingProposalID != proposalID else {
            return false
        }

        respondingProposalID = proposalID
        errorMessage = nil
        do {
            let proposal = try await repository.rejectProposal(proposalID: proposalID)
            replaceProposal(proposal)
            respondingProposalID = nil
            await loadMessages(proposalID: proposalID)
            return true
        } catch {
            errorMessage = "打診を断れませんでした"
            respondingProposalID = nil
            return false
        }
    }

    public func addTradeEvidence(proposalID: UUID, imageData: Data, imageContentType: String) async -> Bool {
        guard addingEvidenceProposalID != proposalID else {
            return false
        }
        guard !imageData.isEmpty else {
            errorMessage = "証跡に使う写真を選択してください"
            return false
        }

        addingEvidenceProposalID = proposalID
        errorMessage = nil
        do {
            let proposal = try await repository.addTradeEvidence(
                TradeEvidenceCreateInput(
                    proposalID: proposalID,
                    imageData: imageData,
                    imageContentType: imageContentType
                )
            )
            replaceProposal(proposal)
            addingEvidenceProposalID = nil
            await loadMessages(proposalID: proposalID)
            return true
        } catch {
            errorMessage = "証跡写真を追加できませんでした"
            addingEvidenceProposalID = nil
            return false
        }
    }

    public func approveTradeEvidence(proposalID: UUID) async -> Bool {
        guard approvingEvidenceProposalID != proposalID else {
            return false
        }

        approvingEvidenceProposalID = proposalID
        errorMessage = nil
        do {
            let proposal = try await repository.approveTradeEvidence(proposalID: proposalID)
            replaceProposal(proposal)
            approvingEvidenceProposalID = nil
            await loadMessages(proposalID: proposalID)
            return true
        } catch {
            errorMessage = "証跡を承認できませんでした"
            approvingEvidenceProposalID = nil
            return false
        }
    }

    public func submitTradeEvaluation(proposalID: UUID, stars: Int, comment: String?) async -> Bool {
        guard submittingEvaluationProposalID != proposalID else {
            return false
        }

        submittingEvaluationProposalID = proposalID
        errorMessage = nil
        do {
            _ = try await repository.submitTradeEvaluation(
                TradeEvaluationCreateInput(
                    proposalID: proposalID,
                    stars: stars,
                    comment: comment
                )
            )
            submittingEvaluationProposalID = nil
            return true
        } catch {
            errorMessage = "評価を送信できませんでした"
            submittingEvaluationProposalID = nil
            return false
        }
    }

    public func fileTradeDispute(
        proposalID: UUID,
        category: TradeDisputeCategory,
        factMemo: String
    ) async -> Bool {
        let trimmed = factMemo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "申告内容を入力してください"
            return false
        }
        guard filingDisputeProposalID != proposalID else {
            return false
        }

        filingDisputeProposalID = proposalID
        errorMessage = nil
        do {
            _ = try await repository.fileTradeDispute(
                TradeDisputeCreateInput(
                    proposalID: proposalID,
                    category: category,
                    factMemo: trimmed
                )
            )
            filingDisputeProposalID = nil
            await loadMessages(proposalID: proposalID)
            return true
        } catch {
            errorMessage = "申告を送信できませんでした"
            filingDisputeProposalID = nil
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

    public func sendLocationMessage(
        proposalID: UUID,
        latitude: Double,
        longitude: Double,
        label: String,
        body: String? = nil
    ) async -> Bool {
        let normalizedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedLabel.isEmpty, sendingMessageProposalID != proposalID else {
            return false
        }

        sendingMessageProposalID = proposalID
        errorMessage = nil
        do {
            let message = try await repository.sendLocationMessage(
                proposalID: proposalID,
                latitude: latitude,
                longitude: longitude,
                label: normalizedLabel,
                body: body
            )
            messagesByProposalID[proposalID, default: []].append(message)
            sendingMessageProposalID = nil
            return true
        } catch {
            errorMessage = "現在地を共有できませんでした"
            sendingMessageProposalID = nil
            return false
        }
    }

    public func sendArrivalStatusMessage(
        proposalID: UUID,
        status: TradeArrivalStatus,
        body: String? = nil
    ) async -> Bool {
        guard sendingMessageProposalID != proposalID else {
            return false
        }

        sendingMessageProposalID = proposalID
        errorMessage = nil
        do {
            let message = try await repository.sendArrivalStatusMessage(
                proposalID: proposalID,
                status: status,
                body: body
            )
            messagesByProposalID[proposalID, default: []].append(message)
            sendingMessageProposalID = nil
            return true
        } catch {
            errorMessage = "到着ステータスを送信できませんでした"
            sendingMessageProposalID = nil
            return false
        }
    }

    public func loadSchedules(for proposal: TradeProposal, startAt: Date, endAt: Date) async {
        guard loadingSchedulesProposalID != proposal.id else {
            return
        }
        guard startAt < endAt else {
            schedulesByProposalID[proposal.id] = []
            return
        }

        loadingSchedulesProposalID = proposal.id
        errorMessage = nil
        do {
            schedulesByProposalID[proposal.id] = try await repository.loadSchedules(
                for: proposal,
                startAt: startAt,
                endAt: endAt
            )
        } catch {
            errorMessage = "スケジュールを読み込めませんでした"
        }
        loadingSchedulesProposalID = nil
    }

    public func createSchedule(_ input: PersonalScheduleCreateInput, for proposal: TradeProposal? = nil) async -> Bool {
        guard input.isValid else {
            errorMessage = "予定名と時間を確認してください"
            return false
        }
        guard !isCreatingSchedule else {
            return false
        }

        isCreatingSchedule = true
        errorMessage = nil
        do {
            let schedule = try await repository.createSchedule(input)
            if let proposal {
                schedulesByProposalID[proposal.id, default: []].append(schedule)
                schedulesByProposalID[proposal.id]?.sort { $0.startAt < $1.startAt }
            }
            isCreatingSchedule = false
            return true
        } catch {
            errorMessage = "スケジュールを保存できませんでした"
            isCreatingSchedule = false
            return false
        }
    }

    private func replaceProposal(_ proposal: TradeProposal) {
        if let index = proposals.firstIndex(where: { $0.id == proposal.id }) {
            proposals[index] = proposal
        } else {
            proposals.insert(proposal, at: 0)
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

    @discardableResult
    public func registerNativePushDeviceToken(_ token: String, appVersion: String? = nil) async -> Bool {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else {
            return false
        }
        guard !isRegisteringNativePushDevice else {
            return false
        }

        isRegisteringNativePushDevice = true
        errorMessage = nil
        do {
            try await repository.registerNativePushDeviceToken(trimmedToken, appVersion: appVersion)
            registeredNativePushDeviceToken = trimmedToken
            isRegisteringNativePushDevice = false
            return true
        } catch {
            errorMessage = "モバイル通知の端末登録に失敗しました"
            isRegisteringNativePushDevice = false
            return false
        }
    }

    @discardableResult
    public func revokeRegisteredNativePushDeviceToken(revokedAt: Date = .now) async -> Bool {
        guard let registeredNativePushDeviceToken, !registeredNativePushDeviceToken.isEmpty else {
            return false
        }
        guard !isRevokingNativePushDevice else {
            return false
        }

        isRevokingNativePushDevice = true
        errorMessage = nil
        do {
            try await repository.revokeNativePushDeviceToken(
                registeredNativePushDeviceToken,
                revokedAt: revokedAt
            )
            self.registeredNativePushDeviceToken = nil
            isRevokingNativePushDevice = false
            return true
        } catch {
            errorMessage = "モバイル通知の端末登録を解除できませんでした"
            isRevokingNativePushDevice = false
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
        listings = snapshot.listings
        proposals = snapshot.proposals
        grooms = snapshot.grooms
        groomMapPosts = snapshot.grooms
        likedGroomIDs = Set(snapshot.grooms.filter(\.liked).map(\.id))
        threads = snapshot.threads
    }

    private func removeGoodsItemLocally(_ itemID: UUID) {
        inventory.removeAll { $0.id == itemID }
        wishes.removeAll { $0.id == itemID }
        searchResults.removeAll { $0.item.id == itemID }
        listings = listings.compactMap { listing in
            var next = listing
            next.haves.removeAll { $0.itemID == itemID }
            next.options = next.options.compactMap { option in
                var nextOption = option
                nextOption.wishes.removeAll { $0.itemID == itemID }
                return nextOption.wishes.isEmpty && !nextOption.isCashOffer ? nil : nextOption
            }
            return next.haves.isEmpty || next.options.isEmpty ? nil : next
        }
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
