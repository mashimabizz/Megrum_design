import Foundation
import MegrumCore

extension PublicUserProfileScreen {
    var publicProfile: PublicUserProfile? {
        appState.publicProfilesByUserID[userID]
    }

    var displayedPublicProfile: PublicUserProfile? {
        publicProfile ?? fallbackPublicProfile
    }

    var moderationTarget: PublicProfileModerationTarget? {
        guard appState.viewer?.id != userID else {
            return nil
        }
        let profile = displayedPublicProfile?.profile
        return PublicProfileModerationTarget(
            userID: userID,
            displayName: profile?.displayName ?? profile?.handle ?? "このユーザー"
        )
    }

    var fallbackPublicProfile: PublicUserProfile? {
        userID == HomeDiscoveryFixtures.ownerID ? HomeDiscoveryFixtures.ownerPublicProfile : nil
    }

    var evaluations: [UserEvaluation] {
        appState.userEvaluationsByUserID[userID] ?? []
    }

    var tradeGoods: [GoodsItem] {
        appState.publicTradeGoodsByUserID[userID] ?? []
    }

    var listings: [IndividualListing] {
        appState.publicListingsByUserID[userID] ?? []
    }

    var goodsByID: [UUID: GoodsItem] {
        Dictionary(uniqueKeysWithValues: tradeGoods.map { ($0.id, $0) })
    }

    var publicWishByID: [UUID: WishItem] {
        Dictionary(uniqueKeysWithValues: appState.wishes.map { ($0.id, $0) })
    }

    func publicProfileBio(_ publicProfile: PublicUserProfile) -> String {
        if let bio = cleanText(publicProfile.profile.bio) {
            return bio
        }
        let parts = [
            cleanText(publicProfile.profile.prefecture),
            publicProfile.profile.gender?.displayName
        ].compactMap { $0 }
        guard !parts.isEmpty else {
            return "公開プロフィール"
        }
        return parts.joined(separator: " / ")
    }

    func publicProfileRating(_ publicProfile: PublicUserProfile) -> String {
        guard let averageStars = publicProfile.averageStars else {
            return "—"
        }
        return String(format: "%.1f", averageStars)
    }

    func publicProfileOshiTags(_ publicProfile: PublicUserProfile) -> [ProfileVisualTagItem] {
        publicProfile.oshiTags.map { tag in
            ProfileVisualTagItem(title: tag.title, colorKey: tag.colorKey, kind: tag.characterID == nil ? .group : .member)
        }
    }

    var publicProfileGoodsGridItems: [ProfileVisualGridItem] {
        tradeGoods.map(ProfileVisualGridItem.init(goods:))
    }

    var publicProfileWishGridItems: [ProfileVisualGridItem] {
        orderedPublicWishIDs.compactMap { id in
            if let wish = publicWishByID[id] {
                return ProfileVisualGridItem(wish: wish)
            }
            if let goods = goodsByID[id] {
                return ProfileVisualGridItem(goods: goods)
            }
            return nil
        }
    }

    private var orderedPublicWishIDs: [UUID] {
        var seen: Set<UUID> = []
        return listings
            .flatMap(\.options)
            .flatMap(\.wishes)
            .compactMap { wish in
                guard seen.insert(wish.itemID).inserted else {
                    return nil
                }
                return wish.itemID
            }
    }

    func cleanText(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
