import SwiftUI

/// メッセージに保存された（失効しうる）グルーム署名URLを、表示時に
/// 有効な署名URLへ解決するリゾルバ。既定はそのまま返す（プレビュー等）。
struct GroomContextImageURLResolverKey: EnvironmentKey {
    static let defaultValue: @Sendable (URL) async -> URL? = { $0 }
}

extension EnvironmentValues {
    var groomContextImageURLResolver: @Sendable (URL) async -> URL? {
        get { self[GroomContextImageURLResolverKey.self] }
        set { self[GroomContextImageURLResolverKey.self] = newValue }
    }
}

/// 失効しうる署名URLを解決してから表示する画像コンテナ。
/// 解決完了までは何も描画せず、失敗時のみ failure ビューを出す。
struct GroomContextResolvedImage<Content: View>: View {
    var staleURL: URL
    @ViewBuilder var content: (AsyncImagePhase) -> Content

    @Environment(\.groomContextImageURLResolver) private var resolver
    @State private var resolvedURL: URL?
    @State private var didFailToResolve = false

    var body: some View {
        Group {
            if let resolvedURL {
                AsyncImage(url: resolvedURL, content: content)
            } else if didFailToResolve {
                content(.failure(URLError(.badURL)))
            } else {
                content(.empty)
            }
        }
        .task(id: staleURL) {
            didFailToResolve = false
            if let fresh = await resolver(staleURL) {
                resolvedURL = fresh
            } else {
                didFailToResolve = true
            }
        }
    }
}
