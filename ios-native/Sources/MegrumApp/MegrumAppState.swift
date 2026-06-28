import Combine
import Foundation
import MegrumCore

@MainActor
public final class MegrumAppState: ObservableObject {
    @Published public internal(set) var viewer: UserProfile?
    @Published public internal(set) var inventory: [GoodsItem] = []
    @Published public internal(set) var wishes: [WishItem] = []
    @Published public internal(set) var homeMatchedItems: [GoodsItem] = []
    @Published public internal(set) var homePossibleItems: [GoodsItem] = []
    @Published public internal(set) var homeCandidateConditionSignals: [UUID: HomeCandidateConditionSignals] = [:]
    @Published public internal(set) var homeMutualMatchCandidates: [HomeMutualMatchCandidateData] = []
    @Published public internal(set) var listings: [IndividualListing] = []
    @Published public internal(set) var proposals: [TradeProposal] = []
    @Published public internal(set) var messagesByProposalID: [UUID: [TradeMessage]] = [:]
    @Published public internal(set) var evidencePhotosByProposalID: [UUID: [TradeEvidencePhoto]] = [:]
    @Published public internal(set) var viewerReadAtByProposalID: [UUID: Date] = [:]
    @Published public internal(set) var partnerReadAtByProposalID: [UUID: Date] = [:]
    @Published public internal(set) var schedulesByProposalID: [UUID: [PersonalSchedule]] = [:]
    @Published public internal(set) var personalSchedules: [PersonalSchedule] = []
    @Published public internal(set) var profileSchedulesByUserID: [UUID: [PersonalSchedule]] = [:]
    @Published public internal(set) var boardRepliesByThreadID: [UUID: [BoardReply]] = [:]
    @Published public internal(set) var groomRepliesByPostID: [UUID: [GroomReply]] = [:]
    @Published public internal(set) var groomReactionsByPostID: [UUID: [GroomReaction]] = [:]
    @Published public internal(set) var meguriMessages: [MeguriMessage] = []
    @Published public internal(set) var meguriProfile: MeguriProfile?
    @Published public internal(set) var meguriProfilesByUserID: [UUID: MeguriProfile] = [:]
    @Published public internal(set) var grooms: [GroomPost] = []
    @Published public internal(set) var groomMapPosts: [GroomPost] = []
    @Published public internal(set) var ownGroomArchive: [GroomPost] = []
    @Published public internal(set) var viewedGroomIDs: Set<UUID> = []
    @Published public internal(set) var likedGroomIDs: Set<UUID> = []
    @Published public internal(set) var threads: [BoardThread] = []
    @Published public internal(set) var oshiGenres: [OshiGenre] = []
    @Published public internal(set) var oshiGroups: [OshiGroup] = []
    @Published public internal(set) var oshiCharacters: [OshiCharacter] = []
    @Published public internal(set) var userOshiSelections: [UserOshiSelection] = []
    @Published public internal(set) var goodsTypes: [GoodsType] = []
    @Published public internal(set) var searchResults: [SearchResultItem] = []
    @Published public internal(set) var publicProfilesByUserID: [UUID: PublicUserProfile] = [:]
    @Published public internal(set) var publicTradeGoodsByUserID: [UUID: [GoodsItem]] = [:]
    @Published public internal(set) var publicListingsByUserID: [UUID: [IndividualListing]] = [:]
    @Published public internal(set) var publicExchangeSettingsByUserID: [UUID: HomeDefaultExchangeSettings] = [:]
    @Published public internal(set) var userEvaluationsByUserID: [UUID: [UserEvaluation]] = [:]
    @Published public internal(set) var mailingAddress: MailingAddress?
    @Published public internal(set) var paymentSettings: UserPaymentSettings?
    @Published public internal(set) var exchangeSettings: HomeDefaultExchangeSettings?
    @Published public internal(set) var subscriptionState: UserSubscriptionState = .free
    @Published public internal(set) var blockedUsers: [BlockedUser] = []
    @Published public internal(set) var blockedContentUserIDs: Set<UUID> = []
    @Published public internal(set) var notifications: [MegrumNotification] = []
    @Published public internal(set) var pushNotificationsEnabled = true
    @Published public internal(set) var groomActivityPushNotificationsEnabled = true
    @Published public internal(set) var chatroomActivityPushNotificationsEnabled = true
    @Published public internal(set) var isLoading = false
    @Published public internal(set) var isLoadingOshiGroups = false
    @Published public internal(set) var isLoadingOshiCharacters = false
    @Published public internal(set) var isLoadingUserOshiSelections = false
    @Published public internal(set) var isLoadingGoodsTypes = false
    @Published public internal(set) var isSearchingGoods = false
    @Published public internal(set) var loadingPublicProfileUserID: UUID?
    @Published public internal(set) var loadingPublicExchangeUserID: UUID?
    @Published public internal(set) var loadingEvaluationsUserID: UUID?
    @Published public internal(set) var isLoadingMailingAddress = false
    @Published public internal(set) var isLoadingPaymentSettings = false
    @Published public internal(set) var isLoadingExchangeSettings = false
    @Published public internal(set) var isLoadingSubscriptionState = false
    @Published public internal(set) var isLoadingBlockedUsers = false
    @Published public internal(set) var isLoadingNotifications = false
    @Published public internal(set) var isLoadingPushNotificationSetting = false
    @Published public internal(set) var isRegisteringNativePushDevice = false
    @Published public internal(set) var isRevokingNativePushDevice = false
    @Published public internal(set) var isLoadingMeguri = false
    @Published public internal(set) var isLoadingMeguriProfile = false
    @Published public internal(set) var isSavingMeguriProfile = false
    @Published public internal(set) var isLoadingGroomMap = false
    @Published public internal(set) var isLoadingGroomArchive = false
    @Published public internal(set) var isLoadingMeguriMessages = false
    @Published public internal(set) var isLookingUpPostalCode = false
    @Published public internal(set) var isSavingMailingAddress = false
    @Published public internal(set) var isSavingPaymentSettings = false
    @Published public internal(set) var isSavingExchangeSettings = false
    @Published public internal(set) var isCreatingGoodsEntry = false
    @Published public internal(set) var isLoadingIndividualListings = false
    @Published public internal(set) var isCreatingIndividualListing = false
    @Published public internal(set) var updatingIndividualListingID: UUID?
    @Published public internal(set) var mutatingGoodsItemID: UUID?
    @Published public internal(set) var reportingGoodsItemID: UUID?
    @Published public internal(set) var isCreatingProposal = false
    @Published public internal(set) var addingEvidenceProposalID: UUID?
    @Published public internal(set) var deletingEvidencePhotoID: UUID?
    @Published public internal(set) var approvingEvidenceProposalID: UUID?
    @Published public internal(set) var respondingProposalID: UUID?
    @Published public internal(set) var submittingEvaluationProposalID: UUID?
    @Published public internal(set) var filingDisputeProposalID: UUID?
    @Published public internal(set) var isCreatingGroomPost = false
    @Published public internal(set) var isCreatingBoardThread = false
    @Published public internal(set) var reportingGroomPostID: UUID?
    @Published public internal(set) var blockingGroomUserID: UUID?
    @Published public internal(set) var reportingUserID: UUID?
    @Published public internal(set) var blockingUserID: UUID?
    @Published public internal(set) var loadingMessagesProposalID: UUID?
    @Published public internal(set) var loadingEvidencePhotosProposalID: UUID?
    @Published public internal(set) var loadingSchedulesProposalID: UUID?
    @Published public internal(set) var loadingProfileScheduleUserID: UUID?
    @Published public internal(set) var isLoadingPersonalSchedules = false
    @Published public internal(set) var isCreatingSchedule = false
    @Published public internal(set) var sendingMessageProposalID: UUID?
    @Published public internal(set) var sendingGroomReplyPostID: UUID?
    @Published public internal(set) var sendingMeguriMessageRecipientID: UUID?
    @Published public internal(set) var loadingBoardRepliesThreadID: UUID?
    @Published public internal(set) var sendingBoardReplyThreadID: UUID?
    @Published public internal(set) var unblockingUserID: UUID?
    @Published public internal(set) var isMarkingNotificationsRead = false
    @Published public internal(set) var isSavingPushNotificationSetting = false
    @Published public internal(set) var isSavingAccountSetup = false
    @Published public internal(set) var isSavingOwnProfile = false
    @Published public internal(set) var isRequestingAccountDeletion = false
    @Published public internal(set) var homeLocalModeSettings: HomeLocalActivitySettings?
    @Published public internal(set) var isLoadingHomeLocalModeSettings = false
    @Published public internal(set) var isSavingHomeLocalModeSettings = false
    @Published public internal(set) var errorMessage: String?

