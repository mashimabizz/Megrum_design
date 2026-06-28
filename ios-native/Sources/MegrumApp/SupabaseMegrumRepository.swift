import Foundation
import MegrumCore
import MegrumData

public struct SupabaseMegrumRepository: MegrumRepository {
    let client: SupabaseRESTClient
    let oshiClient: SupabaseOshiClient
    let accountProfilePersistence: SupabaseAccountProfilePersistence
    let ownedGoodsPersistence: SupabaseOwnedGoodsPersistence
    let initialSnapshotLoader: SupabaseInitialSnapshotLoader
    let goodsInventoryClient: SupabaseGoodsInventoryClient
    let goodsEntryPersistence: SupabaseGoodsEntryPersistence
    let goodsReportClient: SupabaseGoodsReportClient
    let userReportClient: SupabaseUserReportClient
    let listingClient: SupabaseListingClient
    let mailingAddressClient: SupabaseMailingAddressClient
    let postalCodeAddressClient: PostalCodeAddressClient
    let blockClient: SupabaseBlockClient
    let notificationClient: SupabaseNotificationClient
    let proposalClient: SupabaseProposalClient
    let disputeClient: SupabaseDisputeClient
    let messageClient: SupabaseMessageClient
    let tradeSchedulePersistence: SupabaseTradeSchedulePersistence
    let homeLocalModePersistence: SupabaseHomeLocalModePersistence
    let groomClient: SupabaseGroomClient
    let meguriProfileClient: SupabaseMeguriProfileClient
    let meguriMessageClient: SupabaseMeguriMessageClient
    let boardClient: SupabaseBoardClient
    let publicProfilePersistence: SupabasePublicProfilePersistence
    let homeClient: SupabaseHomeClient
    let paymentSettingsPersistence: SupabasePaymentSettingsPersistence
    let exchangeSettingsClient: SupabaseExchangeSettingsClient
    let faceRecognitionClient: SupabaseFaceRecognitionClient
    let goodsSeriesSuggestionClient: SupabaseGoodsSeriesSuggestionClient
    let chatPhotoStorage: SupabaseChatPhotoStorage
    let entitlementClient: SupabaseEntitlementClient
    let viewerID: UUID

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
        self.userReportClient = SupabaseUserReportClient(client: client)
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
        self.meguriProfileClient = SupabaseMeguriProfileClient(client: client)
        self.meguriMessageClient = SupabaseMeguriMessageClient(client: client)
        let boardClient = SupabaseBoardClient(client: client)
        self.boardClient = boardClient
        self.publicProfilePersistence = SupabasePublicProfilePersistence(
            userProfileClient: SupabaseUserProfileClient(client: client),
            oshiClient: oshiClient
        )
        self.homeClient = SupabaseHomeClient(client: client)
        self.paymentSettingsPersistence = SupabasePaymentSettingsPersistence(client: client)
        self.exchangeSettingsClient = SupabaseExchangeSettingsClient(client: client)
        self.faceRecognitionClient = SupabaseFaceRecognitionClient(client: client)
        self.goodsSeriesSuggestionClient = SupabaseGoodsSeriesSuggestionClient(client: client)
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

    public func syncMegrumPlusPurchase(_ input: MegrumPlusPurchaseSyncInput) async throws -> UserSubscriptionState {
        try await entitlementClient.syncMegrumPlusPurchase(input)
    }

    public func loadHomeCandidateSections() async throws -> HomeCandidateSections {
        async let composition = homeClient.loadHomeComposition(userID: viewerID)
        async let oshiSelections = oshiClient.loadUserSelections(userID: viewerID)
        return HomeCandidateComposer.sections(
            from: try await composition,
            viewerOshiSelections: (try? await oshiSelections) ?? []
        )
    }
}
