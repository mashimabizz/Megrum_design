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
    public var subscriptionState: UserSubscriptionState

    public init(
        viewer: UserProfile,
        inventory: [GoodsItem],
        wishes: [WishItem],
        listings: [IndividualListing] = [],
        proposals: [TradeProposal],
        grooms: [GroomPost],
        threads: [BoardThread],
        subscriptionState: UserSubscriptionState = .free
    ) {
        self.viewer = viewer
        self.inventory = inventory
        self.wishes = wishes
        self.listings = listings
        self.proposals = proposals
        self.grooms = grooms
        self.threads = threads
        self.subscriptionState = subscriptionState
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
    public var oshiRequestID: UUID?
    public var characterRequestID: UUID?
    public var kind: OshiKind
    public var priority: Int

    public init(
        groupID: UUID?,
        characterID: UUID?,
        kind: OshiKind,
        priority: Int = 1,
        oshiRequestID: UUID? = nil,
        characterRequestID: UUID? = nil
    ) {
        self.groupID = groupID
        self.characterID = characterID
        self.oshiRequestID = oshiRequestID
        self.characterRequestID = characterRequestID
        self.kind = kind
        self.priority = priority
    }
}

public struct OwnProfileUpdateInput: Equatable, Sendable {
    public var handle: String
    public var displayName: String
    public var gender: UserGender?
    public var prefecture: String?
    public var paymentMethods: [UserPaymentMethod]
    public var avatarURL: URL?
    public var avatarUpload: GoodsPhotoUpload?
    public var clearsAvatar: Bool

    public init(
        handle: String,
        displayName: String,
        gender: UserGender? = nil,
        prefecture: String? = nil,
        paymentMethods: [UserPaymentMethod] = [],
        avatarURL: URL? = nil,
        avatarUpload: GoodsPhotoUpload? = nil,
        clearsAvatar: Bool = false
    ) {
        self.handle = handle
        self.displayName = displayName
        self.gender = gender
        self.prefecture = prefecture
        self.paymentMethods = paymentMethods
        self.avatarURL = avatarURL
        self.avatarUpload = avatarUpload
        self.clearsAvatar = clearsAvatar
    }
}

public enum MegrumRepositoryError: Error, Equatable, Sendable {
    case unsupportedMutation
}

