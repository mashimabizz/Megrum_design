import Foundation
import MegrumDesign
import SwiftUI

struct HomeUserSummary: View {
    var owner: HomeDiscoveryGoodsOwnerSummary
    var onOpenProfile: (UUID) -> Void

    var body: some View {
        Button {
            onOpenProfile(owner.id)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(owner.displayName)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                if !owner.genderAgeText.isEmpty {
                    Text(owner.genderAgeText)
                        .font(.system(size: 12.8, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                HStack(spacing: 6) {
                    Text(owner.evaluationText)
                        .foregroundStyle(MegrumTheme.lavender)
                    Text("｜")
                        .foregroundStyle(MegrumTheme.muted.opacity(0.6))
                    Text(owner.tradeText)
                        .foregroundStyle(MegrumTheme.muted)
                }
                .font(.system(size: 12.2, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.74)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(owner.displayName)のプロフィールを開く。\(owner.evaluationText)、\(owner.tradeText)")
    }
}

struct HomeExchangeMethodBlock: View {
    var summary: HomeDiscoveryOwnerExchangeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: "person.2")
                Text(summary.methodTitle)
            }
            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if let detailText = summary.detailText {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MegrumTheme.lavender)
                        .padding(.top, 1)
                    Text(detailText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct HomePaymentBox: View {
    var summaryText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: "yensign.circle")
                Text("支払い条件")
            }
            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)

            Text(summaryText)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(MegrumTheme.ok)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
