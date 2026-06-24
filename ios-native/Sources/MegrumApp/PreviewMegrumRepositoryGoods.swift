import Foundation
import MegrumCore

public extension PreviewMegrumRepository {
    func loadOshiGroups(searchText: String?, limit: Int) async throws -> [OshiGroup] {
        let groups = NativePreviewData.oshiGroups
        guard let searchText = searchText?.trimmingCharacters(in: .whitespacesAndNewlines), !searchText.isEmpty else {
            return Array(groups.prefix(limit))
        }
        return Array(groups.filter { $0.name.localizedCaseInsensitiveContains(searchText) }.prefix(limit))
    }

    func loadOshiGenres(limit: Int) async throws -> [OshiGenre] {
        Array(NativePreviewData.oshiGenres.prefix(limit))
    }

    func loadOshiCharacters(groupID: UUID, limit: Int) async throws -> [OshiCharacter] {
        Array(NativePreviewData.oshiCharacters.filter { $0.groupID == groupID }.prefix(limit))
    }

    func loadUserOshiSelections() async throws -> [UserOshiSelection] {
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

    func saveUserOshiSelections(_ selections: [AccountSetupOshiInput]) async throws -> [UserOshiSelection] {
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

    func createOshiRequest(_ input: OshiRequestCreateInput) async throws -> UUID {
        UUID()
    }

    func createCharacterRequest(_ input: CharacterRequestCreateInput) async throws -> UUID {
        UUID()
    }

    func loadGoodsTypes(limit: Int) async throws -> [GoodsType] {
        Array(NativePreviewData.goodsTypes.prefix(limit))
    }

    func createGoodsEntry(_ input: GoodsEntryInput) async throws -> GoodsItem {
        GoodsItem(
            id: UUID(),
            ownerID: NativePreviewData.viewerID,
            groupID: input.groupID,
            memberID: input.memberID,
            goodsTypeID: input.goodsTypeID,
            title: input.title,
            imageURL: input.photoUpload == nil
                ? input.photoURLs.compactMap(URL.init(string:)).first
                : URL(string: "https://preview.megrum.jp/goods-photo.jpg"),
            tags: input.tagNames.enumerated().map { index, name in
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", index + 1))") ?? UUID(), name: name)
            },
            quantity: input.quantity
        )
    }

    func updateGoodsEntry(itemID: UUID, kind: GoodsEntryKind, input: GoodsEntryUpdateInput) async throws -> GoodsItem {
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

    func searchGoods(_ input: GoodsSearchInput) async throws -> [GoodsItem] {
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

    func archiveGoodsItem(itemID: UUID) async throws {}

    func deleteGoodsItem(itemID: UUID) async throws {}

    func reportGoods(_ input: GoodsReportCreateInput) async throws -> GoodsReportTicket {
        GoodsReportTicket(
            id: UUID(),
            goodsItemID: input.goodsItemID,
            status: "open"
        )
    }

    func loadIndividualListings() async throws -> [IndividualListing] {
        NativePreviewData.listings
    }

    func createIndividualListing(_ input: IndividualListingCreateInput) async throws -> IndividualListing {
        let listingID = UUID()
        let option = IndividualListingWishOption(
            id: UUID(),
            listingID: listingID,
            position: 1,
            wishes: input.wishItems,
            logic: input.wishLogic,
            minimumCount: input.wishMinimumCount,
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
            haveMinimumCount: input.haveMinimumCount,
            status: .active,
            note: input.note,
            options: [option]
        )
    }

    func updateIndividualListing(
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
            minimumCount: input.wishMinimumCount,
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
            haveMinimumCount: input.haveMinimumCount,
            status: status,
            note: input.note,
            options: [option],
            updatedAt: Date()
        )
    }

    func archiveIndividualListing(listingID: UUID) async throws {}

    func loadPublicTradeGoods(userID: UUID, limit: Int) async throws -> [GoodsItem] {
        let goods = NativePreviewData.inventory.filter { item in
            item.ownerID == userID
        }
        return Array(goods.prefix(max(0, limit)))
    }

    func loadPublicIndividualListings(userID: UUID) async throws -> [IndividualListing] {
        NativePreviewData.publicListings.filter { listing in
            listing.ownerID == userID && listing.status == .active
        }
    }

    func loadPublicUserProfile(userID: UUID) async throws -> PublicUserProfile? {
        if userID == HomeDiscoveryFixtures.ownerID {
            return HomeDiscoveryFixtures.ownerPublicProfile
        }

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

    func loadUserEvaluations(userID: UUID, limit: Int) async throws -> [UserEvaluation] {
        Array(NativePreviewData.userEvaluations.prefix(max(0, limit)))
    }
}
