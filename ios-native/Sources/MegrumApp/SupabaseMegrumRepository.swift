import Foundation
import MegrumCore
import MegrumData

private enum ProfilePhotoUploadError: Error, Equatable, Sendable {
    case imageTooLarge
    case unsupportedImageContentType
}

public struct SupabaseMegrumRepository: MegrumRepository {
    private static let chatPhotoBucket = "chat-photos"
    private static let maxChatPhotoUploadBytes = Int(9.5 * 1_024 * 1_024)
    private static let profilePhotoBucket = "profile-photos"
    private static let maxProfilePhotoUploadBytes = 10 * 1_024 * 1_024
    private let client: SupabaseRESTClient
    private let oshiClient: SupabaseOshiClient
    private let goodsInventoryClient: SupabaseGoodsInventoryClient
    private let goodsReportClient: SupabaseGoodsReportClient
    private let listingClient: SupabaseListingClient
    private let mailingAddressClient: SupabaseMailingAddressClient
    private let postalCodeAddressClient: PostalCodeAddressClient
    private let blockClient: SupabaseBlockClient
    private let notificationClient: SupabaseNotificationClient
    private let proposalClient: SupabaseProposalClient
    private let disputeClient: SupabaseDisputeClient
    private let messageClient: SupabaseMessageClient
    private let scheduleClient: SupabaseScheduleClient
    private let activityWindowClient: SupabaseActivityWindowClient
    private let groomClient: SupabaseGroomClient
    private let meguriMessageClient: SupabaseMeguriMessageClient
    private let boardClient: SupabaseBoardClient
    private let userProfileClient: SupabaseUserProfileClient
    private let homeClient: SupabaseHomeClient
    private let viewerID: UUID

    public init(client: SupabaseRESTClient, viewerID: UUID) {
        self.client = client
        self.oshiClient = SupabaseOshiClient(client: client)
        self.goodsInventoryClient = SupabaseGoodsInventoryClient(client: client)
        self.goodsReportClient = SupabaseGoodsReportClient(client: client)
        self.listingClient = SupabaseListingClient(client: client)
        self.mailingAddressClient = SupabaseMailingAddressClient(client: client)
        self.postalCodeAddressClient = PostalCodeAddressClient()
        self.blockClient = SupabaseBlockClient(client: client)
        self.notificationClient = SupabaseNotificationClient(client: client)
        self.proposalClient = SupabaseProposalClient(client: client)
        self.disputeClient = SupabaseDisputeClient(client: client)
        self.messageClient = SupabaseMessageClient(client: client)
        self.scheduleClient = SupabaseScheduleClient(client: client)
        self.activityWindowClient = SupabaseActivityWindowClient(client: client)
        self.groomClient = SupabaseGroomClient(client: client)
        self.meguriMessageClient = SupabaseMeguriMessageClient(client: client)
        self.boardClient = SupabaseBoardClient(client: client)
        self.userProfileClient = SupabaseUserProfileClient(client: client)
        self.homeClient = SupabaseHomeClient(client: client)
        self.viewerID = viewerID
    }

    public func loadInitialSnapshot() async throws -> MegrumAppSnapshot {
        let viewer = try await loadViewer()
        async let inventory = bestEffortInitialSection([]) {
            try await loadGoods(kind: "for_trade")
        }
        async let wishes = bestEffortInitialSection([]) {
            try await loadWishes()
        }
        async let listings = bestEffortInitialSection([]) {
            try await loadIndividualListings()
        }
        async let proposals = bestEffortInitialSection([]) {
            try await loadProposals()
        }
        async let grooms = bestEffortInitialSection([]) {
            try await loadGrooms(latitude: nil, longitude: nil, radiusMeters: 1_000)
        }
        async let threads = bestEffortInitialSection([]) {
            try await loadBoardThreads(
                latitude: nil,
                longitude: nil,
                prefecture: viewer.prefecture,
                scope: viewer.prefecture == nil ? .nearby3km : .samePrefecture
            )
        }

        return MegrumAppSnapshot(
            viewer: viewer,
            inventory: await inventory,
            wishes: await wishes,
            listings: await listings,
            proposals: await proposals,
            grooms: await grooms,
            threads: await threads
        )
    }

