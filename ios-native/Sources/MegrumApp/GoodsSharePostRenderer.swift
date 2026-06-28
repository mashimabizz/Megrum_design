import MegrumCore
import SwiftUI

enum GoodsSharePostRenderer {
    enum RenderError: Error {
        case imageUnavailable
    }

    #if os(iOS)
    @MainActor
    static func payload(for context: GoodsSharePostContext) async throws -> GoodsSharePostPayload {
        let tiles = await imageTiles(for: context.shareItems)
        let view = GoodsSharePostImageView(
            title: "\(context.displayName)さんが登録した譲れるグッズ一覧",
            tiles: tiles
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(
            width: GoodsSharePostImageView.canvasSize.width,
            height: GoodsSharePostImageView.canvasSize.height
        )
        guard let image = renderer.uiImage else {
            throw RenderError.imageUnavailable
        }
        return GoodsSharePostPayload(
            text: GoodsSharePostTextBuilder.text(for: context.shareItems),
            image: image
        )
    }
    #endif

    private static func imageTiles(for items: [GoodsItem]) async -> [GoodsSharePostImageTile] {
        var tiles: [GoodsSharePostImageTile] = []
        tiles.reserveCapacity(items.count)
        for item in items {
            let data = await imageData(for: item.imageURL)
            tiles.append(GoodsSharePostImageTile(item: item, imageData: data))
        }
        return tiles
    }

    private static func imageData(for url: URL?) async -> Data? {
        guard let url else {
            return nil
        }
        return try? await GoodsRemoteImageDataLoader.loadData(from: url)
    }
}