    var repository: any MegrumRepository
    var activeSearchRequestID: UUID?
    var registeredNativePushDeviceToken: String?
    var hasLoadedBlockedContentUserIDs = false
    private static weak var activeInstanceStorage: MegrumAppState?

    static var activeInstance: MegrumAppState? {
        activeInstanceStorage
    }

    public init(repository: any MegrumRepository = PreviewMegrumRepository()) {
        self.repository = repository
        Self.activeInstanceStorage = self
    }

    public var unreadNotificationCount: Int {
        NotificationReadStateReducer.unreadCount(in: notifications)
    }

    public var meguriUnreadMessageCount: Int {
        guard let viewer else {
            return 0
        }
        return MeguriMessageReadStateReducer.unreadIncomingCount(meguriMessages, viewerID: viewer.id)
    }

    public var meguriPendingReplyCount: Int {
        guard let viewer else {
            return 0
        }
        return MeguriMessageReadStateReducer.pendingReplyThreadCount(meguriMessages, viewerID: viewer.id)
    }

    public var meguriMessageThreads: [MeguriMessageThread] {
        guard let viewer else {
            return []
        }
        return MeguriMessageReadStateReducer.conversationThreads(
            from: meguriMessages,
            viewerID: viewer.id,
            publicProfilesByUserID: publicProfilesByUserID,
            meguriProfilesByUserID: meguriProfilesByUserID
        )
    }

