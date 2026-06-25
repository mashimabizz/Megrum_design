import Foundation
import MegrumCore

extension PublicUserProfileScreen {
    var publicProfile: PublicUserProfile? {
        appState.publicProfilesByUserID[userID]
    }

    var displayedPublicProfile: PublicUserProfile? {
        publicProfile ?? fallbackPublicProfile
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
            ProfileVisualTagItem(title: tag.title, colorKey: tag.colorKey)
        }
    }

    func publicProfileGridItems(for tab: ProfileVisualTab) -> [ProfileVisualGridItem] {
        switch tab {
        case .goods:
            return tradeGoods.map { item in
                ProfileVisualGridItem(id: item.id, title: item.title, imageURL: item.imageURL, showsMatchTags: true)
            }
        case .listings:
            return listings.compactMap { listing in
                guard let firstHave = listing.haves.first,
                      let item = goodsByID[firstHave.itemID] else {
                    return nil
                }
                return ProfileVisualGridItem(id: listing.id, title: item.title, imageURL: item.imageURL, showsMatchTags: true)
            }
        case .wish:
            let wishIDs = listings
                .flatMap(\.options)
                .flatMap(\.wishes)
                .map(\.itemID)
            return Array(Set(wishIDs)).compactMap { id in
                guard let item = goodsByID[id] else {
                    return nil
                }
                return ProfileVisualGridItem(id: item.id, title: item.title, imageURL: item.imageURL)
            }
        }
    }

    func cleanText(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
