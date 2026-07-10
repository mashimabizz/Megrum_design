import Combine
import Foundation
import MegrumCore

@MainActor
public final class MegrumAppState: ObservableObject {
    @Published public internal(set) var viewer: UserProfile?
    /// 初回ガイドツアー実行中フラグ。広告・共有プロンプト・位置情報・通知遷移などの
    /// 割り込みを抑制するために深い階層からも参照する（`setTutorialActive` で更新）。
    @Published public internal(set) var isTutorialActive = false
    /// ガイドツアー（めぐり章）で作成コールアウトを出す実演リクエスト（nil で不要）。
    @Published public internal(set) var tutorialMeguriCalloutRequestID: UUID?
    @Published public internal(set) var inventory: [GoodsItem] = []
    @Published public internal(set) var wishes: [WishItem] = []
    @Published public internal(set) var homeMatchedItems: [GoodsItem] = []
    @Published public internal(set) var homeRecentPartnerItems: [GoodsItem] = []
    /// ホーム候補の初回読み込みが完了したか（成功/失敗問わず）。
    /// 確定前に空状態CTAを出すとちらつくため、これが true になるまでスケルトンを表示する。
    @Published public internal(set) var hasLoadedHomeCandidates = false
    @Published public internal(set) var homePossibleItems: [GoodsItem] = []
    @Published public internal(set) var homeCandidateConditionSignals: [UUID: HomeCandidateConditionSignals] = [:]
    @Published public internal(set) var homeMutualMatchCandidates: [HomeMutualMatchCandidateData] = []
    @Published public internal(set) var listings: [IndividualListing] = []
    @Published public internal(set) var proposals: [TradeProposal] = []
    @Published public internal(set) var messagesByProposalID: [UUID: [TradeMessage]] = [:]
    /// 自分が評価済みの proposal ID（サーバー基準）。チャット未読込でも
    /// 「評価待ち」タグ・バッジをサーバーの評価状態で判定するために持つ。
    @Published public internal(set) var viewerEvaluatedProposalIDs: Set<UUID> = []
    @Published public internal(set) var evidencePhotosByProposalID: [UUID: [TradeEvidencePhoto]] = [:]
    @Published public internal(set) var viewerReadAtByProposalID: [UUID: Date] = [:]
    @Published public internal(set) var partnerReadAtByProposalID: [UUID: Date] = [:]
    @Published public internal(set) var schedulesByProposalID: [UUID: [PersonalSchedule]] = [:]
    @Published public internal(set) var personalSchedules: [PersonalSchedule] = []
    @Published public internal(set) var profileSchedulesByUserID: [UUID: [PersonalSchedule]] = [:]
    @Published public internal(set) var boardRepliesByThreadID: [UUID: [BoardReply]] = [:]
    /// 地図の吹き出し用：スレッドごとの最新リプライ本文（最大3件・引用行は除去済み）。
    @Published public internal(set) var boardReplyPreviewsByThreadID: [UUID: [String]] = [:]
    /// ホーム/一覧用の圏内チャットルーム（圏外も含めて取得し、開閉はクライアントで判定）。iter1226.421。
    @Published public internal(set) var homeNearbyBoardThreads: [BoardThread] = []
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
    /// 他人プロフィールのほしいもの（userIDごと）。
    @Published public internal(set) var publicWishesByUserID: [UUID: [WishItem]] = [:]
    /// 相手（打診対象）の現地交換カレンダー用：日付キー→会場名。相手のAWから生成。
    @Published public internal(set) var partnerActivityWindowVenuesByUserID: [UUID: [String: String]] = [:]
    @Published public internal(set) var publicExchangeSettingsByUserID: [UUID: HomeDefaultExchangeSettings] = [:]
    @Published public internal(set) var userEvaluationsByUserID: [UUID: [UserEvaluation]] = [:]
    @Published public internal(set) var groomLikeCountByUserID: [UUID: Int] = [:]
    @Published public internal(set) var mailingAddress: MailingAddress?
    @Published public internal(set) var paymentSettings: UserPaymentSettings?
    @Published public internal(set) var hasLoadedPaymentSettings = false
    @Published public internal(set) var exchangeSettings: HomeDefaultExchangeSettings?
    @Published public internal(set) var subscriptionState: UserSubscriptionState = .free
    @Published public internal(set) var blockedUsers: [BlockedUser] = []
    @Published public internal(set) var blockedContentUserIDs: Set<UUID> = []
    @Published public internal(set) var notifications: [MegrumNotification] = []
    /// 通知の右端サムネの表示URL（非公開バケットは署名URLへ解決済み）。iter1226.415。
    @Published public internal(set) var notificationThumbnailURLByID: [UUID: URL] = [:]
    @Published public internal(set) var pushNotificationsEnabled = true
    @Published public internal(set) var groomActivityPushNotificationsEnabled = true
    @Published public internal(set) var chatroomActivityPushNotificationsEnabled = true
    @Published public internal(set) var groomOshiPushNotificationsEnabled = false
    @Published public internal(set) var groomNearbyPushNotificationsEnabled = false
    @Published public internal(set) var chatroomOshiPushNotificationsEnabled = false
    @Published public internal(set) var chatroomNearbyPushNotificationsEnabled = false
    /// FB8-7: 推し(L1)ごとの圏内グルーム通知設定。groupID -> 設定。未収載は既定（ON・全メンバー）。iter1226.388。
    @Published public internal(set) var groomNotifyPrefsByGroupID: [UUID: GroomNotifyPref] = [:]
    /// 通知設定を一度でも読み込んだか（近接検知で毎回読まないためのガード）。iter1226.390。
    @Published public internal(set) var hasLoadedGroomNotifyPrefs = false
    /// FB(iter1226.390): 近接検知でこのセッション中に既に通知/遭遇処理したグルームID（連続発火の抑制）。
    @Published public internal(set) var processedProximityGroomIDs: Set<UUID> = []
    /// FB(iter1226.392): 出会った(遭遇済み)グルーム。ホーム列で近くに無くても表示する（無料はロック）。
    @Published public internal(set) var encounteredGrooms: [GroomPost] = []
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
    /// めぐり地図のビューポート追加読み込み中（地図中央下の「読み込み中…」表示用）。
    @Published public internal(set) var isLoadingMeguriViewport = false
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
    /// iter1226.422：ホーム経由のバックグラウンド投稿開始をホーム画面（活性化アニメ予約）へ伝えるシグナル。
    @Published public internal(set) var homeGroomActivationExpectationSignal = 0
    /// iter1226.422：ユーザーID重複時の代替候補（アカウントセットアップの保存前チェックで供給）。
    @Published public internal(set) var accountSetupHandleSuggestions: [String] = []
    @Published public internal(set) var isCreatingBoardThread = false
    @Published public internal(set) var deletingGroomPostID: UUID?
    @Published public internal(set) var reportingGroomPostID: UUID?
    @Published public internal(set) var reportingBoardThreadID: UUID?
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
    var meguriFeedCacheKey: MeguriFeedCacheKey?
    var groomMapCacheKey: MeguriFeedCacheKey?
    var isMeguriFeedRequestInFlight = false
    var isGroomMapRequestInFlight = false
    var ownedGoodsImagePreloadTask: Task<Void, Never>?
    private static weak var activeInstanceStorage: MegrumAppState?

