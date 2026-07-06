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
            // ほしいものは補助情報なので、失敗しても募集・譲渡グッズの表示は止めない。
            async let wishes = loadPublicWishesBestEffort(userID: userID)
            publicWishesByUserID[userID] = await wishes
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

    private func loadPublicWishesBestEffort(userID: UUID) async -> [WishItem] {
        (try? await repository.loadPublicWishes(userID: userID)) ?? []
    }

    /// グルームでもらった like 総数（プロフィールの Like 表示用）。
    public func loadGroomLikeCount(userID: UUID) async {
        do {
            let count = try await repository.loadGroomLikeCount(userID: userID)
            groomLikeCountByUserID[userID] = max(0, count)
        } catch {
            // 集計に失敗しても画面は既存キャッシュ or 0 表示のままにする
        }
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
