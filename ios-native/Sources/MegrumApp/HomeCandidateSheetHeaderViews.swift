import Foundation
import MegrumDesign
import SwiftUI

/// 候補シート再設計（notes/19）のヘッダー。左にユーザーアイコン、右に名前＋性別＋評価。
/// 評価はやりとり一覧と同じ「★ X.X（X件）」（黄色星）で表示。タップで相手プロフィールへ。iter1226.374/376/382。
struct HomeCandidateSheetHeader: View {
    var owner: HomeDiscoveryGoodsOwnerSummary?
    var fallbackName: String
    var onOpenOwnerProfile: (UUID) -> Void

    var body: some View {
        if let owner {
            Button {
                onOpenOwnerProfile(owner.id)
            } label: {
                content(owner: owner, name: owner.displayName, tappable: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(owner.displayName)のプロフィールを開く")
        } else {
            content(owner: nil, name: fallbackName, tappable: false)
        }
    }

    private func content(owner: HomeDiscoveryGoodsOwnerSummary?, name: String, tappable: Bool) -> some View {
        HStack(alignment: .center, spacing: 10) {
            ProfileVisualAvatar(
                url: owner?.avatarURL,
                fallback: owner?.initial ?? String(name.prefix(1)).uppercased(),
                size: 44
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .center, spacing: 8) {
                    Text(name)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .layoutPriority(1)

                    Spacer(minLength: 0)

                    if tappable {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12.5, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender.opacity(0.74))
                    }
                }

                if let owner {
                    HStack(spacing: 8) {
                        Text(owner.genderText)
                            .font(.system(size: 12.2, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        MegrumRatingLabel(
                            averageStars: owner.averageStars,
                            evaluationCount: owner.evaluationCount ?? 0
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 44) // ×ボタンと重ならない余白
        .contentShape(Rectangle())
    }
}
