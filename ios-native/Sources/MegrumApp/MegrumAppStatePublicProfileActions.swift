import Foundation
import MegrumCore

@MainActor
extension MegrumAppState {
    public func loadPublicUserProfile(userID: UUID, reportsFailure: Bool = true) async {
        guard loadingPublicProfileUserID != userID else {
            return
        }
        await loadBlockedContentUserIDsIfNeeded(reportsFailure: false)
        guard !blockedContentUserIDs.contains(userID) else {
            removeBlockedContent(userID: userID)
            return
        }
        loadingPublicProfileUserID = userID
        errorMessage = nil
        do {
            if let profile = try await repository.loadPublicUserProfile(userID: userID) {
                publicProfilesByUserID = PublicUserContentStateReducer.storingProfile(
                    profile,
                    for: userID,
                    in: publicProfilesByUserID
                )
            }
        } catch {
            if reportsFailure {
                errorMessage = "プロフィールを読み込めませんでした"
            }
        }
        loadingPublicProfileUserID = nil
    }

    public func loadPublicExchangeContent(userID: UUID) async {
        guard loadingPublicExchangeUserID != userID else {
            return
        }
        await loadBlockedContentUserIDsIfNeeded(reportsFailure: false)
        guard !blockedContentUserIDs.contains(userID) else {
            removeBlockedContent(userID: userID)
            return
        }
        loadingPublicExchangeUserID = userID
        errorMessage = nil
        do {
            async let tradeGoods = repository.loadPublicTradeGoods(userID: userID, limit: 60)
            async let listings = repository.loadPublicIndividualListings(userID: userID)
            publicTradeGoodsByUserID = PublicUserContentStateReducer.storingTradeGoods(
                BlockedUserContentFilter.goods(
                    try await tradeGoods,
                    blockedUserIDs: blockedContentUserIDs
                ),
                for: userID,
                in: publicTradeGoodsByUserID
            )
            publicListingsByUserID = PublicUserContentStateReducer.storingIndividualListings(
                BlockedUserContentFilter.listings(
                    try await listings,
                    blockedUserIDs: blockedContentUserIDs
                ),
                for: userID,
                in: publicListingsByUserID
            )
        } catch {
            errorMessage = "プロフィールの交換情報を読み込めませんでした"
        }
        loadingPublicExchangeUserID = nil
    }

    public func loadUserEvaluations(userID: UUID, limit: Int = 50) async {
        guard loadingEvaluationsUserID != userID else {
            return
        }
        await loadBlockedContentUserIDsIfNeeded(reportsFailure: false)
        guard !blockedContentUserIDs.contains(userID) else {
            removeBlockedContent(userID: userID)
            return
        }
        loadingEvaluationsUserID = userID
        errorMessage = nil
        do {
            userEvaluationsByUserID = PublicUserContentStateReducer.storingEvaluations(
                try await repository.loadUserEvaluations(userID: userID, limit: limit),
                for: userID,
                in: userEvaluationsByUserID
            )
        } catch {
            errorMessage = "評価を読み込めませんでした"
        }
        loadingEvaluationsUserID = nil
    }
}
