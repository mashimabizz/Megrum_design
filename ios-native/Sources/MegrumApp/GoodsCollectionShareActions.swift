import MegrumCore
import SwiftUI

extension GoodsCollectionScreen {
    func presentSharePrompt(_ createdItems: [GoodsItem]) {
        guard !createdItems.isEmpty else {
            return
        }
        sharePostErrorMessage = nil
        isPreparingSharePost = false
        sharePromptContext = GoodsSharePostContext(
            kind: entryKind == .wish ? .wish : .inventory,
            items: createdItems,
            displayName: viewerDisplayNameForSharePost()
        )
    }

    func presentListingSharePrompt(_ listing: IndividualListing) {
        guard let appState else {
            return
        }
        Task { @MainActor in
            if !appState.hasLoadedPaymentSettings {
                await appState.loadPaymentSettings(reportsFailure: false)
            }
            let displayName = viewerDisplayNameForSharePost()
            let snapshot = IndividualListingShareSnapshotFactory.make(
                listing: listing,
                displayName: displayName,
                inventory: appState.inventory,
                wishes: appState.wishes,
                groups: appState.oshiGroups,
                goodsTypes: appState.goodsTypes,
                paymentMethodsText: paymentMethodsTextForSharePost()
            )
            sharePostErrorMessage = nil
            isPreparingSharePost = false
            sharePromptContext = GoodsSharePostContext(
                kind: .individualListing,
                items: [],
                displayName: displayName,
                listingSnapshot: snapshot
            )
        }
    }

    func presentSelectedSharePrompt() {
        let targetItems = selectedItems.filter(isOwnedItem)
        presentSharePrompt(for: targetItems)
    }

    func presentSharePrompt(for targetItems: [GoodsItem]) {
        guard !targetItems.isEmpty else {
            return
        }
        sharePostErrorMessage = nil
        isPreparingSharePost = false
        sharePromptContext = GoodsSharePostContext(
            kind: entryKind == .wish ? .wish : .inventory,
            items: targetItems,
            displayName: viewerDisplayNameForSharePost(),
            promptTitle: "Xで投稿",
            promptDescription: selectedSharePromptDescription,
            shareButtonTitle: "Xで投稿する",
            postTextLeadingText: selectedShareLeadingText
        )
    }

    func dismissSharePrompt() {
        guard !isPreparingSharePost else {
            return
        }
        sharePromptContext = nil
        sharePostErrorMessage = nil
    }

    #if os(iOS)
    func startGoodsSharePost() {
        guard let sharePromptContext, !isPreparingSharePost else {
            return
        }
        isPreparingSharePost = true
        sharePostErrorMessage = nil

        Task { @MainActor in
            do {
                shareActivityPayload = try await GoodsSharePostRenderer.payload(for: sharePromptContext)
                isPreparingSharePost = false
            } catch {
                isPreparingSharePost = false
                sharePostErrorMessage = "ポスト画像を作成できませんでした。時間をおいてもう一度お試しください。"
            }
        }
    }
    #else
    func startGoodsSharePost() {
        sharePostErrorMessage = "この端末ではXへの共有を利用できません。"
    }
    #endif

    private func viewerDisplayNameForSharePost() -> String {
        [
            appState?.viewer?.displayName,
            appState?.viewer?.handle
        ]
        .compactMap(normalizedShareDisplayName)
        .first ?? "Megrumユーザー"
    }

    private func normalizedShareDisplayName(_ value: String?) -> String? {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfBlank
    }

    private func paymentMethodsTextForSharePost() -> String {
        GoodsSharePostTextBuilder.paymentMethodsText(
            methods: PaymentSettingsResolver.methods(
                settings: appState?.paymentSettings,
                viewer: appState?.viewer
            ),
            otherNote: PaymentSettingsResolver.otherNote(
                settings: appState?.paymentSettings,
                viewer: appState?.viewer
            )
        )
    }

    private var selectedSharePromptDescription: String {
        switch entryKind {
        case .inventory:
            "選択したマイグッズを画像と文面にしてXで周知できます。"
        case .wish:
            "選択したウィッシュを画像と文面にしてXで周知できます。"
        }
    }

    private var selectedShareLeadingText: String {
        switch entryKind {
        case .inventory:
            "Megrumで譲れるグッズをまとめました！"
        case .wish:
            "Megrumで欲しいものをまとめました！"
        }
    }
}