    private func bestEffortInitialSection<Value>(
        _ fallback: Value,
        operation: () async throws -> Value
    ) async -> Value {
        do {
            return try await operation()
        } catch {
            #if DEBUG
            print("Megrum initial section failed: \(error)")
            #endif
            return fallback
        }
    }

    private func loadViewer() async throws -> UserProfile {
        let rows: [UserRow] = try await client.fetchRows(
            from: "users",
            select: "id,handle,display_name,avatar_url,gender,primary_area,account_status",
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

    public func loadUserOshiSelections() async throws -> [UserOshiSelection] {
        try await oshiClient.loadUserSelections(userID: viewerID)
    }

    public func saveUserOshiSelections(_ selections: [AccountSetupOshiInput]) async throws -> [UserOshiSelection] {
        let rows = selections.map { selection in
            UserOshiSelection(
                id: UUID(),
                userID: viewerID,
                groupID: selection.groupID,
                characterID: selection.characterID,
                kind: selection.kind,
                priority: selection.priority,
                oshiRequestID: selection.oshiRequestID,
                characterRequestID: selection.characterRequestID
            )
        }
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
        let uploadedPhotoURL = try await uploadGoodsPhotoIfNeeded(
            input.photoUpload,
            client: goodsInventoryClient,
            viewerID: viewerID
        )
        return try await goodsInventoryClient.createGoodsEntry(
            userID: viewerID,
            input: input,
            photoURLs: uploadedPhotoURL.map { [$0] } ?? []
        )
    }

    public func updateGoodsEntry(itemID: UUID, kind: GoodsEntryKind, input: GoodsEntryUpdateInput) async throws -> GoodsItem {
        let status = GoodsInventoryStatus(rawValue: input.status.rawValue) ?? .active
        let uploadedPhotoURL = try await uploadGoodsPhotoIfNeeded(
            input.photoUpload,
            client: goodsInventoryClient,
            viewerID: viewerID
        )
        let photoURLs = uploadedPhotoURL.map { [$0] } ?? input.photoURLs
        let updated = try await goodsInventoryClient.updateGoodsItem(
            userID: viewerID,
            itemID: itemID,
            input: GoodsInventoryUpdateInput(
                title: input.title,
                groupID: input.groupID,
                characterID: input.memberID,
                clearsCharacterID: input.clearsMemberID,
                goodsTypeID: input.goodsTypeID,
                quantity: input.quantity,
                status: status,
                photoURLs: photoURLs,
                tagNames: input.tagNames
            )
        )
        if let updated {
            return updated
        }
        throw MegrumRepositoryError.unsupportedMutation
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

    public func loadPublicTradeGoods(userID: UUID, limit: Int) async throws -> [GoodsItem] {
        try await goodsInventoryClient.loadPublicTradeGoods(userID: userID, limit: limit)
    }

    public func loadPublicIndividualListings(userID: UUID) async throws -> [IndividualListing] {
        try await listingClient.loadPublicListings(userID: userID)
    }

    public func loadPublicUserProfile(userID: UUID) async throws -> PublicUserProfile? {
        try await userProfileClient.loadProfile(userID: userID)
    }

    public func loadUserEvaluations(userID: UUID, limit: Int) async throws -> [UserEvaluation] {
        try await userProfileClient.loadEvaluations(userID: userID, limit: limit)
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

    public func sendMessage(_ input: TradeMessageCreateInput) async throws -> TradeMessage {
        try await messageClient.sendTextMessage(senderID: viewerID, input: input)
    }

    public func sendPhotoMessage(_ input: TradePhotoMessageCreateInput) async throws -> TradeMessage {
        guard [.photo, .outfitPhoto].contains(input.messageType) else {
            throw SupabaseMessageClientError.invalidPhotoMessageType
        }
        guard input.imageData.count <= Self.maxChatPhotoUploadBytes else {
            throw SupabaseProposalClientError.imageTooLarge
        }

        let contentType = normalizedChatImageContentType(input.imageContentType)
        let path = chatPhotoPath(
            proposalID: input.proposalID,
            messageType: input.messageType,
            contentType: contentType
        )
        try await client.uploadObject(
            bucket: Self.chatPhotoBucket,
            path: path,
            data: input.imageData,
            contentType: contentType,
            upsert: false
        )
        let signedURL = try await client.createSignedURL(
            bucket: Self.chatPhotoBucket,
            path: path,
            expiresIn: 60 * 60 * 24 * 365
        )
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
        guard proposal.isParticipant(viewerID) else {
            return []
        }
        var userIDs = [viewerID]
        if let partnerID = proposal.partnerID(for: viewerID) {
            userIDs.append(partnerID)
        }
        return try await scheduleClient.loadSchedules(
            userIDs: userIDs,
            startAt: startAt,
            endAt: endAt
        )
    }

    public func createSchedule(_ input: PersonalScheduleCreateInput) async throws -> PersonalSchedule {
        try await scheduleClient.createSchedule(userID: viewerID, input: input)
    }

    public func loadHomeLocalModeSettings(now: Date) async throws -> HomeLocalActivitySettings? {
        async let storedSettings = activityWindowClient.loadLocalModeSettings(userID: viewerID)
        async let activityWindows = activityWindowClient.loadActivityWindows(userID: viewerID, limit: 50)

        let settings = try await storedSettings
        let windows = try await activityWindows
        let selectedWindow = homeLocalModeWindow(from: windows, settings: settings, now: now)

        if settings == nil, selectedWindow == nil {
            return nil
        }
        return homeLocalModeSettings(from: settings, activityWindow: selectedWindow)
    }

    public func saveHomeLocalModeSettings(
        _ settings: HomeLocalActivitySettings,
        now: Date
    ) async throws -> HomeLocalActivitySettings {
        let prepared = settings.normalizedForPersistence(now: now)
        if prepared.isEnabled {
            return try await saveEnabledHomeLocalModeSettings(prepared, now: now)
        }
        return try await saveDisabledHomeLocalModeSettings(prepared, now: now)
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
        let uploadedAvatarURL = try await uploadProfilePhotoIfNeeded(input.avatarUpload)
        let avatarURL = uploadedAvatarURL ?? (input.clearsAvatar ? nil : input.avatarURL)
        let shouldEncodeAvatarURL = input.avatarUpload != nil || input.clearsAvatar || input.avatarURL != nil

        let rows: [UserRow] = try await client.updateRows(
            in: "users",
            values: UserOwnProfileUpdatePayload(
                handle: input.handle,
                displayName: input.displayName,
                avatarUrl: avatarURL,
                shouldEncodeAvatarUrl: shouldEncodeAvatarURL,
                gender: input.gender,
                primaryArea: input.prefecture
            ),
            select: "id,handle,display_name,avatar_url,gender,primary_area,account_status",
            queryItems: [
                URLQueryItem(name: "id", value: "eq.\(viewerID.uuidString.lowercased())"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        return rows.first?.profile ?? UserProfile(
            id: viewerID,
            handle: input.handle,
            displayName: input.displayName,
            avatarURL: avatarURL,
            gender: input.gender,
            prefecture: input.prefecture,
            accountStatus: .active
        )
    }

    private func uploadProfilePhotoIfNeeded(_ upload: GoodsPhotoUpload?) async throws -> URL? {
        guard let upload else {
            return nil
        }
        guard upload.data.count <= Self.maxProfilePhotoUploadBytes else {
            throw ProfilePhotoUploadError.imageTooLarge
        }

        let contentType = try Self.normalizedProfilePhotoContentType(upload.contentType)
        let path = Self.profilePhotoPath(userID: viewerID, contentType: contentType)
        try await client.uploadObject(
            bucket: Self.profilePhotoBucket,
            path: path,
            data: upload.data,
            contentType: contentType,
            upsert: false
        )
        return try client.publicStorageObjectURL(bucket: Self.profilePhotoBucket, path: path)
    }

    private static func normalizedProfilePhotoContentType(_ value: String) throws -> String {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "image/jpeg", "image/jpg":
            "image/jpeg"
        case "image/png":
            "image/png"
        case "image/webp":
            "image/webp"
        case "image/gif":
            "image/gif"
        default:
            throw ProfilePhotoUploadError.unsupportedImageContentType
        }
    }

    private static func profilePhotoPath(userID: UUID, contentType: String) -> String {
        let milliseconds = Int(Date().timeIntervalSince1970 * 1_000)
        return [
            userID.uuidString.lowercased(),
            "\(milliseconds)_\(UUID().uuidString.lowercased()).\(profilePhotoFileExtension(for: contentType))"
        ].joined(separator: "/")
    }

    private static func profilePhotoFileExtension(for contentType: String) -> String {
        switch contentType {
        case "image/png":
            "png"
        case "image/webp":
            "webp"
        case "image/gif":
            "gif"
        default:
            "jpg"
        }
    }

    public func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        let selections = input.oshiSelections.map { selection in
            UserOshiSelection(
                id: UUID(),
                userID: viewerID,
                groupID: selection.groupID,
                characterID: selection.characterID,
                kind: selection.kind,
                priority: selection.priority,
                oshiRequestID: selection.oshiRequestID,
                characterRequestID: selection.characterRequestID
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
            select: "id,handle,display_name,avatar_url,gender,primary_area,account_status",
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
            select: "id,user_id,kind,status,group_id,character_id,goods_type_id,title,photo_urls,quantity",
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(viewerID.uuidString.lowercased())"),
                URLQueryItem(name: "kind", value: "eq.\(kind)"),
                URLQueryItem(name: "status", value: "neq.archived")
            ]
        )
        return rows.compactMap(\.goodsItem)
    }

    private func loadWishes() async throws -> [WishItem] {
        let rows: [GoodsInventoryRow] = try await client.fetchRows(
            from: "goods_inventory",
            select: "id,user_id,kind,status,group_id,character_id,goods_type_id,title,photo_urls,quantity",
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

    private func saveEnabledHomeLocalModeSettings(
        _ settings: HomeLocalActivitySettings,
        now: Date
    ) async throws -> HomeLocalActivitySettings {
        let startAt = settings.startedAt ?? now
        let endAt = settings.endDate(now: now)
        let existingActivityWindowID: UUID?
        if let activityWindowID = settings.activityWindowID {
            existingActivityWindowID = activityWindowID
        } else {
            existingActivityWindowID = try await loadHomeLocalModeSettings(now: now)?.activityWindowID
        }
        let activityWindow: SupabaseActivityWindow

        if let existingActivityWindowID,
           let updated = try await activityWindowClient.updateActivityWindow(
            userID: viewerID,
            activityWindowID: existingActivityWindowID,
            input: SupabaseActivityWindowUpdateInput(
                venue: settings.normalizedVenue,
                center: supabaseCoordinate(from: settings.coordinate),
                clearsCenter: settings.coordinate == nil,
                radiusMeters: settings.normalizedRadiusMeters,
                clearsEventName: true,
                eventless: true,
                startAt: startAt,
                endAt: endAt,
                clearsNote: true,
                status: .enabled
            )
           ) {
            activityWindow = updated
        } else {
            activityWindow = try await activityWindowClient.createActivityWindow(
                userID: viewerID,
                input: SupabaseActivityWindowCreateInput(
                    venue: settings.normalizedVenue,
                    center: supabaseCoordinate(from: settings.coordinate),
                    radiusMeters: settings.normalizedRadiusMeters,
                    eventless: true,
                    startAt: startAt,
                    endAt: endAt,
                    status: .enabled
                )
            )
        }

        _ = try await activityWindowClient.disableOtherEnabledActivityWindows(
            userID: viewerID,
            keeping: activityWindow.id
        )
        _ = try await activityWindowClient.upsertLocalModeSettings(
            userID: viewerID,
            input: SupabaseLocalModeSettingsUpsertInput(
                enabled: true,
                activityWindowID: activityWindow.id,
                radiusMeters: settings.normalizedRadiusMeters,
                selectedCarryingIDs: sortedUUIDs(settings.selectedCarryingIDs),
                selectedWishIDs: [],
                lastLocation: supabaseCoordinate(from: settings.coordinate),
                clearsLastLocation: settings.coordinate == nil
            )
        )

        return homeLocalModeSettings(
            enabled: true,
            activityWindowID: activityWindow.id,
            radiusMeters: settings.normalizedRadiusMeters,
            selectedCarryingIDs: sortedUUIDs(settings.selectedCarryingIDs),
            coordinate: activityWindow.center ?? supabaseCoordinate(from: settings.coordinate),
            activityWindow: activityWindow
        )
    }

    private func saveDisabledHomeLocalModeSettings(
        _ settings: HomeLocalActivitySettings,
        now: Date
    ) async throws -> HomeLocalActivitySettings {
        let existingActivityWindowID: UUID?
        if let activityWindowID = settings.activityWindowID {
            existingActivityWindowID = activityWindowID
        } else {
            existingActivityWindowID = try await loadHomeLocalModeSettings(now: now)?.activityWindowID
        }
        var disabledWindow: SupabaseActivityWindow?

        if let existingActivityWindowID {
            disabledWindow = try await activityWindowClient.updateActivityWindow(
                userID: viewerID,
                activityWindowID: existingActivityWindowID,
                input: SupabaseActivityWindowUpdateInput(status: .disabled)
            )
        }

        _ = try await activityWindowClient.upsertLocalModeSettings(
            userID: viewerID,
            input: SupabaseLocalModeSettingsUpsertInput(
                enabled: false,
                activityWindowID: existingActivityWindowID,
                radiusMeters: settings.normalizedRadiusMeters,
                selectedCarryingIDs: sortedUUIDs(settings.selectedCarryingIDs),
                selectedWishIDs: [],
                lastLocation: supabaseCoordinate(from: settings.coordinate),
                clearsLastLocation: settings.coordinate == nil
            )
        )

        if let disabledWindow {
            return homeLocalModeSettings(
                enabled: false,
                activityWindowID: existingActivityWindowID,
                radiusMeters: settings.normalizedRadiusMeters,
                selectedCarryingIDs: sortedUUIDs(settings.selectedCarryingIDs),
                coordinate: disabledWindow.center ?? supabaseCoordinate(from: settings.coordinate),
                activityWindow: disabledWindow
            )
        }

        return HomeLocalActivitySettings(
            activityWindowID: existingActivityWindowID,
            isEnabled: false,
            venue: settings.normalizedVenue,
            coordinate: settings.coordinate,
            startedAt: settings.startedAt,
            durationMinutes: settings.normalizedDurationMinutes,
            radiusMeters: settings.normalizedRadiusMeters,
            selectedCarryingIDs: settings.selectedCarryingIDs
        )
    }

    private func homeLocalModeWindow(
        from windows: [SupabaseActivityWindow],
        settings: SupabaseLocalModeSettings?,
        now: Date
    ) -> SupabaseActivityWindow? {
        if let activityWindowID = settings?.activityWindowID,
           let window = windows.first(where: { $0.id == activityWindowID }) {
            return window
        }
        return windows
            .filter { $0.status == .enabled && $0.endAt >= now }
            .sorted { $0.startAt < $1.startAt }
            .first
    }

    private func homeLocalModeSettings(
        from settings: SupabaseLocalModeSettings?,
        activityWindow: SupabaseActivityWindow?
    ) -> HomeLocalActivitySettings {
        homeLocalModeSettings(
            enabled: settings?.enabled,
            activityWindowID: settings?.activityWindowID,
            radiusMeters: settings?.radiusMeters,
            selectedCarryingIDs: settings?.selectedCarryingIDs ?? [],
            coordinate: settings?.lastLocation ?? activityWindow?.center,
            activityWindow: activityWindow
        )
    }

    private func homeLocalModeSettings(
        enabled: Bool?,
        activityWindowID: UUID?,
        radiusMeters: Int?,
        selectedCarryingIDs: [UUID],
        coordinate: SupabaseActivityWindowCoordinate? = nil,
        activityWindow: SupabaseActivityWindow?
    ) -> HomeLocalActivitySettings {
        let durationMinutes = activityWindow.map { window in
            max(30, Int(window.endAt.timeIntervalSince(window.startAt) / 60))
        } ?? HomeLocalActivitySettings.defaultDurationMinutes
        let activityWindowIsEnabled = activityWindow?.status == .enabled

        return HomeLocalActivitySettings(
            activityWindowID: activityWindowID ?? activityWindow?.id,
            isEnabled: (enabled ?? activityWindowIsEnabled) && activityWindowIsEnabled,
            venue: activityWindow?.venue ?? "",
            coordinate: megrumCoordinate(from: coordinate ?? activityWindow?.center),
            startedAt: activityWindow?.startAt,
            durationMinutes: HomeLocalActivitySettings.normalizedDurationMinutes(durationMinutes),
            radiusMeters: HomeLocalActivitySettings.normalizedRadiusMeters(
                radiusMeters ?? activityWindow?.radiusMeters ?? HomeLocalActivitySettings.defaultRadiusMeters
            ),
            selectedCarryingIDs: Set(selectedCarryingIDs)
        )
    }

    private func supabaseCoordinate(from coordinate: MegrumLocationCoordinate?) -> SupabaseActivityWindowCoordinate? {
        guard let coordinate else {
            return nil
        }
        return SupabaseActivityWindowCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    private func megrumCoordinate(from coordinate: SupabaseActivityWindowCoordinate?) -> MegrumLocationCoordinate? {
        guard let coordinate else {
            return nil
        }
        return MegrumLocationCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

private struct UserRow: Decodable, Sendable {
    var id: UUID
    var handle: String?
    var displayName: String?
    var avatarUrl: URL?
    var gender: UserGender?
    var primaryArea: String?
    var accountStatus: String?

    var profile: UserProfile {
        UserProfile(
            id: id,
            handle: handle ?? "unknown",
            displayName: displayName ?? handle ?? "Megrum",
            avatarURL: avatarUrl,
            gender: gender,
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

private struct UserOwnProfileUpdatePayload: Encodable, Sendable {
    var handle: String
    var displayName: String
    var avatarUrl: URL?
    var shouldEncodeAvatarUrl: Bool
    var gender: UserGender?
    var primaryArea: String?

    enum CodingKeys: String, CodingKey {
        case handle
        case displayName
        case avatarUrl
        case gender
        case primaryArea
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(handle, forKey: .handle)
        try container.encode(displayName, forKey: .displayName)
        if shouldEncodeAvatarUrl {
            if let avatarUrl {
                try container.encode(avatarUrl, forKey: .avatarUrl)
            } else {
                try container.encodeNil(forKey: .avatarUrl)
            }
        }
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(primaryArea, forKey: .primaryArea)
    }
}

private struct GoodsInventoryRow: Decodable, Sendable {
    var id: UUID
    var userId: UUID
    var kind: String?
    var status: String?
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
            kind: GoodsEntryKind(inventoryKind: kind),
            status: status.flatMap(GoodsEntryStatus.init(rawValue:)),
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
            imageURL: photoUrls?.compactMap(URL.init(string:)).first,
            tags: [],
            quantity: quantity ?? 1
        )
    }
}

private func normalizedChatImageContentType(_ value: String) -> String {
    switch value.lowercased() {
    case "image/png":
        "image/png"
    case "image/webp":
        "image/webp"
    default:
        "image/jpeg"
    }
}

private func uploadGoodsPhotoIfNeeded(
    _ upload: GoodsPhotoUpload?,
    client: SupabaseGoodsInventoryClient,
    viewerID: UUID
) async throws -> String? {
    guard let upload else {
        return nil
    }
    return try await client.uploadGoodsPhoto(
        userID: viewerID,
        imageData: upload.data,
        contentType: upload.contentType
    )
}

private func chatImageFileExtension(for contentType: String) -> String {
    switch normalizedChatImageContentType(contentType) {
    case "image/png":
        "png"
    case "image/webp":
        "webp"
    default:
        "jpg"
    }
}

private func chatPhotoPath(proposalID: UUID, messageType: TradeMessageType, contentType: String) -> String {
    let milliseconds = Int(Date().timeIntervalSince1970 * 1_000)
    let prefix = messageType == .outfitPhoto ? "outfit" : "photo"
    return "\(proposalID.uuidString.lowercased())/\(prefix)-\(milliseconds)-\(UUID().uuidString.lowercased()).\(chatImageFileExtension(for: contentType))"
}

private func sortedUUIDs(_ ids: Set<UUID>) -> [UUID] {
    ids.sorted { $0.uuidString < $1.uuidString }
}
