import MegrumCore
import MegrumDesign
import SwiftUI

struct PublicExchangeStandardSettingsCard: View {
    var settings: HomeDefaultExchangeSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 38, height: 38)
                    .background(MegrumTheme.lavender.opacity(0.10), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("標準交換条件")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(settings.summaryText)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
            }

            PublicExchangeConditionInfoRow(
                title: "交換方法",
                detail: settings.preference.displayName,
                systemImage: "arrow.triangle.swap"
            )

            if settings.preference.acceptsLocal {
                PublicExchangeConditionInfoRow(
                    title: "現地",
                    detail: localDetailText,
                    systemImage: "mappin.and.ellipse"
                )
            }

            if settings.preference.acceptsMail {
                PublicExchangeConditionInfoRow(
                    title: "郵送",
                    detail: "送料 \(settings.mailShippingFee.title) / 発送 \(settings.mailShippingDays.title)",
                    systemImage: "envelope"
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }

    private var localDetailText: String {
        let dateText = settings.localDateKeys
            .prefix(3)
            .map { key in
                if let detail = settings.localDateDetails[key]?.memo.nilIfBlank {
                    return "\(HomeExchangeDateKey.compactDisplayText(for: key)) \(detail)"
                }
                return HomeExchangeDateKey.compactDisplayText(for: key)
            }
            .joined(separator: "、")
            .nilIfBlank
        let remainingCount = max(0, settings.localDateKeys.count - 3)
        let remainingText = remainingCount > 0 ? "ほか\(remainingCount)日程" : nil
        return [
            settings.localPrefecture.nilIfBlank ?? "場所未設定",
            [dateText, remainingText].compactMap(\.self).joined(separator: " / ").nilIfBlank
        ]
        .compactMap(\.self)
        .joined(separator: " / ")
    }
}

struct PublicExchangePaymentCard: View {
    var summaryText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "yensign.circle.fill")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ok)
                    .frame(width: 38, height: 38)
                    .background(MegrumTheme.ok.opacity(0.10), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("支払い条件")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(summaryText)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ok)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }
}

private struct PublicExchangeConditionInfoRow: View {
    var title: String
    var detail: String
    var systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 24, height: 24)
                .background(MegrumTheme.lavender.opacity(0.09), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                Text(detail)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.76)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(MegrumTheme.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
