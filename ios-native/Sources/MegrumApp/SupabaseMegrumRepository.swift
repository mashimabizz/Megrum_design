import Foundation
import MegrumCore
import MegrumData

public struct SupabaseMegrumRepository: MegrumRepository {
    private let client: SupabaseRESTClient
    private let oshiClient: SupabaseOshiClient
    private let accountProfilePersistence: SupabaseAccountProfilePersistence
    private let ownedGoodsPersistence: SupabaseOwnedGoodsPersistence
    private let initialSnapshotLoader: SupabaseInitialSnapshotLoader
    private let goodsInventoryClient: SupabaseGoodsInventoryClient
    private let goodsEntryPersistence: SupabaseGoodsEntryPersistence
    private let goodsReportClient: SupabaseGoodsReportClient
    private let listingClient: SupabaseListingClient
    private let mailingAddressClient: SupabaseMailingAddressClient
    private let postalCodeAddressClient: PostalCodeAddressClient
    private let blockClient: SupabaseBlockClient
    private let notificationClient: SupabaseNotificationClient
    private let proposalClient: SupabaseProposalClient
    private let disputeClient: SupabaseDisputeClient
    private let messageClient: SupabaseMessageClient
    private let tradeSchedulePersistence: SupabaseTradeSchedulePersistence
    private let homeLocalModePersistence: SupabaseHomeLocalModePersistence
    private let groomClient: SupabaseGroomClient
    private let meguriMessageClient: SupabaseMeguriMessageClient
    private let boardClient: SupabaseBoardClient
    private let publicProfilePersistence: SupabasePublicProfilePersistence
    private let homeClient: SupabaseHomeClient
    private let paymentSettingsPersistence: SupabasePaymentSettingsPersistence
    private let faceRecognitionClient: SupabaseFaceRecognitionClient
    private let chatPhotoStorage: SupabaseChatPhotoStorage
    private let entitlementClient: SupabaseEntitlementClient
    private let viewerID: UUID

    public init(client: SupabaseRESTClient, viewerID: UUID) {
        self.client = client
        let oshiClient = SupabaseOshiClient(client: client)
        self.oshiClient = oshiClient
        let accountProfilePersistence = SupabaseAccountProfilePersistence(
            client: client,
            oshiClient: oshiClient,
            profilePhotoStorage: SupabaseProfilePhotoStorage(client: client),
            userID: viewerID
        )
        self.accountProfilePersistence = accountProfilePersistence
        let ownedGoodsPersistence = SupabaseOwnedGoodsPersistence(client: client, userID: viewerID)
        self.ownedGoodsPersistence = ownedGoodsPersistence
        let goodsInventoryClient = SupabaseGoodsInventoryClient(client: client)
        self.goodsInventoryClient = goodsInventoryClient
        self.goodsEntryPersistence = SupabaseGoodsEntryPersistence(
            goodsInventoryClient: goodsInventoryClient,
            userID: viewerID
        )
        self.goodsReportClient = SupabaseGoodsReportClient(client: client)
        let listingClient = SupabaseListingClient(client: client)
        self.listingClient = listingClient
        self.mailingAddressClient = SupabaseMailingAddressClient(client: client)
        self.postalCodeAddressClient = PostalCodeAddressClient()
        self.blockClient = SupabaseBlockClient(client: client)
        self.notificationClient = SupabaseNotificationClient(client: client)
        let proposalClient = SupabaseProposalClient(client: client)
        self.proposalClient = proposalClient
        self.disputeClient = SupabaseDisputeClient(client: client)
        self.messageClient = SupabaseMessageClient(client: client)
        self.tradeSchedulePersistence = SupabaseTradeSchedulePersistence(
            scheduleClient: SupabaseScheduleClient(client: client),
            userID: viewerID
        )
        self.homeLocalModePersistence = SupabaseHomeLocalModePersistence(
            activityWindowClient: SupabaseActivityWindowClient(client: client),
            userID: viewerID
        )
        let groomClient = SupabaseGroomClient(client: client)
        self.groomClient = groomClient
        self.meguriMessageClient = SupabaseMeguriMessageClient(client: client)
        let boardClient = SupabaseBoardClient(client: client)
        self.boardClient = boardClient
        self.publicProfilePersistence = SupabasePublicProfilePersistence(
            userProfileClient: SupabaseUserProfileClient(client: client),
            oshiClient: oshiClient
        )
        self.homeClient = SupabaseHomeClient(client: client)
        self.paymentSettingsPersistence = SupabasePaymentSettingsPersistence(client: client)
        self.faceRecognitionClient = SupabaseFaceRecognitionClient(client: client)
        self.chatPhotoStorage = SupabaseChatPhotoStorage(client: client)
        self.entitlementClient = SupabaseEntitlementClient(client: client)
        self.viewerID = viewerID
        self.initialSnapshotLoader = SupabaseInitialSnapshotLoader(
            accountProfilePersistence: accountProfilePersistence,
            ownedGoodsPersistence: ownedGoodsPersistence,
            listingClient: listingClient,
            proposalClient: proposalClient,
            groomClient: groomClient,
            boardClient: boardClient,
            userID: viewerID
        )
    }

