import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct OwnProfileScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onClose: (() -> Void)?
    @State private var presentationState = OwnProfilePresentationState()
    @State private var isEvaluationListPresented = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.megrumSlidePresentationDismiss) private var slidePresentationDismiss

    private var summary: OwnProfileSummary? {
        OwnProfileSummary(
            viewer: appState.viewer,
            inventoryCount: appState.inventory.count,
            wishCount: appState.wishes.count,
            listingCount: appState.listings.count,
            proposals: appState.proposals,
            localDraft: presentationState.localDraft
        )
    }

    var body: some View {
        ScrollView {
            OwnProfileContent(
                summary: summary,
                selectedProfileTab: $presentationState.selectedProfileTab,
                profileBio: summary.map(profileBio) ?? "",
                groomLikeCount: appState.viewer.map { appState.groomLikeCountByUserID[$0.id] ?? 0 } ?? 0,
                profileTagItems: profileTagItems,
                goodsItems: ownGoodsGridItems,
                wishItems: ownWishGridItems,
                listings: appState.listings,
                listingGoodsByID: ownListingGoodsByID,
                listingWishByID: ownListingWishByID,
                groups: appState.oshiGroups,
                characters: appState.oshiCharacters,
                goodsTypes: appState.goodsTypes,
                onClose: closePage,
                onEdit: openCurrentProfileEditor,
                onOpenSchedule: openSchedule,
                onOpenEvaluations: openEvaluationList
            )
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .megrumInteractiveBackSwipe(action: closePage)
        .sheet(isPresented: $presentationState.isProfileEditorPresented) {
            NavigationStack {
                OwnProfileEditForm(
                    draft: $presentationState.editDraft,
                    isSaving: appState.isSavingOwnProfile,
                    onSave: saveProfileDraft
                )
            }
        }
        .sheet(isPresented: $isEvaluationListPresented) {
            UserEvaluationListSheet(
                evaluations: appState.viewer.map { appState.userEvaluationsByUserID[$0.id] ?? [] } ?? [],
                isLoading: appState.loadingEvaluationsUserID != nil
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $presentationState.isSchedulePresented) {
            NavigationStack {
                PersonalScheduleScreen(appState: appState) {
                    presentationState.closeSchedule()
                }
            }
        }
        .alert("プロフィールを更新しました", isPresented: $presentationState.showsProfileCompletion) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("変更内容をこの画面に反映しました。")
        }
        .onChange(of: appState.viewer) {
            presentationState.clearLocalDraft()
        }
        .task {
            await loadSupplementalProfileDataIfNeeded()
            if let viewerID = appState.viewer?.id {
                await appState.loadGroomLikeCount(userID: viewerID)
            }
        }
    }

    private func openEvaluationList() {
        isEvaluationListPresented = true
        if let viewerID = appState.viewer?.id {
            Task {
                await appState.loadUserEvaluations(userID: viewerID)
            }
        }
    }

    private var profileTagItems: [ProfileVisualTagItem] {
        OwnProfileOshiTagPresentation.tagItems(from: appState.userOshiSelections)
    }

    private func profileBio(_ summary: OwnProfileSummary) -> String {
        summary.bio ?? ""
    }

    private var ownGoodsGridItems: [ProfileVisualGridItem] {
        appState.inventory.map(ProfileVisualGridItem.init(goods:))
    }

    private var ownWishGridItems: [ProfileVisualGridItem] {
        appState.wishes.map(ProfileVisualGridItem.init(wish:))
    }

    private var ownListingGoodsByID: [UUID: GoodsItem] {
        Dictionary(uniqueKeysWithValues: appState.inventory.map { ($0.id, $0) })
    }

    private var ownListingWishByID: [UUID: WishItem] {
        Dictionary(uniqueKeysWithValues: appState.wishes.map { ($0.id, $0) })
    }

    private func closePage() {
        if let onClose {
            onClose()
        } else if let slidePresentationDismiss {
            slidePresentationDismiss()
        } else {
            dismiss()
        }
    }

    private func openCurrentProfileEditor() {
        guard let summary else {
            return
        }
        openProfileEditor(summary: summary)
    }

    private func openSchedule() {
        presentationState.openSchedule()
    }

    private func openProfileEditor(summary: OwnProfileSummary) {
        presentationState.openProfileEditor(summary: summary)
    }

    private func loadSupplementalProfileDataIfNeeded() async {
        if appState.userOshiSelections.isEmpty {
            await appState.loadUserOshiSelections()
        }
        if appState.mailingAddress == nil {
            await appState.loadMailingAddress()
        }
    }

    private func saveProfileDraft(_ savedDraft: OwnProfileEditDraft) async -> Bool {
        let normalized = savedDraft.normalized
        let saved = await appState.updateOwnProfile(
            OwnProfileUpdateInput(
                handle: normalized.handle,
                displayName: normalized.displayName,
                bio: normalized.bio.nilIfBlank,
                gender: normalized.gender,
                prefecture: normalized.prefecture.nilIfBlank,
                birthDate: normalized.birthDate,
                paymentMethods: normalized.paymentMethods,
                avatarURL: normalized.visibleAvatarURL,
                avatarUpload: normalized.avatarUpload,
                clearsAvatar: normalized.clearsAvatar
            )
        )

        if saved {
            presentationState.markProfileSaved()
        }
        return saved
    }
}
