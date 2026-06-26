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

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(presentation.partnerDisplayName)
                            .font(.system(size: 14.2, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        Text("@\(presentation.partnerHandle)")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    Text(presentation.partnerMetaText)
                        .font(.system(size: 10.8, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 8)
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(presentation.partnerDisplayName)。@\(presentation.partnerHandle)。\(presentation.partnerMetaText)")
        .accessibilityHint("プロフィールを開きます")
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
                TradeCollapsedSummaryCardContent(
                    label: label,
                    summary: summary,
                    systemImage: systemImage
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("詳細を開きます")
        } else {
            TradeCollapsedSummaryCardContent(
                label: label,
                summary: summary,
                systemImage: systemImage
            )
        }
    }
}

private struct TradeCollapsedSummaryCardContent: View {
    var label: String
    var summary: String
    var systemImage: String

    var body: some View {
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