    public func loadInitialSnapshot() async throws -> MegrumAppSnapshot {
        try await initialSnapshotLoader.loadSnapshot()
    }

    public func loadSubscriptionState() async throws -> UserSubscriptionState {
        try await entitlementClient.loadSubscriptionState(userID: viewerID)
    }

    public func loadHomeCandidateSections() async throws -> HomeCandidateSections {
        let composition = try await homeClient.loadHomeComposition(userID: viewerID)
        return HomeCandidateComposer.sections(from: composition)
    }

    public func loadOshiGroups(searchText: String?, limit: Int) async throws -> [OshiGroup] {
        try await oshiClient.loadGroups(searchText: searchText, limit: limit)
    }

    public func loadOshiGenres(limit: Int) async throws -> [OshiGenre] {
        try await oshiClient.loadGenres(limit: limit)
    }

    public func loadOshiCharacters(groupID: UUID, limit: Int) async throws -> [OshiCharacter] {
        try await oshiClient.loadCharacters(groupID: groupID, limit: limit)
    }

    public func loadMemberFaceProfiles(memberIDs: [UUID], limit: Int) async throws -> [MemberFaceProfile] {
        try await faceRecognitionClient.loadMemberFaceProfiles(memberIDs: memberIDs, limit: limit)
    }

    public func loadUserOshiSelections() async throws -> [UserOshiSelection] {
        try await oshiClient.loadUserSelections(userID: viewerID)
    }

    public func saveUserOshiSelections(_ selections: [AccountSetupOshiInput]) async throws -> [UserOshiSelection] {
        let rows = UserOshiSelectionPersistenceMapper.selections(from: selections, userID: viewerID)
        return try await oshiClient.replaceUserSelections(userID: viewerID, selections: rows)
    }

    public func createOshiRequest(_ input: OshiRequestCreateInput) async throws -> UUID {
        try await oshiClient.createOshiRequest(userID: viewerID, input: input)
    }

    public func createCharacterRequest(_ input: CharacterRequestCreateInput) async throws -> UUID {
        try await oshiClient.createCharacterRequest(userID: viewerID, input: input)
    }

    public func loadGoodsTypes(limit: Int) async throws -> [GoodsType] {
        try await goodsInventoryClient.loadGoodsTypes(limit: limit)
    }

    public func createGoodsEntry(_ input: GoodsEntryInput) async throws -> GoodsItem {
        try await goodsEntryPersistence.createGoodsEntry(input)
    }

    public func updateGoodsEntry(itemID: UUID, kind: GoodsEntryKind, input: GoodsEntryUpdateInput) async throws -> GoodsItem {
        try await goodsEntryPersistence.updateGoodsEntry(itemID: itemID, input: input)
    }

    public func searchGoods(_ input: GoodsSearchInput) async throws -> [GoodsItem] {
        try await goodsInventoryClient.searchGoods(viewerID: viewerID, input: input)
    }

    public func archiveGoodsItem(itemID: UUID) async throws {
        _ = try await goodsInventoryClient.archiveGoodsItem(userID: viewerID, itemID: itemID)
    }

    public func deleteGoodsItem(itemID: UUID) async throws {
        try await goodsInventoryClient.deleteGoodsItem(userID: viewerID, itemID: itemID)
    }

