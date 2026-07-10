import MegrumCore
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// FB(iter1226.403)：ホーム列の各タイルの画面上フレームを保持する箱。タップ時に
/// 「そのタイルの位置から拡大／その位置へ縮小」するアンカー計算に使う。
/// クラス（参照型）への書き込みは View を再評価させないので、スクロール中の更新もタダ同然。
private final class GroomRailTileFrameStore {
    var frames: [UUID: CGRect] = [:]
}

struct GroomFeedOrdering {
    static func sorted(
        _ grooms: [GroomPost],
        viewerID: UUID?,
        viewedIDs: Set<UUID>
    ) -> [GroomPost] {
        grooms
            .filter { $0.authorID != viewerID }
            .sorted { lhs, rhs in
                let lhsViewed = viewedIDs.contains(lhs.id)
                let rhsViewed = viewedIDs.contains(rhs.id)
                if lhsViewed != rhsViewed {
                    return !lhsViewed && rhsViewed
                }
                return lhs.createdAt > rhs.createdAt
            }
    }
}

struct GroomStrip: View {
    var grooms: [GroomPost]
    /// FB(iter1226.392)：いま開けない（圏外×無料の遭遇済み）グルームID。ロックアイコン表示に使う。
    var lockedGroomIDs: Set<UUID> = []
    var viewer: UserProfile?
    var publicProfilesByUserID: [UUID: PublicUserProfile]
    var viewedGroomIDs: Set<UUID>
    var isCreating: Bool
    /// FB(iter1226.394/395)：自分の有効かつ未読のグルームがある時、自分タイルの枠をグラデにする。
    var hasOwnActiveGroom: Bool = false
    /// FB(iter1226.402)：既読でも自分のグルームがあればタップで閲覧できる（枠グラデは未読のみ）。
    var hasAnyOwnGroom: Bool = false
    /// FB(iter1226.395)：この値変化で自分タイルの活性化アニメを発火（グルーム列が見えたタイミング）。
    var activationSignal: Int = 0
    var onAdd: () -> Void
    /// FB(iter1226.403)：タップしたタイルの画面上アンカー（拡大/縮小の基点）を添えて通知する。
    var onViewOwn: (UnitPoint) -> Void = { _ in }
    var onSelect: (GroomPost, UnitPoint) -> Void

    /// 自分タイルのフレーム記録用ID（グルームIDと衝突しない固定値）。
    private static let ownTileFrameID = UUID(uuidString: "00000000-0000-0000-0000-00000000FEED")!

    /// 参照型なので中身の更新で View は再評価されない（スクロール追従のフレーム記録専用）。
    @State private var tileFrameStore = GroomRailTileFrameStore()

    private var displayGrooms: [GroomPost] {
        GroomFeedOrdering.sorted(grooms, viewerID: viewer?.id, viewedIDs: viewedGroomIDs)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: GroomStoryMetrics.itemSpacing) {
                GroomMyStoryTile(
                    viewer: viewer,
                    isLoading: isCreating,
                    hasActiveGroom: hasOwnActiveGroom,
                    hasAnyOwnGroom: hasAnyOwnGroom,
                    activationSignal: activationSignal,
                    onAdd: onAdd,
                    onViewOwn: { onViewOwn(anchor(for: Self.ownTileFrameID)) }
                )
                .background(tileFrameReader(id: Self.ownTileFrameID))

                ForEach(displayGrooms) { groom in
                    Button {
                        onSelect(groom, anchor(for: groom.id))
                    } label: {
                        GroomStoryTile(
                            groom: groom,
                            profile: publicProfilesByUserID[groom.authorID]?.profile,
                            isRead: viewedGroomIDs.contains(groom.id),
                            isLocked: lockedGroomIDs.contains(groom.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .background(tileFrameReader(id: groom.id))
                    .accessibilityLabel("\(groomStoryName(for: groom))のグルーム")
                    .id(groom.id)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func tileFrameReader(id: UUID) -> some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            Color.clear
                .onAppear { tileFrameStore.frames[id] = frame }
                .onChange(of: frame) { _, new in tileFrameStore.frames[id] = new }
        }
    }

    /// タイルの画面上中心を UnitPoint（画面比率）へ変換。取れない時は上部中央の近似値。
    private func anchor(for id: UUID) -> UnitPoint {
        #if canImport(UIKit)
        guard
            let rect = tileFrameStore.frames[id],
            let bounds = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?.bounds,
            bounds.width > 0, bounds.height > 0
        else {
            return UnitPoint(x: 0.5, y: 0.12)
        }
        return UnitPoint(
            x: min(max(rect.midX / bounds.width, 0), 1),
            y: min(max(rect.midY / bounds.height, 0), 1)
        )
        #else
        return UnitPoint(x: 0.5, y: 0.12)
        #endif
    }

    private func groomStoryName(for groom: GroomPost) -> String {
        if let profile = publicProfilesByUserID[groom.authorID]?.profile {
            return profile.handle.nilIfBlank ?? profile.displayName.nilIfBlank ?? "グルーム"
        }
        return "グルーム"
    }
}
