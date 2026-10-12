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

/// iter1226.448：ホームのグルームレール標準zoom遷移で使う source ID。
/// タイル側の `matchedTransitionSource(id:)` と、提示側の `navigationTransition(.zoom(sourceID:))`
/// で同じ値を使う必要があるため、共有の定数として置く。グループタイルの source は
/// 代表グルームの `id`、自分タイルは `ownTile` 固定値。
enum GroomStoryRailSource {
    static let ownTile = UUID(uuidString: "00000000-0000-0000-0000-00000000FEED")!
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

/// iter1226.422：グルーム列の初回ロード中プレースホルダ（淡い円＋名前バーの脈動）。
struct GroomStorySkeletonTile: View {
    @State private var pulses = false

    var body: some View {
        VStack(spacing: GroomStoryMetrics.labelSpacing) {
            ZStack {
                Circle()
                    .strokeBorder(GroomStoryMetrics.seenRing, lineWidth: GroomStoryMetrics.ringLineWidth)
                    .frame(width: GroomStoryMetrics.ringDiameter, height: GroomStoryMetrics.ringDiameter)
                Circle()
                    .fill(MegrumTheme.ink.opacity(0.06))
                    .frame(width: GroomStoryMetrics.avatarDiameter, height: GroomStoryMetrics.avatarDiameter)
            }
            Capsule()
                .fill(MegrumTheme.ink.opacity(0.08))
                .frame(width: 40, height: 9)
        }
        .opacity(pulses ? 0.55 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulses = true
            }
        }
        .accessibilityHidden(true)
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
    /// iter1226.422：初回ロード中（まだ他ユーザーのタイルが無い間）はスケルトンを出す。
    var isLoadingInitial: Bool = false
    /// FB(iter1226.394/395)：自分の有効かつ未読のグルームがある時、自分タイルの枠をグラデにする。
    var hasOwnActiveGroom: Bool = false
    /// FB(iter1226.402)：既読でも自分のグルームがあればタップで閲覧できる（枠グラデは未読のみ）。
    var hasAnyOwnGroom: Bool = false
    /// FB(iter1226.395)：この値変化で自分タイルの活性化アニメを発火（グルーム列が見えたタイミング）。
    var activationSignal: Int = 0
    var onAdd: () -> Void
    /// FB(iter1226.403)：タップしたタイルの画面上アンカー（拡大/縮小の基点）を添えて通知する。
    var onViewOwn: (UnitPoint) -> Void = { _ in }
    /// iter1226.420：同一ユーザーのグルームは1タイルにまとめ、タップでそのユーザーの全グルームを渡す。
    var onSelectGroup: ([GroomPost], UnitPoint) -> Void
    /// iter1226.448：標準zoom遷移の source namespace（iOS18+・ホームレールのみ）。
    var groomZoomNamespace: Namespace.ID? = nil

    /// 自分タイルのフレーム記録用ID（グルームIDと衝突しない固定値）。
    private static let ownTileFrameID = GroomStoryRailSource.ownTile

    /// 参照型なので中身の更新で View は再評価されない（スクロール追従のフレーム記録専用）。
    @State private var tileFrameStore = GroomRailTileFrameStore()

    private var displayGrooms: [GroomPost] {
        GroomFeedOrdering.sorted(grooms, viewerID: viewer?.id, viewedIDs: viewedGroomIDs)
    }

    /// iter1226.420：ユーザー単位のまとまり（未読優先の並びを保ったまま、同一投稿者を1つに束ねる）。
    private var displayGroups: [[GroomPost]] {
        var order: [UUID] = []
        var byAuthor: [UUID: [GroomPost]] = [:]
        for groom in displayGrooms {
            if byAuthor[groom.authorID] == nil {
                order.append(groom.authorID)
            }
            byAuthor[groom.authorID, default: []].append(groom)
        }
        return order.compactMap { byAuthor[$0] }
    }

    private func isGroupRead(_ group: [GroomPost]) -> Bool {
        group.allSatisfy { viewedGroomIDs.contains($0.id) }
    }

    private func isGroupLocked(_ group: [GroomPost]) -> Bool {
        group.allSatisfy { lockedGroomIDs.contains($0.id) }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: GroomStoryMetrics.itemSpacing) {
                zoomSource(GroomStoryRailSource.ownTile) {
                    GroomMyStoryTile(
                        viewer: viewer,
                        isLoading: isCreating,
                        hasActiveGroom: hasOwnActiveGroom,
                        hasAnyOwnGroom: hasAnyOwnGroom,
                        activationSignal: activationSignal,
                        onAdd: onAdd,
                        onViewOwn: { onViewOwn(anchor(for: Self.ownTileFrameID)) }
                    )
                }
                .background(tileFrameReader(id: Self.ownTileFrameID))

                if isLoadingInitial, displayGroups.isEmpty {
                    ForEach(0..<4, id: \.self) { index in
                        GroomStorySkeletonTile()
                            .opacity(1 - Double(index) * 0.16)
                    }
                }

                ForEach(displayGroups, id: \.first!.id) { group in
                    let representative = group.first!
                    zoomSource(representative.id) {
                        Button {
                            onSelectGroup(group, anchor(for: representative.id))
                        } label: {
                            GroomStoryTile(
                                groom: representative,
                                profile: publicProfilesByUserID[representative.authorID]?.profile,
                                isRead: isGroupRead(group),
                                isLocked: isGroupLocked(group),
                                isProfileLoading: isLoadingInitial
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .background(tileFrameReader(id: representative.id))
                    .accessibilityLabel("\(groomStoryName(for: representative))のグルーム\(group.count)件")
                    .id(representative.id)
                }
            }
            .padding(.vertical, 8)
            // フルブリード：親の水平パディングを打ち消した分、中身側で先頭/末尾の余白を確保（iter1226.420）。
            .padding(.horizontal, 20)
        }
    }

    /// iter1226.448：iOS18+ でホームレールに namespace が渡っている時だけ、タイルを
    /// zoom 遷移の source としてマークする。iOS17 や namespace 未指定時は素通し。
    @ViewBuilder
    private func zoomSource(_ id: UUID, @ViewBuilder content: () -> some View) -> some View {
        #if os(iOS)
        if #available(iOS 18.0, *), let groomZoomNamespace {
            content().matchedTransitionSource(id: id, in: groomZoomNamespace)
        } else {
            content()
        }
        #else
        content()
        #endif
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
