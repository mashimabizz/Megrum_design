import Foundation
import MegrumDesign
import SwiftUI

/// 候補シート再設計（notes/19）のヘッダー。見出し文・大画像・需要チップを撤去し、
/// 名前＋評価（プロフメタ）のみに簡素化。タップで相手プロフィールへ。iter1226.374/376。
struct HomeCandidateSheetHeader: View {
    var owner: HomeDiscoveryGoodsOwnerSummary?
    var fallbackName: String
    var onOpenOwnerProfile: (UUID) -> Void

    var body: some View {
        if let owner {
            Button {
                onOpenOwnerProfile(owner.id)
            } label: {
                content(name: owner.displayName, meta: owner.profileMetaText, tappable: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(owner.displayName)のプロフィールを開く。\(owner.profileMetaText)")
        } else {
            content(name: fallbackName, meta: nil, tappable: false)
        }
    }

    private func content(name: String, meta: String?, tappable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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

            if let meta {
                Text(meta)
                    .font(.system(size: 12.2, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 44) // ×ボタンと重ならない余白
        .contentShape(Rectangle())
    }
}