    public func meguriProfile(for userID: UUID) -> MeguriProfile? {
        if userID == viewer?.id {
            return meguriProfile ?? meguriProfilesByUserID[userID]
        }
        return meguriProfilesByUserID[userID]
    }

    public func messages(for proposalID: UUID) -> [TradeMessage] {
        messagesByProposalID[proposalID] ?? []
    }

    public func partnerLastReadAt(for proposalID: UUID) -> Date? {
        partnerReadAtByProposalID[proposalID]
    }

    public func schedules(for proposalID: UUID) -> [PersonalSchedule] {
        schedulesByProposalID[proposalID] ?? []
    }

    public func profileSchedules(for userID: UUID) -> [PersonalSchedule] {
        profileSchedulesByUserID[userID] ?? []
    }

    public func clearErrorMessage() {
        errorMessage = nil
    }

    public func evidencePhotos(for proposal: TradeProposal) -> [TradeEvidencePhoto] {
        TradeEvidencePhotoStateReducer.photos(
            for: proposal,
            in: evidencePhotosByProposalID,
            viewerID: viewer?.id
        )
    }

    public func boardReplies(for threadID: UUID) -> [BoardReply] {
        boardRepliesByThreadID[threadID] ?? []
    }

    public func groomReplies(for postID: UUID) -> [GroomReply] {
        groomRepliesByPostID[postID] ?? []
    }

    public func groomReactions(for postID: UUID) -> [GroomReaction] {
        groomReactionsByPostID[postID] ?? []
    }

    public func meguriMessages(with peerID: UUID) -> [MeguriMessage] {
        meguriMessages.filter { message in
            message.senderID == peerID || message.recipientID == peerID
        }
    }

