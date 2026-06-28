import MegrumCore
import SwiftUI

extension GoodsCollectionScreen {
    func presentSharePrompt(_ createdItems: [GoodsItem]) {
        guard entryKind == .inventory, !createdItems.isEmpty else {
            return
        }
        sharePostErrorMessage = nil
        isPreparingSharePost = false
        sharePromptContext = GoodsSharePostContext(
            items: createdItems,
            displayName: viewerDisplayNameForSharePost()
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
}
