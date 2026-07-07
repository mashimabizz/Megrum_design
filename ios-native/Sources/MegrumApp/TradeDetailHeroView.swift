import MegrumDesign
import SwiftUI

struct TradeDetailHero: View {
    var presentation: TradeDetailHeroPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ProfileVisualAvatar(
                    url: presentation.partnerAvatarURL,
                    fallback: presentation.partnerInitial,
                    size: 46
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text("@\(presentation.partnerHandle)")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        Circle()
                            .fill(MegrumTheme.lavender)
                            .frame(width: 6, height: 6)
                        Text(presentation.relationText)
                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    if let evaluationCount = presentation.partnerEvaluationCount {
                        // 相手の評価を候補シート・やりとり一覧と同じ黄色星表記で表示（iter1226.382 / FB6-4）。
                        MegrumRatingLabel(
                            averageStars: presentation.partnerAverageStars,
                            evaluationCount: evaluationCount,
                            starSize: 11,
                            fontSize: 11.5,
                            fontWeight: .heavy
                        )
                    }
                }

                Spacer(minLength: 8)

                Text(presentation.statusLabel)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(statusColor, in: Capsule())
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(MegrumTheme.lavender)
                    Text(presentation.agreementLabel)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                Text(presentation.guidanceText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(MegrumTheme.lavender.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.24), lineWidth: 1)
            }

            HStack(spacing: 8) {
                agreementChip(text: presentation.myAgreementText, done: presentation.myAgreementDone)
                agreementChip(text: presentation.partnerAgreementText, done: presentation.partnerAgreementDone)
            }

            HStack(spacing: 8) {
                metaChip(systemImage: "shippingbox", text: presentation.summaryText)
                metaChip(systemImage: "arrow.triangle.swap", text: presentation.exchangeMethodText)
            }
        }
        .padding(14)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.82), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.06), radius: 14, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(presentation.relationText)。\(presentation.statusLabel)。\(presentation.guidanceText)")
    }

    private var statusColor: Color {
        switch presentation.statusLabel {
        case "新着打診", "合意待ち":
            return Color(red: 0.84, green: 0.46, blue: 0.36)
        case "取引予定", "完了":
            return Color(red: 0.23, green: 0.49, blue: 0.58)
        case "見送り", "キャンセル", "期限切れ":
            return MegrumTheme.muted
        default:
            return MegrumTheme.lavender
        }
    }

    private func agreementChip(text: String, done: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: done ? "checkmark.circle.fill" : "clock")
                .font(.system(size: 12, weight: .bold))
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .font(.system(size: 12, weight: .heavy, design: .rounded))
        .foregroundStyle(done ? MegrumTheme.ok : MegrumTheme.muted)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(.white.opacity(0.72), in: Capsule())
    }

    private func metaChip(systemImage: String, text: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.white.opacity(0.62), in: Capsule())
    }
}
