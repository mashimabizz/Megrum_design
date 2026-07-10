import MegrumCore
import MegrumDesign
import SwiftUI

enum ProfileVisualTab: String, CaseIterable, Identifiable {
    case goods = "譲"
    case listings = "個別募集"
    case wish = "ほしいもの"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .goods:
            "bag"
        case .listings:
            "bookmark"
        case .wish:
            "heart"
        }
    }
}

struct ProfileVisualGridItem: Identifiable, Hashable {
    var id: UUID
    var title: String
    var imageURL: URL?
    var tags: [GoodsTag]
    var quantity: Int

    init(
        id: UUID,
        title: String,
        imageURL: URL?,
        tags: [GoodsTag] = [],
        quantity: Int = 1
    ) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.tags = tags
        self.quantity = max(1, quantity)
    }

    init(goods: GoodsItem) {
        self.init(
            id: goods.id,
            title: goods.title,
            imageURL: goods.imageURL,
            tags: goods.tags,
            quantity: goods.quantity
        )
    }

    init(wish: WishItem) {
        self.init(
            id: wish.id,
            title: wish.title,
            imageURL: wish.imageURL,
            tags: wish.tags,
            quantity: wish.quantity
        )
    }
}

/// 推しタグの階層。L1（グループ/作品）＝指名ありトーン、L2（メンバー/キャラ）＝wish一致トーン。
enum ProfileVisualTagKind: Hashable {
    case plain
    case group
    case member
}

struct ProfileVisualTagItem: Identifiable, Hashable {
    var title: String
    var colorKey: String
    var kind: ProfileVisualTagKind = .plain

    var id: String {
        "\(colorKey):\(title)"
    }
}

enum ProfileVisualTagSize {
    case regular
    case compact
}

struct ProfileVisualTabs: View {
    @Binding var selection: ProfileVisualTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProfileVisualTab.allCases) { tab in
                Button {
                    withAnimation(.smooth(duration: 0.2)) {
                        selection = tab
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.symbolName)
                            .font(.system(size: 19, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(selection == tab ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.62))
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(selection == tab ? MegrumTheme.lavender : .clear)
                            .frame(height: 3)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(.white.opacity(0.76))
    }
}

struct ProfileVisualAvatar: View {
    var url: URL?
    var fallback: String
    var size: CGFloat

    var body: some View {
        Circle()
            .fill(Color(white: 0.90))
            .frame(width: size, height: size)
            .overlay {
                if let url {
                    #if canImport(UIKit)
                    // iter1226.441：AsyncImage はビューを作り直すたびに人型プレースホルダを
                    // 一瞬挟む（グルームビューアのキューブ回転等でチラつく）。デコード済みの
                    // メモリキャッシュから同期表示できるローダーへ差し替え。
                    ProfileAvatarCachedImage(url: url, placeholderSize: size)
                        .clipShape(Circle())
                    #else
                    AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            defaultPersonPlaceholder
                        }
                    }
                    .clipShape(Circle())
                    #endif
                } else {
                    defaultPersonPlaceholder
                }
            }
    }

    /// アイコン未設定時の初期表示（グレーの人型シルエット）。
    private var defaultPersonPlaceholder: some View {
        ProfileAvatarPersonPlaceholder(size: size)
    }
}

/// アイコン未設定時の初期表示（グレーの人型シルエット）。
struct ProfileAvatarPersonPlaceholder: View {
    var size: CGFloat

    var body: some View {
        Image(systemName: "person.fill")
            .font(.system(size: size * 0.5, weight: .medium))
            .foregroundStyle(Color(white: 0.62))
            .offset(y: size * 0.06)
    }
}

#if canImport(UIKit)
/// アバターの瞬間表示用メモリキャッシュ（デコード済みUIImage）。iter1226.441。
@MainActor
final class ProfileAvatarImageStore {
    static let shared = ProfileAvatarImageStore()
    private let cache = NSCache<NSURL, UIImage>()

    init() {
        cache.countLimit = 300
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }

    /// 未キャッシュのURLを順に読み込み・デコードして格納する（ベストエフォート）。
    func prewarm(urls: [URL]) async {
        for url in urls where image(for: url) == nil {
            guard !Task.isCancelled else {
                return
            }
            guard let data = try? await GoodsRemoteImageDataLoader.loadData(from: url),
                  let loaded = UIImage(data: data)
            else {
                continue
            }
            let prepared = await loaded.byPreparingForDisplay() ?? loaded
            insert(prepared, for: url)
        }
    }
}

/// キャッシュ済みなら生成時から同期表示するアバター画像。
/// URLが差し替わっても読み込み完了まで直前の画像を出し続け、人型プレースホルダを挟まない。
private struct ProfileAvatarCachedImage: View {
    let url: URL
    let placeholderSize: CGFloat

    @State private var image: UIImage?

    init(url: URL, placeholderSize: CGFloat) {
        self.url = url
        self.placeholderSize = placeholderSize
        _image = State(initialValue: ProfileAvatarImageStore.shared.image(for: url))
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProfileAvatarPersonPlaceholder(size: placeholderSize)
            }
        }
        .task(id: url) {
            if let cached = ProfileAvatarImageStore.shared.image(for: url) {
                setImageWithoutAnimation(cached)
                return
            }
            guard let data = try? await GoodsRemoteImageDataLoader.loadData(from: url),
                  !Task.isCancelled,
                  let loaded = UIImage(data: data)
            else {
                return
            }
            let prepared = await loaded.byPreparingForDisplay() ?? loaded
            guard !Task.isCancelled else {
                return
            }
            ProfileAvatarImageStore.shared.insert(prepared, for: url)
            setImageWithoutAnimation(prepared)
        }
    }

    private func setImageWithoutAnimation(_ newImage: UIImage) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            image = newImage
        }
    }
}
#endif