    public func isGroomLiked(_ postID: UUID) -> Bool {
        likedGroomIDs.contains(postID)
    }

    public func groomLikeCount(_ postID: UUID, fallback: Int = 0) -> Int {
        groomPost(postID)?.likeCount ?? fallback
    }

    private func groomPost(_ postID: UUID) -> GroomPost? {
        grooms.first { $0.id == postID }
            ?? groomMapPosts.first { $0.id == postID }
            ?? ownGroomArchive.first { $0.id == postID }
    }

    public func loadInitialData() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let snapshot = try await repository.loadInitialSnapshot()
            apply(snapshot)
            await loadBlockedContentUserIDs(reportsFailure: false)
            await loadHomeCandidates(fallbackInventory: snapshot.inventory)
            await loadSubscriptionState(reportsFailure: false)
            await loadMeguriProfile(reportsFailure: false)
            await loadMeguriMessages(reportsFailure: false)
        } catch {
            errorMessage = "データを読み込めませんでした"
        }

        isLoading = false
    }

    public func refresh() async {
        await refreshHomeDiscovery()
    }

    public func refreshHomeDiscovery() async {
        errorMessage = nil
        do {
            let snapshot = try await repository.loadInitialSnapshot()
            apply(snapshot)
            await loadBlockedContentUserIDs(reportsFailure: false)
            await loadHomeCandidates(fallbackInventory: snapshot.inventory)
            await loadSubscriptionState(reportsFailure: false)
            await loadMeguriProfile(reportsFailure: false)
            await loadMeguriMessages(reportsFailure: false)
        } catch {
            errorMessage = "ホームを更新できませんでした"
        }
    }

    public func refreshHomeCandidates(reportsFailure: Bool = false) async {
        do {
            await loadBlockedContentUserIDsIfNeeded(reportsFailure: false)
            let sections = try await repository.loadHomeCandidateSections()
            applyHomeCandidateSections(sections, fallbackInventory: inventory)
        } catch {
            if reportsFailure {
                errorMessage = "ホームの候補を更新できませんでした"
            }
        }
    }

    private func loadHomeCandidates(fallbackInventory: [GoodsItem]) async {
        do {
            let sections = try await repository.loadHomeCandidateSections()
            applyHomeCandidateSections(sections, fallbackInventory: fallbackInventory)
        } catch {
            applyHomeCandidateSections(
                HomeCandidateSections(
                    matchedItems: fallbackInventory,
                    possibleItems: Array(fallbackInventory.reversed())
                ),
                fallbackInventory: fallbackInventory
            )
        }
    }

    public func replaceRepository(_ repository: any MegrumRepository) async {
        self.repository = repository
        await loadInitialData()
    }

    private func apply(_ snapshot: MegrumAppSnapshot) {
        let state = MegrumAppInitialSnapshotState(
            snapshot: snapshot,
            previousViewedGroomIDs: viewedGroomIDs
        )
        viewer = state.viewer
        inventory = state.inventory
        wishes = state.wishes
        listings = state.listings
        proposals = state.proposals
        grooms = state.grooms
        groomMapPosts = state.groomMapPosts
        viewedGroomIDs = state.viewedGroomIDs
        likedGroomIDs = state.likedGroomIDs
        threads = state.threads
        subscriptionState = state.subscriptionState
    }

    private func applyHomeCandidateSections(_ sections: HomeCandidateSections, fallbackInventory: [GoodsItem]) {
        let resolved = BlockedUserContentFilter.homeSections(
            sections.resolvedWithFallbackInventory(fallbackInventory),
            blockedUserIDs: blockedContentUserIDs
        )
        homeMatchedItems = resolved.matchedItems
        homePossibleItems = resolved.possibleItems
        homeCandidateConditionSignals = resolved.conditionSignalsByItemID
        homeMutualMatchCandidates = resolved.mutualMatchCandidates
    }

}
