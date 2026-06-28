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
    @Environment(\.megrumSlidePresentationDismiss) var slidePresentationDismiss
    @State var selectedVisualTab: ProfileVisualTab = .goods
    @State var proposalTargetItem: GoodsItem?
    @State var listingProposalTarget: ListingProposalTarget?
    @State var isSchedulePresented = false
    @State var isExchangeConditionsPresented = false
    @State var reportTarget: PublicProfileModerationTarget?
    @State var blockTarget: PublicProfileModerationTarget?

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
                goodsItems: publicProfileGoodsGridItems,
                wishItems: publicProfileWishGridItems,
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
                onOpenExchangeConditions: {
                    isExchangeConditionsPresented = true
                },
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
                        closeProfile()
                    }
                }
            }
            if let moderationTarget {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            reportTarget = moderationTarget
                        } label: {
                            Label("通報", systemImage: "exclamationmark.bubble")
                        }

                        Button(role: .destructive) {
                            blockTarget = moderationTarget
                        } label: {
                            Label("ブロック", systemImage: "hand.raised")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 36, height: 36)
                            .contentShape(Circle())
                    }
                    .accessibilityLabel("プロフィールメニュー")
                }
            }
        }
        .megrumInteractiveBackSwipe {
            closeProfile()
        }
        .task(id: userID) {
            await appState.loadPublicUserProfile(userID: userID)
            await appState.loadPublicExchangeContent(userID: userID)
            await appState.loadPublicExchangeSettings(userID: userID)
            await appState.loadUserEvaluations(userID: userID)
            if appState.oshiGroups.isEmpty {
                await appState.loadOshiGroups()
            }
            if appState.goodsTypes.isEmpty {
                await appState.loadGoodsTypes()
            }
        }
        .sheet(isPresented: $isExchangeConditionsPresented) {
            NavigationStack {
                PublicExchangeConditionsScreen(
                    displayName: displayedPublicProfile?.profile.displayName ?? "相手",
                    settings: appState.publicExchangeSettingsByUserID[userID],
                    listings: listings,
                    profile: displayedPublicProfile?.profile
                )
            }
        }
        .megrumSlideItemPresentation(item: $proposalTargetItem) { item, _ in
            NavigationStack {
                ProposalCreateFlow(appState: appState, targetItem: item)
            }
        }
        .megrumSlideItemPresentation(item: $listingProposalTarget) { target, _ in
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
        .sheet(item: $reportTarget) { target in
            NavigationStack {
                UserReportSheet(
                    target: target,
                    isSubmitting: appState.reportingUserID == target.userID
                ) { reason, note in
                    Task {
                        _ = await appState.reportUser(
                            targetUserID: target.userID,
                            reason: reason,
                            note: note
                        )
                    }
                }
            }
        }
        .confirmationDialog(
            "このユーザーをブロックしますか？",
            isPresented: Binding(
                get: { blockTarget != nil },
                set: { isPresented in
                    if !isPresented {
                        blockTarget = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let blockTarget {
                Button("ブロック", role: .destructive) {
                    Task {
                        if await appState.blockUser(blockTarget.userID) {
                            closeProfile()
                        }
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("このユーザーのグッズは検索結果とマッチ候補に表示されなくなります。")
        }
    }

    private func closeProfile() {
        if let slidePresentationDismiss {
            slidePresentationDismiss()
        } else {
            dismiss()
        }
    }
}
