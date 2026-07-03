import MegrumCore
import SwiftUI

enum GoodsSharePostRenderer {
    enum RenderError: Error {
        case imageUnavailable
    }

    #if os(iOS)
    @MainActor
    static func payload(for context: GoodsSharePostContext) async throws -> GoodsSharePostPayload {
        if let listingSnapshot = context.listingSnapshot {
            return try await listingPayload(for: listingSnapshot)
        }

        let tiles = await imageTiles(for: context.shareItems)
        let view = GoodsSharePostImageView(
            title: context.kind.imageTitle(displayName: context.displayName),
            tiles: tiles
        )
        let image = try renderedImage(view, size: GoodsSharePostImageView.canvasSize)
        return GoodsSharePostPayload(
            text: GoodsSharePostTextBuilder.text(
                for: context.shareItems,
                kind: context.kind,
                leadingTextOverride: context.postTextLeadingText
            ),
            images: [image]
        )
    }

    @MainActor
    private static func listingPayload(for snapshot: IndividualListingShareSnapshot) async throws -> GoodsSharePostPayload {
        let wantedRows = await renderRows(for: snapshot.wantedRows)
        let offeredRows = await renderRows(for: snapshot.offeredRows)
        let wantedView = IndividualListingSharePostImageView(
            title: "\(snapshot.displayName)さんの個別募集",
            sectionTitle: "求めるもの",
            rows: wantedRows,
            conditionLines: snapshot.exchangeConditionLines
        )
        let offeredView = IndividualListingSharePostImageView(
            title: "\(snapshot.displayName)さんの個別募集",
            sectionTitle: "譲るもの",
            rows: offeredRows,
            conditionLines: snapshot.exchangeConditionLines
        )
        return GoodsSharePostPayload(
            text: GoodsSharePostTextBuilder.text(for: snapshot),
            images: [
                try renderedImage(wantedView, size: IndividualListingSharePostImageView.canvasSize),
                try renderedImage(offeredView, size: IndividualListingSharePostImageView.canvasSize)
            ]
        )
    }

    @MainActor
    private static func renderedImage<Content: View>(_ content: Content, size: CGSize) throws -> UIImage {
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        guard let image = renderer.uiImage else {
            throw RenderError.imageUnavailable
        }
        return image
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

    private static func renderRows(for rows: [IndividualListingShareRow]) async -> [IndividualListingShareRenderRow] {
        var renderRows: [IndividualListingShareRenderRow] = []
        renderRows.reserveCapacity(rows.count)
        for row in rows {
            renderRows.append(
                IndividualListingShareRenderRow(
                    id: row.id,
                    title: row.title,
                    detail: row.detail,
                    badge: row.badge,
                    imageData: await imageData(for: row.imageURL)
                )
            )
        }
        return renderRows
    }
}