public protocol MegrumRepository: Sendable {
    func loadInitialSnapshot() async throws -> MegrumAppSnapshot
    func loadSubscriptionState() async throws -> UserSubscriptionState
    func loadHomeCandidateSections() async throws -> HomeCandidateSections
    func loadOshiGenres(limit: Int) async throws -> [OshiGenre]
    func loadOshiGroups(searchText: String?, limit: Int) async throws -> [OshiGroup]
    func loadOshiCharacters(groupID: UUID, limit: Int) async throws -> [OshiCharacter]
    func loadMemberFaceProfiles(memberIDs: [UUID], limit: Int) async throws -> [MemberFaceProfile]
    func loadUserOshiSelections() async throws -> [UserOshiSelection]
    func saveUserOshiSelections(_ selections: [AccountSetupOshiInput]) async throws -> [UserOshiSelection]
    func createOshiRequest(_ input: OshiRequestCreateInput) async throws -> UUID
    func createCharacterRequest(_ input: CharacterRequestCreateInput) async throws -> UUID
    func loadGoodsTypes(limit: Int) async throws -> [GoodsType]
    func createGoodsEntry(_ input: GoodsEntryInput) async throws -> GoodsItem
    func updateGoodsEntry(itemID: UUID, kind: GoodsEntryKind, input: GoodsEntryUpdateInput) async throws -> GoodsItem
    func searchGoods(_ input: GoodsSearchInput) async throws -> [GoodsItem]
    func archiveGoodsItem(itemID: UUID) async throws
    func deleteGoodsItem(itemID: UUID) async throws
    func reportGoods(_ input: GoodsReportCreateInput) async throws -> GoodsReportTicket
    func loadIndividualListings() async throws -> [IndividualListing]
    func createIndividualListing(_ input: IndividualListingCreateInput) async throws -> IndividualListing
    func updateIndividualListing(
        listingID: UUID,
        primaryOptionID: UUID?,
        input: IndividualListingCreateInput,
        status: IndividualListingStatus
    ) async throws -> IndividualListing
    func archiveIndividualListing(listingID: UUID) async throws
    func loadPublicTradeGoods(userID: UUID, limit: Int) async throws -> [GoodsItem]
    func loadPublicIndividualListings(userID: UUID) async throws -> [IndividualListing]
    func loadPublicUserProfile(userID: UUID) async throws -> PublicUserProfile?
    func loadUserEvaluations(userID: UUID, limit: Int) async throws -> [UserEvaluation]
    func createProposal(_ input: ProposalCreateInput) async throws -> TradeProposal
    func agreeProposal(proposalID: UUID, acceptedExchangeMethod: ExchangeMethod?) async throws -> TradeProposal
    func rejectProposal(proposalID: UUID) async throws -> TradeProposal
    func approveTradeCancel(proposalID: UUID) async throws -> (proposal: TradeProposal, message: TradeMessage)
    func addTradeEvidence(_ input: TradeEvidenceCreateInput) async throws -> TradeProposal
    func loadTradeEvidencePhotos(proposalID: UUID) async throws -> [TradeEvidencePhoto]
    func deleteTradeEvidencePhoto(proposalID: UUID, photoID: UUID) async throws -> TradeProposal
    func approveTradeEvidence(proposalID: UUID) async throws -> TradeProposal
    func submitTradeEvaluation(_ input: TradeEvaluationCreateInput) async throws -> UserEvaluation
    func fileTradeDispute(_ input: TradeDisputeCreateInput) async throws -> TradeDisputeTicket
    func loadMessages(proposalID: UUID, limit: Int) async throws -> [TradeMessage]
    func loadProposalReadState(proposalID: UUID, userID: UUID) async throws -> ProposalReadState?
    func markProposalMessagesRead(proposalID: UUID, userID: UUID, lastReadAt: Date) async throws -> ProposalReadState?
    func sendMessage(_ input: TradeMessageCreateInput) async throws -> TradeMessage
    func sendPhotoMessage(_ input: TradePhotoMessageCreateInput) async throws -> TradeMessage
    func sendSystemMessage(proposalID: UUID, body: String) async throws -> TradeMessage
    func sendLateNoticeMessage(proposalID: UUID, lateMinutes: Int, reason: String, note: String?) async throws -> TradeMessage
    func sendCancelRequestMessage(proposalID: UUID, reason: String, note: String?) async throws -> TradeMessage
    func sendLocationMessage(proposalID: UUID, latitude: Double, longitude: Double, label: String, body: String?) async throws -> TradeMessage
    func sendArrivalStatusMessage(proposalID: UUID, status: TradeArrivalStatus, body: String?) async throws -> TradeMessage
    func loadSchedules(for proposal: TradeProposal, startAt: Date, endAt: Date) async throws -> [PersonalSchedule]
    func loadPersonalSchedules(startAt: Date, endAt: Date) async throws -> [PersonalSchedule]
    func loadProfileSchedules(userID: UUID, startAt: Date, endAt: Date) async throws -> [PersonalSchedule]
    func createSchedule(_ input: PersonalScheduleCreateInput) async throws -> PersonalSchedule
    func loadHomeLocalModeSettings(now: Date) async throws -> HomeLocalActivitySettings?
    func saveHomeLocalModeSettings(_ settings: HomeLocalActivitySettings, now: Date) async throws -> HomeLocalActivitySettings
    func loadGrooms(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost]
    func loadGroomMapPosts(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost]
    func loadOwnGroomArchive(limit: Int) async throws -> [GroomPost]
    func loadGroomReactions(postIDs: [UUID]) async throws -> [GroomReaction]
    func loadGroomReplies(postIDs: [UUID]) async throws -> [GroomReply]
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
    func loadPaymentSettings() async throws -> UserPaymentSettings?
    func savePaymentSettings(_ settings: UserPaymentSettings) async throws -> (profile: UserProfile, settings: UserPaymentSettings)
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
    func updateOwnProfile(_ input: OwnProfileUpdateInput) async throws -> UserProfile
    func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile
}
