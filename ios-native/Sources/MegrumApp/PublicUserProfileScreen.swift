import MegrumCore
import MegrumDesign
import SwiftUI

struct PublicUserProfileScreen: View {
    @ObservedObject var appState: MegrumAppState
    var userID: UUID
    var presentationContext: PublicProfilePresentationContext = .standalone
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    var adPlacement: AdPlacement?

    @Environment(\.dismiss) var dismiss
    @State var selectedVisualTab: ProfileVisualTab = .goods
    @State var proposalTargetItem: GoodsItem?
    @State var listingProposalTarget: ListingProposalTarget?
    @State var isSchedulePresented = false

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
}
