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
                profileGridItems: profileGridItems(for: selectedProfileTab),
                onClose: closePage,
                onEdit: openCurrentProfileEditor,
                onOpenSchedule: openSchedule
            )
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .megrumEdgeBackSwipe(action: closePage)
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
        let parts = [
            summary.prefectureText,
            summary.genderText,
            summary.paymentMethodsText
        ].filter { !$0.isEmpty && $0 != "未設定" }
        guard !parts.isEmpty else {
            return "プロフィール情報を編集できます"
        }
        return parts.joined(separator: " / ")
    }

    private func profileGridItems(for tab: ProfileVisualTab) -> [ProfileVisualGridItem] {
        switch tab {
        case .goods:
            return appState.inventory.map { item in
                ProfileVisualGridItem(id: item.id, title: item.title, imageURL: item.imageURL)
            }
        case .listings:
            return listingGridItems()
        case .wish:
            return appState.wishes.map { item in
                ProfileVisualGridItem(id: item.id, title: item.title, imageURL: item.imageURL)
            }
        }
    }

    private func listingGridItems() -> [ProfileVisualGridItem] {
        let inventoryByID = Dictionary(uniqueKeysWithValues: appState.inventory.map { ($0.id, $0) })
        return appState.listings.compactMap { listing in
            guard let firstHave = listing.haves.first,
                  let item = inventoryByID[firstHave.itemID] else {
                return nil
            }
            return ProfileVisualGridItem(id: listing.id, title: item.title, imageURL: item.imageURL)
        }
    }

    private func closePage() {
        if let onClose {
            onClose()
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
                gender: normalized.gender,
                prefecture: normalized.prefecture.nilIfBlank,
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
