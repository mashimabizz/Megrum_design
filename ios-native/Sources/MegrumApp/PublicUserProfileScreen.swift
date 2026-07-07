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
                groomLikeCount: appState.groomLikeCountByUserID[userID] ?? 0,
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
            // VisualQA: 起動時に指定タブ（listings / wish）を開いた状態にする。
            switch ProcessInfo.processInfo.environment["MEGRUM_VISUAL_QA_PROFILE_TAB"] {
            case "goods":
                presentationState.selectedVisualTab = .goods
            case "listings":
                presentationState.selectedVisualTab = .listings
            case "wish":
                presentationState.selectedVisualTab = .wish
            default:
                break
            }
            await appState.loadPublicUserProfile(userID: userID)
            await appState.loadPublicExchangeContent(userID: userID)
            await appState.loadPublicExchangeSettings(userID: userID)
            await appState.loadPartnerActivityWindows(userID: userID)
            await appState.loadUserEvaluations(userID: userID)
            await appState.loadGroomLikeCount(userID: userID)
            if appState.oshiGroups.isEmpty {
                await appState.loadOshiGroups()
            }
            if appState.goodsTypes.isEmpty {
                await appState.loadGoodsTypes()
            }
            // VisualQA（profile-proposal）：プロフィール経由の打診画面をタップ操作なしで検証する。
            if VisualQAPreviewMode.initialScreen(environment: ProcessInfo.processInfo.environment) == .profileProposal,
               presentationState.proposalTargetItem == nil {
                startPrimaryProposal()
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
            // 公開設定は廃止（全員一律閲覧）。打診フローの「＞」と同じ交換条件カレンダーを出す。
            HomePartnerExchangeCalendarSheet(context: partnerExchangeCalendarContext)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        // プロフィールは呼び出し元の NavigationStack 内に置かれるため、スライドオーバーレイを
        // ネストするとセーフエリアが失われる（ヘッダーがステータスバーに被る）。
        // iOS標準の fullScreenCover で正しいセーフエリアのまま全画面表示する。
        .megrumFullScreenItemPresentation(item: $presentationState.proposalTargetItem) { item in
            NavigationStack {
                ProposalCreateFlow(appState: appState, targetItem: item)
            }
        }
        .megrumFullScreenItemPresentation(item: $presentationState.listingProposalTarget) { target in
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
