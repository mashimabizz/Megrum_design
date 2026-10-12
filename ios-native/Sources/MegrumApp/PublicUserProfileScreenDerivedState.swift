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

    /// 相手の交換条件カレンダー（打診フローの「＞」と同一シート）用コンテキスト。
    var partnerExchangeCalendarContext: HomePartnerExchangeCalendarContext {
        let summary = listings
            .compactMap { IndividualListingExchangeSummary.extract(from: $0.note).summary }
            .first { $0.includesLocal }
        let displayName = displayedPublicProfile?.profile.displayName.nilIfBlank
            ?? displayedPublicProfile?.profile.handle.nilIfBlank
            ?? "相手"
        return PartnerExchangeCalendarContextBuilder.context(
            appState: appState,
            userID: userID,
            listingLocalPrefecture: summary?.localPrefecture,
            listingLocalMemo: summary?.localPlaceMemo,
            conditionText: summary?.localDetailTextForProposalDisplay,
            displayName: displayName
        )
    }

    var listings: [IndividualListing] {
        appState.publicListingsByUserID[userID] ?? []
    }

    var goodsByID: [UUID: GoodsItem] {
        Dictionary(uniqueKeysWithValues: tradeGoods.map { ($0.id, $0) })
    }

    /// プロフィール対象ユーザーのほしいもの（updated_at desc）。
    var publicWishes: [WishItem] {
        appState.publicWishesByUserID[userID] ?? []
    }

    var publicWishByID: [UUID: WishItem] {
        // 以前は viewer 自身の wishes で解決していたため、他人のほしいものが
        // 1件も表示されなかった。プロフィール対象ユーザーの wish で解決する。
        Dictionary(uniqueKeysWithValues: publicWishes.map { ($0.id, $0) })
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
        // 個別募集で求めているものを先頭に、残りのほしいものを新しい順で続ける。
        var seen: Set<UUID> = []
        var items: [ProfileVisualGridItem] = []
        for id in orderedPublicWishIDs {
            if let wish = publicWishByID[id], seen.insert(id).inserted {
                items.append(ProfileVisualGridItem(wish: wish))
            } else if let goods = goodsByID[id], seen.insert(id).inserted {
                items.append(ProfileVisualGridItem(goods: goods))
            }
        }
        for wish in publicWishes where seen.insert(wish.id).inserted {
            items.append(ProfileVisualGridItem(wish: wish))
        }
        return items
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
