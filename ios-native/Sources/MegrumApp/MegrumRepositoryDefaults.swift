import Foundation
import MegrumCore

public extension MegrumRepository {
    func loadSubscriptionState() async throws -> UserSubscriptionState {
        .free
    }

    func syncMegrumPlusPurchase(_ input: MegrumPlusPurchaseSyncInput) async throws -> UserSubscriptionState {
        UserSubscriptionState(
            planType: .megrumPlusMonthly,
            status: .active,
            currentPeriodEnd: input.expiresAt,
            entitlements: [
                UserEntitlement(
                    key: .megrumPlus,
                    isActive: true,
                    source: .purchase,
                    grantedAt: input.verifiedAt,
                    expiresAt: input.expiresAt,
                    updatedAt: input.verifiedAt
                )
            ],
            loadedAt: input.verifiedAt
        )
    }

    func loadHomeCandidateSections() async throws -> HomeCandidateSections {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadOshiGenres(limit: Int) async throws -> [OshiGenre] {
        []
    }

    func loadOshiGroups(searchText: String?, limit: Int) async throws -> [OshiGroup] {
        []
    }

    func loadOshiCharacters(groupID: UUID, limit: Int) async throws -> [OshiCharacter] {
        []
    }

    func loadMemberFaceProfiles(memberIDs: [UUID], limit: Int) async throws -> [MemberFaceProfile] {
        []
    }

    func loadUserOshiSelections() async throws -> [UserOshiSelection] {
        []
    }

    func saveUserOshiSelections(_ selections: [AccountSetupOshiInput]) async throws -> [UserOshiSelection] {
        []
    }

    func createOshiRequest(_ input: OshiRequestCreateInput) async throws -> UUID {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func createCharacterRequest(_ input: CharacterRequestCreateInput) async throws -> UUID {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadGoodsTypes(limit: Int) async throws -> [GoodsType] {
        []
    }

    func createGoodsEntry(_ input: GoodsEntryInput) async throws -> GoodsItem {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func updateGoodsEntry(itemID: UUID, kind: GoodsEntryKind, input: GoodsEntryUpdateInput) async throws -> GoodsItem {
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

    func reportUser(_ input: UserReportCreateInput) async throws -> UserReportTicket {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadIndividualListings() async throws -> [IndividualListing] {
        []
    }

    func createIndividualListing(_ input: IndividualListingCreateInput) async throws -> IndividualListing {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func updateIndividualListing(
        listingID: UUID,
        primaryOptionID: UUID?,
        input: IndividualListingCreateInput,
        status: IndividualListingStatus
    ) async throws -> IndividualListing {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func archiveIndividualListing(listingID: UUID) async throws {
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

    func loadExchangeSettings(userID: UUID) async throws -> HomeDefaultExchangeSettings? {
        nil
    }

    func saveExchangeSettings(_ settings: HomeDefaultExchangeSettings) async throws -> HomeDefaultExchangeSettings {
        settings
    }
}
