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
    @State var presentationState = PublicUserProfilePresentationState()

    var body: some View {
        let profile = displayedPublicProfile
        ScrollView {
            PublicUserProfileContent(
                publicProfile: profile,
                selectedVisualTab: $presentationState.selectedVisualTab,
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
                    presentationState.openExchangeConditions()
                },
                onOpenEvaluations: {
                    presentationState.isEvaluationListPresented = true
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
                            presentationState.reportTarget = moderationTarget
                        } label: {
                            Label("通報", systemImage: "exclamationmark.bubble")
                        }

                        Button(role: .destructive) {
                            presentationState.blockTarget = moderationTarget
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
        .sheet(isPresented: $presentationState.isEvaluationListPresented) {
            UserEvaluationListSheet(
                evaluations: evaluations,
                isLoading: appState.loadingEvaluationsUserID == userID
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $presentationState.isExchangeConditionsPresented) {
            NavigationStack {
                PublicExchangeConditionsScreen(
                    displayName: displayedPublicProfile?.profile.displayName ?? "相手",
                    settings: appState.publicExchangeSettingsByUserID[userID],
                    listings: listings,
                    profile: displayedPublicProfile?.profile
                )
            }
        }
        .megrumSlideItemPresentation(item: $presentationState.proposalTargetItem) { item, _ in
            NavigationStack {
                ProposalCreateFlow(appState: appState, targetItem: item)
            }
        }
        .megrumSlideItemPresentation(item: $presentationState.listingProposalTarget) { target, _ in
            NavigationStack {
                ProposalCreateFlow(
                    appState: appState,
                    targetItem: target.targetItem,
                    listingID: target.listing.id,
                    receiverGoodsIDs: target.receiverGoodsIDs
                )
            }
        }
        .sheet(isPresented: $presentationState.isSchedulePresented) {
            NavigationStack {
                ProfileScheduleScreen(
                    appState: appState,
                    userID: userID,
                    displayName: displayedPublicProfile?.profile.displayName ?? "相手"
                ) {
                    presentationState.closeSchedule()
                }
            }
        }
        .sheet(item: $presentationState.reportTarget) { target in
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
                get: { presentationState.blockTarget != nil },
                set: { isPresented in
                    presentationState.updateBlockConfirmationPresentation(isPresented)
                }
            ),
            titleVisibility: .visible
        ) {
            if let blockTarget = presentationState.blockTarget {
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
