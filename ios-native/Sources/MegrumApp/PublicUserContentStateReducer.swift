import Foundation
import MegrumCore

public enum PublicUserContentStateReducer {
    public static func storingProfile(
        _ profile: PublicUserProfile,
        for userID: UUID,
        in profilesByUserID: [UUID: PublicUserProfile]
    ) -> [UUID: PublicUserProfile] {
        var next = profilesByUserID
        next[userID] = profile
        return next
    }

    public static func storingTradeGoods(
        _ goods: [GoodsItem],
        for userID: UUID,
        in goodsByUserID: [UUID: [GoodsItem]]
    ) -> [UUID: [GoodsItem]] {
        var next = goodsByUserID
        next[userID] = goods
        return next
    }

    public static func storingIndividualListings(
        _ listings: [IndividualListing],
        for userID: UUID,
        in listingsByUserID: [UUID: [IndividualListing]]
    ) -> [UUID: [IndividualListing]] {
        var next = listingsByUserID
        next[userID] = listings
        return next
    }

    public static func storingEvaluations(
        _ evaluations: [UserEvaluation],
        for userID: UUID,
        in evaluationsByUserID: [UUID: [UserEvaluation]]
    ) -> [UUID: [UserEvaluation]] {
        var next = evaluationsByUserID
        next[userID] = evaluations
        return next
    }
}
