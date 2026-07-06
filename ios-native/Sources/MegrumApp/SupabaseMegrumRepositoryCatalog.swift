import Foundation
import MegrumCore
import MegrumData

public extension SupabaseMegrumRepository {
    func loadOshiGroups(searchText: String?, limit: Int) async throws -> [OshiGroup] {
        try await oshiClient.loadGroups(searchText: searchText, limit: limit)
    }

    func loadOshiGenres(limit: Int) async throws -> [OshiGenre] {
        try await oshiClient.loadGenres(limit: limit)
    }

    func searchOshiCharacterGroupIDs(query: String) async throws -> [UUID] {
        try await oshiClient.searchCharacterGroupIDs(matching: query)
    }

    func loadOshiCharacters(groupID: UUID, limit: Int) async throws -> [OshiCharacter] {
        try await oshiClient.loadCharacters(groupID: groupID, limit: limit)
    }

    func loadMemberFaceProfiles(memberIDs: [UUID], limit: Int) async throws -> [MemberFaceProfile] {
        try await faceRecognitionClient.loadMemberFaceProfiles(memberIDs: memberIDs, limit: limit)
    }

    func loadUserOshiSelections() async throws -> [UserOshiSelection] {
        try await oshiClient.loadUserSelections(userID: viewerID)
    }

    func saveUserOshiSelections(_ selections: [AccountSetupOshiInput]) async throws -> [UserOshiSelection] {
        let rows = UserOshiSelectionPersistenceMapper.selections(from: selections, userID: viewerID)
        return try await oshiClient.replaceUserSelections(userID: viewerID, selections: rows)
    }

    func createOshiRequest(_ input: OshiRequestCreateInput) async throws -> UUID {
        try await oshiClient.createOshiRequest(userID: viewerID, input: input)
    }

    func createCharacterRequest(_ input: CharacterRequestCreateInput) async throws -> UUID {
        try await oshiClient.createCharacterRequest(userID: viewerID, input: input)
    }

    func loadGoodsTypes(limit: Int) async throws -> [GoodsType] {
        try await goodsInventoryClient.loadGoodsTypes(limit: limit)
    }

    func createGoodsEntry(_ input: GoodsEntryInput) async throws -> GoodsItem {
        try await goodsEntryPersistence.createGoodsEntry(input)
    }

    func updateGoodsEntry(itemID: UUID, kind: GoodsEntryKind, input: GoodsEntryUpdateInput) async throws -> GoodsItem {
        try await goodsEntryPersistence.updateGoodsEntry(itemID: itemID, input: input)
    }

    func suggestGoodsSeriesNamesFromImage(_ input: GoodsSeriesSuggestionInput) async throws -> [String] {
        try await goodsSeriesSuggestionClient.suggestSeriesNames(input: input)
    }

    func uploadGoodsGoogleLensSearchPhoto(_ upload: GoodsPhotoUpload) async throws -> URL {
        let rawURL = try await goodsInventoryClient.uploadGoodsPhoto(
            userID: viewerID,
            imageData: upload.data,
            contentType: upload.contentType
        )
        guard let url = URL(string: rawURL) else {
            throw URLError(.badURL)
        }
        return url
    }

    func searchGoods(_ input: GoodsSearchInput) async throws -> [GoodsItem] {
        try await goodsInventoryClient.searchGoods(viewerID: viewerID, input: input)
    }

    func archiveGoodsItem(itemID: UUID) async throws {
        _ = try await goodsInventoryClient.archiveGoodsItem(userID: viewerID, itemID: itemID)
    }

    func deleteGoodsItem(itemID: UUID) async throws {
        try await goodsInventoryClient.deleteGoodsItem(userID: viewerID, itemID: itemID)
    }

    func reportGoods(_ input: GoodsReportCreateInput) async throws -> GoodsReportTicket {
        try await goodsReportClient.createReport(reporterID: viewerID, input: input)
    }

    func reportUser(_ input: UserReportCreateInput) async throws -> UserReportTicket {
        try await userReportClient.createReport(reporterID: viewerID, input: input)
    }

    func loadIndividualListings() async throws -> [IndividualListing] {
        try await listingClient.loadListings(userID: viewerID)
    }

    func createIndividualListing(_ input: IndividualListingCreateInput) async throws -> IndividualListing {
        try await listingClient.createListing(userID: viewerID, input: input)
    }

    func updateIndividualListing(
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

    func archiveIndividualListing(listingID: UUID) async throws {
        try await listingClient.archiveListing(userID: viewerID, listingID: listingID)
    }

    func loadPublicTradeGoods(userID: UUID, limit: Int) async throws -> [GoodsItem] {
        try await goodsInventoryClient.loadPublicTradeGoods(userID: userID, limit: limit)
    }

    func loadPublicIndividualListings(userID: UUID) async throws -> [IndividualListing] {
        try await listingClient.loadPublicListings(userID: userID)
    }

    func loadPublicWishes(userID: UUID) async throws -> [WishItem] {
        try await ownedGoodsPersistence.loadPublicWishes(of: userID)
    }

    func loadPublicUserProfile(userID: UUID) async throws -> PublicUserProfile? {
        try await publicProfilePersistence.loadProfile(userID: userID)
    }

    func loadGroomLikeCount(userID: UUID) async throws -> Int {
        try await publicProfilePersistence.loadGroomLikeCount(userID: userID)
    }

    func loadUserEvaluations(userID: UUID, limit: Int) async throws -> [UserEvaluation] {
        try await publicProfilePersistence.loadEvaluations(userID: userID, limit: limit)
    }
}
