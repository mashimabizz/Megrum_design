import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct OwnProfileScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onClose: (() -> Void)?
    @State private var localDraft: OwnProfileEditDraft?
    @State private var editDraft = OwnProfileEditDraft.empty
    @State private var isProfileEditorPresented = false
    @State private var isSchedulePresented = false
    @State private var showsProfileCompletion = false
    @State private var selectedProfileTab: ProfileVisualTab = .goods
    @Environment(\.dismiss) private var dismiss
    @Environment(\.megrumSlidePresentationDismiss) private var slidePresentationDismiss

    private var summary: OwnProfileSummary? {
        OwnProfileSummary(
            viewer: appState.viewer,
            inventoryCount: appState.inventory.count,
            wishCount: appState.wishes.count,
            listingCount: appState.listings.count,
            proposals: appState.proposals,
            localDraft: localDraft
        )
    }

    var body: some View {
        ScrollView {
            OwnProfileContent(
                summary: summary,
                selectedProfileTab: $selectedProfileTab,
                profileBio: summary.map(profileBio) ?? "",
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
                onOpenSchedule: openSchedule
            )
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .megrumInteractiveBackSwipe(action: closePage)
        .sheet(isPresented: $isProfileEditorPresented) {
            NavigationStack {
                OwnProfileEditForm(
                    draft: $editDraft,
                    isSaving: appState.isSavingOwnProfile,
                    onSave: saveProfileDraft
                )
            }
        }
        .sheet(isPresented: $isSchedulePresented) {
            NavigationStack {
                PersonalScheduleScreen(appState: appState) {
                    isSchedulePresented = false
                }
            }
        }
        .alert("プロフィールを更新しました", isPresented: $showsProfileCompletion) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("変更内容をこの画面に反映しました。")
        }
        .onChange(of: appState.viewer) {
            localDraft = nil
        }
        .task {
            await loadSupplementalProfileDataIfNeeded()
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
        isSchedulePresented = true
    }

    private func openProfileEditor(summary: OwnProfileSummary) {
        editDraft = OwnProfileEditDraft(summary: summary)
        isProfileEditorPresented = true
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
            localDraft = nil
            showsProfileCompletion = true
        }
        return saved
    }
}