    public func reportGoods(_ input: GoodsReportCreateInput) async throws -> GoodsReportTicket {
        try await goodsReportClient.createReport(reporterID: viewerID, input: input)
    }

    public func loadIndividualListings() async throws -> [IndividualListing] {
        try await listingClient.loadListings(userID: viewerID)
    }

    public func createIndividualListing(_ input: IndividualListingCreateInput) async throws -> IndividualListing {
        try await listingClient.createListing(userID: viewerID, input: input)
    }

    public func updateIndividualListing(
        listingID: UUID,
        primaryOptionID: UUID?,
        input: IndividualListingCreateInput,
        status: IndividualListingStatus
    ) async throws -> IndividualListing {
        try await listingClient.updateListing(
            userID: viewerID,
            listingID: listingID,
            primaryOptionID: primaryOptionID,
            input: input,
            status: status
        )
    }

    public func archiveIndividualListing(listingID: UUID) async throws {
        try await listingClient.archiveListing(userID: viewerID, listingID: listingID)
    }

    public func loadPublicTradeGoods(userID: UUID, limit: Int) async throws -> [GoodsItem] {
        try await goodsInventoryClient.loadPublicTradeGoods(userID: userID, limit: limit)
    }

    public func loadPublicIndividualListings(userID: UUID) async throws -> [IndividualListing] {
        try await listingClient.loadPublicListings(userID: userID)
    }

    public func loadPublicUserProfile(userID: UUID) async throws -> PublicUserProfile? {
        try await publicProfilePersistence.loadProfile(userID: userID)
    }

    public func loadUserEvaluations(userID: UUID, limit: Int) async throws -> [UserEvaluation] {
        try await publicProfilePersistence.loadEvaluations(userID: userID, limit: limit)
    }

    public func createProposal(_ input: ProposalCreateInput) async throws -> TradeProposal {
        try await proposalClient.createProposal(senderID: viewerID, input: input)
    }

    public func agreeProposal(proposalID: UUID, acceptedExchangeMethod: ExchangeMethod?) async throws -> TradeProposal {
        try await proposalClient.agreeProposal(
            userID: viewerID,
            proposalID: proposalID,
            acceptedExchangeMethod: acceptedExchangeMethod
        )
    }

    public func rejectProposal(proposalID: UUID) async throws -> TradeProposal {
        try await proposalClient.rejectProposal(userID: viewerID, proposalID: proposalID)
    }

    public func addTradeEvidence(_ input: TradeEvidenceCreateInput) async throws -> TradeProposal {
        try await proposalClient.addEvidencePhoto(userID: viewerID, input: input)
    }

    public func loadTradeEvidencePhotos(proposalID: UUID) async throws -> [TradeEvidencePhoto] {
        try await proposalClient.loadEvidencePhotos(proposalID: proposalID)
    }

    public func deleteTradeEvidencePhoto(proposalID: UUID, photoID: UUID) async throws -> TradeProposal {
        try await proposalClient.deleteEvidencePhoto(userID: viewerID, proposalID: proposalID, photoID: photoID)
    }

    public func approveTradeEvidence(proposalID: UUID) async throws -> TradeProposal {
        try await proposalClient.approveEvidence(userID: viewerID, proposalID: proposalID)
    }

    public func submitTradeEvaluation(_ input: TradeEvaluationCreateInput) async throws -> UserEvaluation {
        try await proposalClient.submitEvaluation(userID: viewerID, input: input)
    }

    public func fileTradeDispute(_ input: TradeDisputeCreateInput) async throws -> TradeDisputeTicket {
        try await disputeClient.createDispute(userID: viewerID, input: input)
    }

    public func loadMessages(proposalID: UUID, limit: Int) async throws -> [TradeMessage] {
        try await messageClient.loadMessages(proposalID: proposalID, limit: limit)
    }

    public func loadProposalReadState(proposalID: UUID, userID: UUID) async throws -> ProposalReadState? {
        try await messageClient.loadProposalReadState(proposalID: proposalID, userID: userID)
    }

    public func markProposalMessagesRead(proposalID: UUID, userID: UUID, lastReadAt: Date) async throws -> ProposalReadState? {
        try await messageClient.markProposalMessagesRead(
            proposalID: proposalID,
            userID: userID,
            lastReadAt: lastReadAt
        )
    }

