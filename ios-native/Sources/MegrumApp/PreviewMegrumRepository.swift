import Foundation
import MegrumCore

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

    public func loadHomeCandidateSections() async throws -> HomeCandidateSections {
        let matchedItems = NativePreviewData.homeMatchedItems
        let possibleItems = NativePreviewData.homePossibleItems
        var conditionSignalsByItemID = HomeCandidateConditionSignalDefaults.previewSignals(
            matchedItems: matchedItems,
            possibleItems: possibleItems
        )
        for item in matchedItems where item.ownerID == NativePreviewData.partnerID {
            conditionSignalsByItemID[item.id]?.individualListingSelection = HomeDiscoveryFixtures.miiIndividualListingSelection
        }
        return HomeCandidateSections(
            matchedItems: matchedItems,
            possibleItems: possibleItems,
            conditionSignalsByItemID: conditionSignalsByItemID
        )
    }

    public func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        UserProfile(
            id: NativePreviewData.viewer.id,
            handle: NativePreviewData.viewer.handle,
            displayName: input.displayName,
            avatarURL: NativePreviewData.viewer.avatarURL,
            prefecture: input.prefecture,
            paymentMethods: NativePreviewData.viewer.paymentMethods,
            paymentNote: NativePreviewData.viewer.paymentNote,
            accountStatus: .active
        )
    }

    public func updateOwnProfile(_ input: OwnProfileUpdateInput) async throws -> UserProfile {
        let avatarURL: URL?
        if input.avatarUpload != nil {
            avatarURL = URL(string: "https://preview.megrum.jp/profile-photo.jpg")
        } else if input.clearsAvatar {
            avatarURL = nil
        } else {
            avatarURL = input.avatarURL ?? NativePreviewData.viewer.avatarURL
        }

        return UserProfile(
            id: NativePreviewData.viewer.id,
            handle: normalizedHandle(input.handle),
            displayName: input.displayName,
            avatarURL: avatarURL,
            gender: input.gender,
            prefecture: input.prefecture,
            paymentMethods: input.paymentMethods,
            paymentNote: NativePreviewData.viewer.paymentNote,
            accountStatus: .active
        )
    }

    public func loadPaymentSettings() async throws -> UserPaymentSettings? {
        NativePreviewData.paymentSettings
    }

    public func savePaymentSettings(_ settings: UserPaymentSettings) async throws -> (profile: UserProfile, settings: UserPaymentSettings) {
        let normalized = settings.normalized(for: NativePreviewData.viewer.id)
        let profile = UserProfile(
            id: NativePreviewData.viewer.id,
            handle: NativePreviewData.viewer.handle,
            displayName: NativePreviewData.viewer.displayName,
            avatarURL: NativePreviewData.viewer.avatarURL,
            gender: NativePreviewData.viewer.gender,
            prefecture: NativePreviewData.viewer.prefecture,
            paymentMethods: normalized.methods,
            paymentNote: normalized.otherNote,
            accountStatus: .active
        )
        return (profile, normalized)
    }

    private func normalizedHandle(_ handle: String) -> String {
        var normalized = handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        while normalized.first == "@" {
            normalized.removeFirst()
        }
        return normalized
    }

    public func loadOshiGroups(searchText: String?, limit: Int) async throws -> [OshiGroup] {
        let groups = NativePreviewData.oshiGroups
        guard let searchText = searchText?.trimmingCharacters(in: .whitespacesAndNewlines), !searchText.isEmpty else {
            return Array(groups.prefix(limit))
        }
        return Array(groups.filter { $0.name.localizedCaseInsensitiveContains(searchText) }.prefix(limit))
    }

    public func loadOshiGenres(limit: Int) async throws -> [OshiGenre] {
        Array(NativePreviewData.oshiGenres.prefix(limit))
    }

    public func loadOshiCharacters(groupID: UUID, limit: Int) async throws -> [OshiCharacter] {
        Array(NativePreviewData.oshiCharacters.filter { $0.groupID == groupID }.prefix(limit))
    }

    public func loadUserOshiSelections() async throws -> [UserOshiSelection] {
        [
            UserOshiSelection(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000a1")!,
                userID: NativePreviewData.viewerID,
                groupID: NativePreviewData.groupID,
                characterID: NativePreviewData.memberID,
                kind: .specific,
                priority: 1,
                groupName: "aespa",
                characterName: "カリナ"
            )
        ]
    }

    public func saveUserOshiSelections(_ selections: [AccountSetupOshiInput]) async throws -> [UserOshiSelection] {
        let prioritizedSelections = selections.enumerated().map { offset, selection in
            var next = selection
            next.priority = offset + 1
            return next
        }
        return UserOshiSelectionPersistenceMapper.selections(
            from: prioritizedSelections,
            userID: NativePreviewData.viewerID
        )
    }

    public func createOshiRequest(_ input: OshiRequestCreateInput) async throws -> UUID {
        UUID()
    }

    public func createCharacterRequest(_ input: CharacterRequestCreateInput) async throws -> UUID {
        UUID()
    }

    public func loadGoodsTypes(limit: Int) async throws -> [GoodsType] {
        Array(NativePreviewData.goodsTypes.prefix(limit))
    }

    public func createGoodsEntry(_ input: GoodsEntryInput) async throws -> GoodsItem {
        GoodsItem(
            id: UUID(),
            ownerID: NativePreviewData.viewerID,
            groupID: input.groupID,
            memberID: input.memberID,
            goodsTypeID: input.goodsTypeID,
            title: input.title,
            imageURL: input.photoUpload == nil ? nil : URL(string: "https://preview.megrum.jp/goods-photo.jpg"),
            tags: input.tagNames.enumerated().map { index, name in
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", index + 1))") ?? UUID(), name: name)
            },
            quantity: input.quantity
        )
    }

    public func updateGoodsEntry(itemID: UUID, kind: GoodsEntryKind, input: GoodsEntryUpdateInput) async throws -> GoodsItem {
        GoodsItem(
            id: itemID,
            ownerID: NativePreviewData.viewerID,
            groupID: input.groupID,
            memberID: input.memberID,
            goodsTypeID: input.goodsTypeID,
            title: input.title,
            imageURL: input.photoUpload == nil ? input.photoURLs?.compactMap(URL.init(string:)).first : URL(string: "https://preview.megrum.jp/goods-photo.jpg"),
            tags: input.tagNames?.enumerated().map { index, name in
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", index + 1))") ?? UUID(), name: name)
            } ?? [],
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
            exchangeType: input.exchangeType,
            isCashOffer: input.isCashOffer,
            cashAmount: input.cashAmount,
            wishGroupID: input.wishGroupID,
            wishGoodsTypeID: input.wishGoodsTypeID
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

    public func updateIndividualListing(
        listingID: UUID,
        primaryOptionID: UUID?,
        input: IndividualListingCreateInput,
        status: IndividualListingStatus
    ) async throws -> IndividualListing {
        let option = IndividualListingWishOption(
            id: primaryOptionID ?? UUID(),
            listingID: listingID,
            position: 1,
            wishes: input.wishItems,
            logic: input.wishLogic,
            exchangeType: input.exchangeType,
            isCashOffer: input.isCashOffer,
            cashAmount: input.cashAmount,
            wishGroupID: input.wishGroupID,
            wishGoodsTypeID: input.wishGoodsTypeID,
            updatedAt: Date()
        )
        return IndividualListing(
            id: listingID,
            ownerID: NativePreviewData.viewerID,
            haves: input.haveItems,
            haveLogic: input.haveLogic,
            status: status,
            note: input.note,
            options: [option],
            updatedAt: Date()
        )
    }

    public func archiveIndividualListing(listingID: UUID) async throws {}

    public func loadPublicTradeGoods(userID: UUID, limit: Int) async throws -> [GoodsItem] {
        let goods = NativePreviewData.inventory.filter { item in
            item.ownerID == userID
        }
        return Array(goods.prefix(max(0, limit)))
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
            completedTradeCount: 12,
            oshiTags: previewPublicOshiTags(for: userID)
        )
    }

    private func previewPublicOshiTags(for userID: UUID) -> [PublicOshiTag] {
        if userID == NativePreviewData.partnerID {
            return [
                PublicOshiTag(title: "TWICE", groupID: NativePreviewData.groupID, priority: 1),
                PublicOshiTag(title: "IVE", groupID: NativePreviewData.secondGroupID, priority: 2),
                PublicOshiTag(
                    title: "ウォニョン",
                    groupID: NativePreviewData.secondGroupID,
                    characterID: NativePreviewData.secondMemberID,
                    priority: 2
                )
            ]
        }
        return [
            PublicOshiTag(title: "aespa", groupID: NativePreviewData.groupID, priority: 1),
            PublicOshiTag(
                title: "カリナ",
                groupID: NativePreviewData.groupID,
                characterID: NativePreviewData.memberID,
                priority: 1
            )
        ]
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
            cashOffer: input.cashOffer,
            cashAmount: input.cashAmount,
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
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
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
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
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

    public func approveTradeCancel(proposalID: UUID) async throws -> (proposal: TradeProposal, message: TradeMessage) {
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.partnerID,
                receiverID: NativePreviewData.viewerID,
                status: .agreed,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: []
            )
        let cancelled = TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: .cancelled,
            exchangeMethod: proposal.exchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
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
        let message = TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .system,
            body: "キャンセル申請に同意しました",
            meta: [
                "action": "cancel_approved",
                "approved_by": NativePreviewData.viewerID.uuidString.lowercased()
            ]
        )
        return (cancelled, message)
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
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
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
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
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

    public func loadTradeEvidencePhotos(proposalID: UUID) async throws -> [TradeEvidencePhoto] {
        [
            TradeEvidencePhoto(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000e101")!,
                proposalID: proposalID,
                photoURL: URL(string: "https://picsum.photos/seed/megrum-evidence-1/640/480")!,
                position: 1,
                takenAt: .now,
                takenBy: NativePreviewData.viewerID
            ),
            TradeEvidencePhoto(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000e102")!,
                proposalID: proposalID,
                photoURL: URL(string: "https://picsum.photos/seed/megrum-evidence-2/640/480")!,
                position: 2,
                takenAt: .now.addingTimeInterval(-120),
                takenBy: NativePreviewData.partnerID
            )
        ]
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

    public func sendPhotoMessage(_ input: TradePhotoMessageCreateInput) async throws -> TradeMessage {
        TradeMessage(
            id: UUID(),
            proposalID: input.proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: input.messageType,
            body: input.body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank,
            photoURL: URL(string: "https://preview.megrum.local/chat/\(UUID().uuidString.lowercased()).jpg")
        )
    }

    public func sendSystemMessage(proposalID: UUID, body: String) async throws -> TradeMessage {
        TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .system,
            body: body
        )
    }

    public func sendLateNoticeMessage(
        proposalID: UUID,
        lateMinutes: Int,
        reason: String,
        note: String?
    ) async throws -> TradeMessage {
        let normalizedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedReason.isEmpty else {
            throw MegrumRepositoryError.unsupportedMutation
        }
        let normalizedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        let body = "\(Self.lateMinutesLabel(lateMinutes))遅れる旨が通知されました\n理由：\(normalizedReason)\(normalizedNote.map { "\n\($0)" } ?? "")"
        var meta = [
            "action": "late_notice",
            "notified_by": NativePreviewData.viewerID.uuidString.lowercased(),
            "late_minutes": "\(lateMinutes)",
            "reason": normalizedReason
        ]
        if let normalizedNote {
            meta["note"] = normalizedNote
        }
        return TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .system,
            body: body,
            meta: meta
        )
    }

    public func sendCancelRequestMessage(
        proposalID: UUID,
        reason: String,
        note: String?
    ) async throws -> TradeMessage {
        let normalizedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedReason.isEmpty else {
            throw MegrumRepositoryError.unsupportedMutation
        }
        let normalizedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        let body = "取引キャンセルが申請されました\n理由：\(normalizedReason)\(normalizedNote.map { "\n\($0)" } ?? "")"
        var meta = [
            "action": "cancel_requested",
            "requested_by": NativePreviewData.viewerID.uuidString.lowercased(),
            "reason": normalizedReason
        ]
        if let normalizedNote {
            meta["note"] = normalizedNote
        }
        return TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .system,
            body: body,
            meta: meta
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

    private static func lateMinutesLabel(_ minutes: Int) -> String {
        switch minutes {
        case 60:
            "1時間"
        case 90:
            "1時間以上"
        default:
            "\(minutes)分"
        }
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

    public func loadPersonalSchedules(startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        NativePreviewData.schedules
            .filter { $0.userID == NativePreviewData.viewerID && $0.overlaps(start: startAt, end: endAt) }
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

    public func loadHomeLocalModeSettings(now: Date) async throws -> HomeLocalActivitySettings? {
        nil
    }

    public func saveHomeLocalModeSettings(
        _ settings: HomeLocalActivitySettings,
        now: Date
    ) async throws -> HomeLocalActivitySettings {
        var normalized = settings.normalizedForPersistence(now: now)
        if normalized.isEnabled, normalized.activityWindowID == nil {
            normalized.activityWindowID = UUID()
        }
        return normalized
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
        let imageURLs = previewBoardThreadImageURLs(from: input)
        return BoardThread(
            id: UUID(),
            authorID: NativePreviewData.viewerID,
            title: input.title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: input.body.trimmingCharacters(in: .whitespacesAndNewlines),
            audience: input.audience,
            latitude: input.latitude,
            longitude: input.longitude,
            prefecture: input.prefecture,
            imageURLs: imageURLs,
            imagePaths: input.imagePaths
        )
    }

    private func previewBoardThreadImageURLs(from input: BoardThreadCreateInput) -> [URL] {
        var urls = input.imagePaths.compactMap(URL.init(string:))
        if let thumbnailURL = previewBoardThreadThumbnailURL(from: input.thumbnailUpload) {
            urls.insert(thumbnailURL, at: 0)
        }
        return urls
    }

    private func previewBoardThreadThumbnailURL(from upload: GoodsPhotoUpload?) -> URL? {
        guard let upload else {
            return nil
        }
        let fileExtension = upload.contentType.lowercased().contains("png") ? "png" : "jpg"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("megrum-board-thumbnail-\(UUID().uuidString).\(fileExtension)")
        do {
            try upload.data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
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

private extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}

private func normalizedPostalCode(_ value: String) -> String {
    String(value.filter(\.isNumber).prefix(7))
}