    static var activeInstance: MegrumAppState? {
        activeInstanceStorage
    }

    public init(repository: any MegrumRepository = PreviewMegrumRepository()) {
        self.repository = repository
        Self.activeInstanceStorage = self
    }

    deinit {
        ownedGoodsImagePreloadTask?.cancel()
    }

    public var unreadNotificationCount: Int {
        NotificationReadStateReducer.unreadCount(in: notifications)
    }

    /// アプリアイコンのバッジ＝タブバーのバッジ合計（やりとり＋めぐり）。
    /// タブバーで見えている数を正とし、それ以外は足さない。
    public var appIconBadgeCount: Int {
        let tradeAttention = TradeStageAttentionCounts(
            proposals: proposals,
            messagesByProposalID: messagesByProposalID,
            viewerReadAtByProposalID: viewerReadAtByProposalID,
            viewerID: viewer?.id,
            evaluatedProposalIDs: viewerEvaluatedProposalIDs
        )
        return tradeAttention.total + meguriUnreadMessageCount
    }

    public var meguriUnreadMessageCount: Int {
        guard let viewer else {
            return 0
        }
        return MeguriMessageReadStateReducer.unreadIncomingCount(
            visibleMeguriMessages(for: viewer.id),
            viewerID: viewer.id,
            hiddenThreadEntries: hiddenMeguriThreadEntries
        )
    }

