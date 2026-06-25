import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeChatPartnerStrip: View {
    var presentation: TradeDetailHeroPresentation
    var onOpenProfile: () -> Void = {}

    var body: some View {
        Button(action: onOpenProfile) {
            HStack(spacing: 10) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                MegrumTheme.lavender.opacity(0.42),
                                MegrumTheme.sky.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                    .overlay {
                        Text(presentation.partnerInitial)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text("@\(presentation.partnerHandle)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(MegrumTheme.muted.opacity(0.42))
                            .frame(width: 4.5, height: 4.5)
                        Text(presentation.partnerMetaText)
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                }

                Spacer(minLength: 8)

                Text(presentation.agreementLabel)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(statusForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusBackground, in: Capsule())
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("@\(presentation.partnerHandle)。\(presentation.partnerMetaText)。\(presentation.agreementLabel)")
        .accessibilityHint("プロフィールを開きます")
    }

    private var statusForeground: Color {
        switch presentation.statusLabel {
        case "取引予定", "完了":
            return MegrumTheme.ok
        case "見送り", "キャンセル", "期限切れ":
            return MegrumTheme.muted
        default:
            return MegrumTheme.lavender
        }
    }

    private var statusBackground: Color {
        switch presentation.statusLabel {
        case "取引予定", "完了":
            return MegrumTheme.ok.opacity(0.15)
        case "見送り", "キャンセル", "期限切れ":
            return MegrumTheme.ink.opacity(0.06)
        default:
            return MegrumTheme.lavender.opacity(0.14)
        }
    }
}

struct TradeCollapsedSummaryCard: View {
    var label: String
    var summary: String
    var systemImage: String
    var action: (() -> Void)?

    var body: some View {
        if let action {
            Button(action: action) {
                cardContent
            }
            .buttonStyle(.plain)
            .accessibilityHint("詳細を開きます")
        } else {
            cardContent
        }
    }

    private var cardContent: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 22, height: 22)
                .background(MegrumTheme.lavender.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            Text(label)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)

            Text(summary)
                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Spacer(minLength: 4)

            Text("詳細")
                .font(.system(size: 10.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.14), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

struct TradeChatTimestampDivider: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10.5, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.78), in: Capsule())
            .frame(maxWidth: .infinity)
            .accessibilityLabel("メッセージ日時 \(text)")
    }
}
