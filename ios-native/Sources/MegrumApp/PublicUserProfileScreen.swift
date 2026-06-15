import MegrumCore
import MegrumDesign
import SwiftUI

struct PublicProfileRoute: Identifiable, Equatable {
    var userID: UUID
    var id: UUID { userID }
}

struct PublicUserProfileScreen: View {
    @ObservedObject var appState: MegrumAppState
    var userID: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var selectedVisualTab: ProfileVisualTab = .goods
    @State private var proposalTargetItem: GoodsItem?
    @State private var listingProposalTarget: ListingProposalTarget?

    private var publicProfile: PublicUserProfile? {
        appState.publicProfilesByUserID[userID]
    }

    private var evaluations: [UserEvaluation] {
        appState.userEvaluationsByUserID[userID] ?? []
    }

    private var tradeGoods: [GoodsItem] {
        appState.publicTradeGoodsByUserID[userID] ?? []
    }

    private var listings: [IndividualListing] {
        appState.publicListingsByUserID[userID] ?? []
    }

    private var goodsByID: [UUID: GoodsItem] {
        Dictionary(uniqueKeysWithValues: tradeGoods.map { ($0.id, $0) })
    }

    private var publicWishByID: [UUID: WishItem] {
        Dictionary(uniqueKeysWithValues: appState.wishes.map { ($0.id, $0) })
    }

    var body: some View {
        ScrollView {
            PublicUserProfileContent(
                publicProfile: publicProfile,
                selectedVisualTab: $selectedVisualTab,
                bio: publicProfile.map(publicProfileBio) ?? "",
                ratingText: publicProfile.map(publicProfileRating) ?? "—",
                chips: [],
                oshiTags: publicProfile.map(publicProfileOshiTags) ?? [],
                gridItems: publicProfileGridItems(for: selectedVisualTab),
                listings: listings,
                listingGoodsByID: goodsByID,
                listingWishByID: publicWishByID,
                groups: appState.oshiGroups,
                characters: appState.oshiCharacters,
                goodsTypes: appState.goodsTypes,
                onPrimaryAction: startPrimaryProposal,
                onSelectGridItem: selectProfileGridItem,
                onSelectListing: selectProfileListing
            )
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("プロフィール")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .task(id: userID) {
            await appState.loadPublicUserProfile(userID: userID)
            await appState.loadPublicExchangeContent(userID: userID)
            await appState.loadUserEvaluations(userID: userID)
            if appState.oshiGroups.isEmpty {
                await appState.loadOshiGroups()
            }
            if appState.goodsTypes.isEmpty {
                await appState.loadGoodsTypes()
            }
        }
        .sheet(item: $proposalTargetItem) { item in
            NavigationStack {
                ProposalCreateFlow(appState: appState, targetItem: item)
            }
        }
        .sheet(item: $listingProposalTarget) { target in
            NavigationStack {
                ProposalCreateFlow(
                    appState: appState,
                    targetItem: target.targetItem,
                    listingID: target.listing.id,
                    receiverGoodsIDs: target.receiverGoodsIDs
                )
            }
        }
    }

    private func publicProfileBio(_ publicProfile: PublicUserProfile) -> String {
        let parts = [
            cleanText(publicProfile.profile.prefecture),
            publicProfile.profile.gender?.displayName
        ].compactMap { $0 }
        guard !parts.isEmpty else {
            return "公開プロフィール"
        }
        return parts.joined(separator: " / ")
    }

    private func publicProfileRating(_ publicProfile: PublicUserProfile) -> String {
        guard let averageStars = publicProfile.averageStars else {
            return "—"
        }
        return String(format: "%.1f", averageStars)
    }

    private func publicProfileOshiTags(_ publicProfile: PublicUserProfile) -> [ProfileVisualTagItem] {
        publicProfile.oshiTags.map { tag in
            ProfileVisualTagItem(title: tag.title, colorKey: tag.colorKey)
        }
    }

    private func publicProfileGridItems(for tab: ProfileVisualTab) -> [ProfileVisualGridItem] {
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

    private func selectProfileGridItem(_ item: ProfileVisualGridItem) {
        switch selectedVisualTab {
        case .goods:
            guard let goods = tradeGoods.first(where: { $0.id == item.id }) else {
                return
            }
            proposalTargetItem = goods
        case .listings:
            selectProfileListing(item.id)
        case .wish:
            break
        }
    }

    private func selectProfileListing(_ listingID: UUID) {
        guard let listing = listings.first(where: { $0.id == listingID }),
              let target = ListingProposalTarget(listing: listing, goodsByID: goodsByID) else {
            return
        }
        listingProposalTarget = target
    }

    private func cleanText(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func startPrimaryProposal() {
        if let goods = tradeGoods.first {
            proposalTargetItem = goods
            return
        }
        if let target = listings.compactMap({ ListingProposalTarget(listing: $0, goodsByID: goodsByID) }).first {
            listingProposalTarget = target
        }
    }
}

struct ListingProposalTarget: Identifiable, Equatable {
    var listing: IndividualListing
    var targetItem: GoodsItem
    var receiverGoodsIDs: [UUID]

    var id: UUID { listing.id }

    init?(listing: IndividualListing, goodsByID: [UUID: GoodsItem]) {
        let receiverGoodsIDs = listing.haves.map(\.itemID).deduplicated()
        guard
            let targetItem = receiverGoodsIDs.compactMap({ goodsByID[$0] }).first
        else {
            return nil
        }
        self.listing = listing
        self.targetItem = targetItem
        self.receiverGoodsIDs = receiverGoodsIDs
    }
}

private extension Array where Element == UUID {
    func deduplicated() -> [UUID] {
        var seen: Set<UUID> = []
        return filter { seen.insert($0).inserted }
    }
}

struct PublicProfileEvaluationListState: Equatable {
    var evaluationCount: Int
    var isLoading: Bool

    init(evaluations: [UserEvaluation], isLoading: Bool) {
        self.evaluationCount = evaluations.count
        self.isLoading = isLoading
    }

    var showsLoading: Bool {
        isLoading && evaluationCount == 0
    }

    var showsEmpty: Bool {
        !isLoading && evaluationCount == 0
    }
}
