import MegrumCore
import MegrumDesign
import SwiftUI

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
    /// FB(iter1226.394/395)：自分の有効かつ未読のグルームがある時、自分タイルの枠をグラデにする＆タップで閲覧できる。
    var hasOwnActiveGroom: Bool = false
    /// FB(iter1226.395)：この値変化で自分タイルの活性化アニメを発火（グルーム列が見えたタイミング）。
    var activationSignal: Int = 0
    var onAdd: () -> Void
    var onViewOwn: () -> Void = {}
    var onSelect: (GroomPost) -> Void

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
                    activationSignal: activationSignal,
                    onAdd: onAdd,
                    onViewOwn: onViewOwn
                )

                ForEach(displayGrooms) { groom in
                    Button {
                        onSelect(groom)
                    } label: {
                        GroomStoryTile(
                            groom: groom,
                            profile: publicProfilesByUserID[groom.authorID]?.profile,
                            isRead: viewedGroomIDs.contains(groom.id),
                            isLocked: lockedGroomIDs.contains(groom.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(groomStoryName(for: groom))のグルーム")
                    .id(groom.id)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func groomStoryName(for groom: GroomPost) -> String {
        if let profile = publicProfilesByUserID[groom.authorID]?.profile {
            return profile.handle.nilIfBlank ?? profile.displayName.nilIfBlank ?? "グルーム"
        }
        return "グルーム"
    }
}
