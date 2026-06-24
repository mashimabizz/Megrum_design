import MegrumCore
import MegrumDesign
import SwiftUI

struct PublicProfileRoute: Identifiable, Equatable {
    var userID: UUID
    var id: UUID { userID }
}

enum PublicProfilePresentationContext: Equatable, Sendable {
    case standalone
    case stackedFromHomeDiscoverySheet
    case tradeChat

    var allowsProposalActions: Bool {
        self == .standalone
    }

    var showsDismissToolbarButton: Bool {
        self != .tradeChat
    }
}

struct PublicUserProfileScreen: View {
    @ObservedObject var appState: MegrumAppState
    var userID: UUID
    var presentationContext: PublicProfilePresentationContext = .standalone
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    var adPlacement: AdPlacement?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedVisualTab: ProfileVisualTab = .goods
    @State private var proposalTargetItem: GoodsItem?
    @State private var listingProposalTarget: ListingProposalTarget?
    @State private var isSchedulePresented = false

    private var publicProfile: PublicUserProfile? {
        appState.publicProfilesByUserID[userID]
    }

    private var displayedPublicProfile: PublicUserProfile? {
        publicProfile ?? fallbackPublicProfile
    }

    private var fallbackPublicProfile: PublicUserProfile? {
        userID == HomeDiscoveryFixtures.ownerID ? HomeDiscoveryFixtures.ownerPublicProfile : nil
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
        let profile = displayedPublicProfile
        ScrollView {
            PublicUserProfileContent(
                publicProfile: profile,
                selectedVisualTab: $selectedVisualTab,
                bio: profile.map(publicProfileBio) ?? "",
                ratingText: profile.map(publicProfileRating) ?? "—",
                chips: [],
                oshiTags: profile.map(publicProfileOshiTags) ?? [],
                gridItems: publicProfileGridItems(for: selectedVisualTab),
                listings: listings,
                listingGoodsByID: goodsByID,
                listingWishByID: publicWishByID,
                groups: appState.oshiGroups,
                characters: appState.oshiCharacters,
                goodsTypes: appState.goodsTypes,
                adDisplayContext: adDisplayContext,
                adPlacement: adPlacement,
                showsProposalAction: presentationContext.allowsProposalActions,
                onPrimaryAction: startPrimaryProposal,
                onOpenSchedule: openSchedule,
                onSelectGridItem: selectProfileGridItem,
                onSelectListing: selectProfileListing
            )
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("プロフィール")
        .megrumInlineNavigationTitle()
        .toolbar {
            if presentationContext.showsDismissToolbarButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .megrumEdgeBackSwipe {
            dismiss()
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
        .sheet(isPresented: $isSchedulePresented) {
            NavigationStack {
                ProfileScheduleScreen(
                    appState: appState,
                    userID: userID,
                    displayName: displayedPublicProfile?.profile.displayName ?? "相手"
                ) {
                    isSchedulePresented = false
                }
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
        guard presentationContext.allowsProposalActions else {
            return
        }
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
        guard presentationContext.allowsProposalActions else {
            return
        }
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
        guard presentationContext.allowsProposalActions else {
            return
        }
        if let goods = tradeGoods.first {
            proposalTargetItem = goods
            return
        }
        if let target = listings.compactMap({ ListingProposalTarget(listing: $0, goodsByID: goodsByID) }).first {
            listingProposalTarget = target
        }
    }

    private func openSchedule() {
        isSchedulePresented = true
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
