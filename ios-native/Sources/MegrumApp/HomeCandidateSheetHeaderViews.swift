import Foundation
import MegrumDesign
import SwiftUI

/// 候補シート再設計（notes/19）のヘッダー。見出し文・大画像を撤去し、
/// 名前＋評価（プロフメタ）＋需要チップのみに簡素化。タップで相手プロフィールへ。iter1226.374。
struct HomeCandidateSheetHeader: View {
    var owner: HomeDiscoveryGoodsOwnerSummary?
    var fallbackName: String
    var demand: HomeCandidateDemandLine
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

                HomeCandidateDemandChip(demand: demand)

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

/// 需要チップ（超求！/超求めてる？/求！/求めてる？/定価/探し中/相談）。
/// 装飾色は意味のあるものだけに絞る方針（notes/19）：超求＝ピンク、求＝ラベンダー、定価＝スカイ→ラベンダー。
struct HomeCandidateDemandChip: View {
    var demand: HomeCandidateDemandLine

    var body: some View {
        let style = Self.style(for: demand)
        HStack(spacing: 3) {
            Text(style.label)
                .font(.system(size: 12, weight: .black, design: .rounded))
        }
        .foregroundStyle(style.foreground)
        .padding(.horizontal, 9)
        .frame(height: 24)
        .background(style.background, in: Capsule())
        .overlay {
            if let border = style.border {
                Capsule().strokeBorder(border, lineWidth: 1)
            }
        }
        .fixedSize()
        .accessibilityLabel(style.label)
    }

    private struct ChipStyle {
        var label: String
        var foreground: Color
        var background: Color
        var border: Color?
    }

    // 超求！＝ピンク濃、超求めてる？＝ピンク淡、求＝ラベンダー系（notes/19 の色指定）。
    private static let hotInk = Color(red: 0.294, green: 0.082, blue: 0.157) // #4B1528
    private static let hotBg = Color(red: 0.957, green: 0.753, blue: 0.820) // #F4C0D1
    private static let hotTentativeInk = Color(red: 0.447, green: 0.141, blue: 0.243) // #72243E
    private static let hotTentativeBg = Color(red: 0.984, green: 0.918, blue: 0.941) // #FBEAF0
    private static let demandInk = Color(red: 0.38, green: 0.30, blue: 0.62)

    private static func style(for demand: HomeCandidateDemandLine) -> ChipStyle {
        switch demand {
        case .hotDemand:
            return ChipStyle(label: "超求！", foreground: hotInk, background: hotBg, border: nil)
        case .hotDemandTentative:
            return ChipStyle(label: "超求めてる？", foreground: hotTentativeInk, background: hotTentativeBg, border: hotBg.opacity(0.6))
        case .demand:
            return ChipStyle(label: "求！", foreground: demandInk, background: MegrumTheme.lavender.opacity(0.18), border: nil)
        case .demandTentative:
            return ChipStyle(label: "求めてる？", foreground: demandInk.opacity(0.85), background: MegrumTheme.lavender.opacity(0.10), border: MegrumTheme.lavender.opacity(0.22))
        case .cash:
            return ChipStyle(label: "定価", foreground: demandInk, background: MegrumTheme.sky.opacity(0.22), border: nil)
        case .lookingFor:
            return ChipStyle(label: "探し中", foreground: MegrumTheme.muted, background: MegrumTheme.ink.opacity(0.06), border: nil)
        case .discuss:
            return ChipStyle(label: "相談", foreground: MegrumTheme.muted, background: MegrumTheme.ink.opacity(0.06), border: nil)
        }
    }
}