    public func sendMessage(_ input: TradeMessageCreateInput) async throws -> TradeMessage {
        try await messageClient.sendTextMessage(senderID: viewerID, input: input)
    }

    public func sendPhotoMessage(_ input: TradePhotoMessageCreateInput) async throws -> TradeMessage {
        let signedURL = try await chatPhotoStorage.uploadPhoto(input)
        return try await messageClient.sendPhotoMessage(
            senderID: viewerID,
            proposalID: input.proposalID,
            photoURL: signedURL,
            body: input.body,
            messageType: input.messageType
        )
    }

    public func sendSystemMessage(proposalID: UUID, body: String) async throws -> TradeMessage {
        try await messageClient.sendSystemMessage(senderID: viewerID, proposalID: proposalID, body: body)
    }

    public func sendLateNoticeMessage(
        proposalID: UUID,
        lateMinutes: Int,
        reason: String,
        note: String?
    ) async throws -> TradeMessage {
        try await messageClient.sendLateNoticeMessage(
            senderID: viewerID,
            proposalID: proposalID,
            lateMinutes: lateMinutes,
            reason: reason,
            note: note
        )
    }

    public func sendCancelRequestMessage(
        proposalID: UUID,
        reason: String,
        note: String?
    ) async throws -> TradeMessage {
        try await messageClient.sendCancelRequestMessage(
            senderID: viewerID,
            proposalID: proposalID,
            reason: reason,
            note: note
        )
    }

    public func approveTradeCancel(proposalID: UUID) async throws -> (proposal: TradeProposal, message: TradeMessage) {
        let proposal = try await proposalClient.approveCancel(userID: viewerID, proposalID: proposalID)
        let message = try await messageClient.sendCancelApprovedMessage(
            senderID: viewerID,
            proposalID: proposalID
        )
        return (proposal, message)
    }

    public func sendLocationMessage(
        proposalID: UUID,
        latitude: Double,
        longitude: Double,
        label: String,
        body: String?
    ) async throws -> TradeMessage {
        try await messageClient.sendLocationMessage(
            senderID: viewerID,
            proposalID: proposalID,
            latitude: latitude,
            longitude: longitude,
            label: label,
            body: body
        )
    }

    public func sendArrivalStatusMessage(
        proposalID: UUID,
        status: TradeArrivalStatus,
        body: String?
    ) async throws -> TradeMessage {
        try await messageClient.sendArrivalStatusMessage(
            senderID: viewerID,
            proposalID: proposalID,
            status: status,
            body: body
        )
    }

    public func loadSchedules(for proposal: TradeProposal, startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        try await tradeSchedulePersistence.loadSchedules(for: proposal, startAt: startAt, endAt: endAt)
    }

    public func loadPersonalSchedules(startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        try await tradeSchedulePersistence.loadPersonalSchedules(startAt: startAt, endAt: endAt)
    }

    public func loadProfileSchedules(userID: UUID, startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        try await tradeSchedulePersistence.loadProfileSchedules(userID: userID, startAt: startAt, endAt: endAt)
    }

    public func createSchedule(_ input: PersonalScheduleCreateInput) async throws -> PersonalSchedule {
        try await tradeSchedulePersistence.createSchedule(input)
    }

    public func loadHomeLocalModeSettings(now: Date) async throws -> HomeLocalActivitySettings? {
        try await homeLocalModePersistence.loadSettings(now: now)
    }

    public func saveHomeLocalModeSettings(
        _ settings: HomeLocalActivitySettings,
        now: Date
    ) async throws -> HomeLocalActivitySettings {
        try await homeLocalModePersistence.saveSettings(settings, now: now)
    }

    public func loadGrooms(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost] {
        try await groomClient.loadNearbyGrooms(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters
        )
    }

    public func loadGroomMapPosts(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost] {
        try await groomClient.loadGroomMapPosts(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters
        )
    }

    public func loadOwnGroomArchive(limit: Int) async throws -> [GroomPost] {
        try await groomClient.loadOwnGroomArchive(userID: viewerID, limit: limit)
    }