    public var meguriPendingReplyCount: Int {
        guard let viewer else {
            return 0
        }
        return MeguriMessageReadStateReducer.pendingReplyThreadCount(
            visibleMeguriMessages(for: viewer.id),
            viewerID: viewer.id,
            hiddenThreadEntries: hiddenMeguriThreadEntries
        )
    }

    public var meguriMessageThreads: [MeguriMessageThread] {
        guard let viewer else {
            return []
        }
        return MeguriMessageReadStateReducer.conversationThreads(
            from: visibleMeguriMessages(for: viewer.id),
            viewerID: viewer.id,
            publicProfilesByUserID: publicProfilesByUserID,
            meguriProfilesByUserID: meguriProfilesByUserID
        )
        .filter { thread in
            !MeguriHiddenThreadStore.isHidden(
                lastMessageAt: thread.lastMessage.createdAt,
                hiddenAt: hiddenMeguriThreadEntries[thread.id]
            )
        }
    }

    /// めぐりメッセージ一覧でローカル非表示（削除）にしたスレッド。
    @Published public private(set) var hiddenMeguriThreadEntries: [String: Date] = [:]

    public func hideMeguriMessageThread(_ thread: MeguriMessageThread) {
        guard let viewer else {
            return
        }
        hiddenMeguriThreadEntries[thread.id] = Date()
        MeguriHiddenThreadStore.save(hiddenMeguriThreadEntries, viewerID: viewer.id)
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

    /// 初回ガイドツアーの実行状態を更新する。割り込み抑制の可否をこのフラグで判定する。
    /// めぐり章のサンプルピンは MeguriScreen 側が表示レイヤで注入する（実データは触らない）。
    public func setTutorialActive(_ isActive: Bool) {
        guard isTutorialActive != isActive else { return }
        isTutorialActive = isActive
        if !isActive {
            tutorialMeguriCalloutRequestID = nil
        }
    }

    /// ガイドツアー（めぐり章）の実演：地図中心付近に作成コールアウトを出すリクエスト。
    /// MeguriScreen が onChange で拾い、実物のコールアウト表示処理を呼ぶ。
    public func requestTutorialMeguriCallout() {
        tutorialMeguriCalloutRequestID = UUID()
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
        meguriMessages(
            in: MeguriMessageConversationKey(peerID: peerID),
            showsAllPeerMessages: true
        )
    }

    public func meguriMessages(
        in conversationKey: MeguriMessageConversationKey,
        showsAllPeerMessages: Bool = false
    ) -> [MeguriMessage] {
        guard !blockedContentUserIDs.contains(conversationKey.peerID) else {
            return []
        }
        return meguriMessages.filter { message in
            guard message.senderID == conversationKey.peerID || message.recipientID == conversationKey.peerID else {
                return false
            }
            if showsAllPeerMessages && conversationKey.sourceGroomPostID == nil {
                return true
            }
            return message.sourceGroomPostID == conversationKey.sourceGroomPostID
        }
    }

    private func visibleMeguriMessages(for viewerID: UUID) -> [MeguriMessage] {
        MeguriMessageReadStateReducer.visibleMessages(
            meguriMessages,
            viewerID: viewerID,
            blockedUserIDs: blockedContentUserIDs
        )
    }

    public func isGroomLiked(_ postID: UUID) -> Bool {
        likedGroomIDs.contains(postID)
    }

    public func groomLikeCount(_ postID: UUID, fallback: Int = 0) -> Int {
        groomPost(postID)?.likeCount ?? fallback
    }

    public func ownVisibleGroom(postID: UUID? = nil) -> GroomPost? {
        guard let viewerID = viewer?.id else {
            return nil
        }
        let candidates = grooms + groomMapPosts
        if let postID,
           let groom = candidates.first(where: { $0.id == postID && $0.authorID == viewerID }) {
            return groom
        }
        return candidates
            .filter { $0.authorID == viewerID }
            .max { $0.createdAt < $1.createdAt }
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
            // 評価済みIDはスナップショットと並行で取得し、proposals を公開する前に
            // 反映する。後から反映するとやりとりバッジが「開いた直後だけ多い→減る」
            // 見え方になるため（iter1226.341）。
            async let evaluatedProposalIDsTask = repository.loadViewerEvaluatedProposalIDs()
            let snapshot = try await repository.loadInitialSnapshot()
            if let evaluatedIDs = try? await evaluatedProposalIDsTask {
                viewerEvaluatedProposalIDs.formUnion(evaluatedIDs)
            }
            apply(snapshot)
            persistViewerEvaluatedProposalIDsIfPossible()
            preloadOwnedGoodsImages(inventory: snapshot.inventory, wishes: snapshot.wishes)
            await loadBlockedContentUserIDs(reportsFailure: false)
            await loadHomeCandidates(fallbackInventory: snapshot.inventory)
            await loadSubscriptionState(reportsFailure: false)
            await loadMeguriProfile(reportsFailure: false)
            await loadMeguriMessages(reportsFailure: false)
            await preloadTradeMessages()
            await preloadTradeEvidencePhotos()
        } catch {
            #if DEBUG
            print("MEGRUM_DEBUG_SNAPSHOT error: \(error)")
            #endif
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
            async let evaluatedProposalIDsTask = repository.loadViewerEvaluatedProposalIDs()
            let snapshot = try await repository.loadInitialSnapshot()
            if let evaluatedIDs = try? await evaluatedProposalIDsTask {
                viewerEvaluatedProposalIDs.formUnion(evaluatedIDs)
            }
            apply(snapshot)
            persistViewerEvaluatedProposalIDsIfPossible()
            preloadOwnedGoodsImages(inventory: snapshot.inventory, wishes: snapshot.wishes)
            await loadBlockedContentUserIDs(reportsFailure: false)
            await loadHomeCandidates(fallbackInventory: snapshot.inventory)
            await loadSubscriptionState(reportsFailure: false)
            await loadMeguriProfile(reportsFailure: false)
            await loadMeguriMessages(reportsFailure: false)
            await preloadTradeMessages()
            await preloadTradeEvidencePhotos()
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
        defer { hasLoadedHomeCandidates = true }
        do {
            let sections = try await repository.loadHomeCandidateSections()
            applyHomeCandidateSections(sections, fallbackInventory: fallbackInventory)
        } catch {
            #if DEBUG
            print("MEGRUM_DEBUG_HOME_CANDIDATES error: \(error)")
            #endif
            // 以前は取得失敗時に自分の在庫を候補のように表示していたが、
            // 「更新すると候補が消える」ように見える混乱の元だったため、
            // 失敗時は表示を変えない（実データのみ表示する）。
        }
    }

    public func replaceRepository(
        _ repository: any MegrumRepository,
        reloadsInitialData: Bool = true
    ) async {
        self.repository = repository
        guard reloadsInitialData else {
            return
        }
        await loadInitialData()
    }

    private func apply(_ snapshot: MegrumAppSnapshot) {
        let state = MegrumAppInitialSnapshotState(
            snapshot: snapshot,
            previousViewedGroomIDs: viewedGroomIDs
        )
        viewer = state.viewer
        hiddenMeguriThreadEntries = MeguriHiddenThreadStore.load(viewerID: state.viewer.id)
        // 評価済みIDはローカル保存分を proposals より先に反映して、
        // 起動直後の「評価待ち」過計上（バッジが後から減る現象）を防ぐ。
        viewerEvaluatedProposalIDs.formUnion(
            ViewerEvaluatedProposalStore.load(viewerID: state.viewer.id)
        )
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
        hasLoadedHomeCandidates = true
        let resolved = BlockedUserContentFilter.homeSections(
            sections.resolvedWithFallbackInventory(fallbackInventory),
            blockedUserIDs: blockedContentUserIDs
        )
        homeMatchedItems = resolved.matchedItems
        homePossibleItems = resolved.possibleItems
        homeCandidateConditionSignals = resolved.conditionSignalsByItemID
        homeMutualMatchCandidates = resolved.mutualMatchCandidates
        homeRecentPartnerItems = sections.recentPartnerItems.filter { item in
            !blockedContentUserIDs.contains(item.ownerID)
        }
    }

    private func preloadOwnedGoodsImages(inventory: [GoodsItem], wishes: [WishItem]) {
        guard !(repository is PreviewMegrumRepository) else {
            ownedGoodsImagePreloadTask?.cancel()
            ownedGoodsImagePreloadTask = nil
            return
        }

        let urls = OwnedGoodsImagePreloadPolicy.urls(inventory: inventory, wishes: wishes)
        guard !urls.isEmpty else {
            ownedGoodsImagePreloadTask?.cancel()
            ownedGoodsImagePreloadTask = nil
            return
        }

        ownedGoodsImagePreloadTask?.cancel()
        ownedGoodsImagePreloadTask = Task(priority: .utility) {
            await GoodsRemoteImageDataLoader.preload(urls: urls)
        }
    }

}