    public func loadGroomReactions(postIDs: [UUID]) async throws -> [GroomReaction] {
        try await groomClient.loadReactions(postIDs: postIDs)
    }

    public func loadGroomReplies(postIDs: [UUID]) async throws -> [GroomReply] {
        try await groomClient.loadReplies(postIDs: postIDs)
    }

    public func createGroomPost(_ input: GroomPostCreateInput) async throws -> GroomPost {
        try await groomClient.createPost(input)
    }

    public func markGroomViewed(postID: UUID) async throws {
        try await groomClient.markViewed(userID: viewerID, postID: postID)
    }

    public func setGroomLiked(postID: UUID, isLiked: Bool) async throws {
        try await groomClient.setLiked(userID: viewerID, postID: postID, isLiked: isLiked)
    }

    public func sendGroomReply(_ input: GroomReplyCreateInput) async throws -> GroomReply {
        try await groomClient.sendReply(input)
    }

    public func loadMeguriMessages() async throws -> [MeguriMessage] {
        try await meguriMessageClient.loadMessages()
    }

    public func sendMeguriMessage(_ input: MeguriMessageCreateInput) async throws -> MeguriMessage {
        try await meguriMessageClient.sendTextMessage(input)
    }

    public func markMeguriMessagesRead(peerID: UUID, readAt: Date) async throws -> [MeguriMessage] {
        try await meguriMessageClient.markConversationRead(viewerID: viewerID, peerID: peerID, readAt: readAt)
    }

    public func loadBoardThreads(
        latitude: Double?,
        longitude: Double?,
        prefecture: String?,
        scope: BoardThread.Audience
    ) async throws -> [BoardThread] {
        try await boardClient.loadThreads(
            latitude: latitude,
            longitude: longitude,
            prefecture: prefecture,
            scope: scope
        )
    }

    public func loadBoardReplies(
        threadID: UUID,
        latitude: Double?,
        longitude: Double?,
        prefecture: String?,
        scope: BoardThread.Audience
    ) async throws -> [BoardReply] {
        try await boardClient.loadReplies(
            threadID: threadID,
            latitude: latitude,
            longitude: longitude,
            prefecture: prefecture,
            scope: scope
        )
    }

    public func sendBoardReply(_ input: BoardReplyCreateInput) async throws -> BoardReply {
        try await boardClient.appendReply(input)
    }

    public func createBoardThread(_ input: BoardThreadCreateInput) async throws -> BoardThread {
        try await boardClient.createThread(input)
    }

    public func loadMailingAddress() async throws -> MailingAddress? {
        try await mailingAddressClient.loadAddress(userID: viewerID)
    }

    public func saveMailingAddress(_ address: MailingAddress) async throws -> MailingAddress {
        try await mailingAddressClient.upsertAddress(address)
    }

    public func loadPaymentSettings() async throws -> UserPaymentSettings? {
        try await paymentSettingsPersistence.loadSettings(userID: viewerID)
    }

    public func savePaymentSettings(_ settings: UserPaymentSettings) async throws -> (profile: UserProfile, settings: UserPaymentSettings) {
        try await paymentSettingsPersistence.saveSettings(settings, userID: viewerID)
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

    public func loadPushNotificationsEnabled() async throws -> Bool {
        try await notificationClient.loadPushNotificationsEnabled(userID: viewerID)
    }

    public func setPushNotificationsEnabled(_ enabled: Bool) async throws -> Bool {
        try await notificationClient.setPushNotificationsEnabled(userID: viewerID, enabled: enabled)
    }

    public func registerNativePushDeviceToken(_ token: String, appVersion: String?) async throws {
        _ = try await notificationClient.registerNativePushDevice(
            userID: viewerID,
            deviceToken: token,
            appVersion: appVersion
        )
    }

    public func revokeNativePushDeviceToken(_ token: String, revokedAt: Date) async throws {
        _ = try await notificationClient.revokeNativePushDevice(
            userID: viewerID,
            deviceToken: token,
            revokedAt: revokedAt
        )
    }

    public func updateOwnProfile(_ input: OwnProfileUpdateInput) async throws -> UserProfile {
        try await accountProfilePersistence.updateOwnProfile(input)
    }

    public func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        try await accountProfilePersistence.completeAccountSetup(input)
    }
}
