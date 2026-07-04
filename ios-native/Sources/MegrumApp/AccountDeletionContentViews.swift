import MegrumDesign
import SwiftUI

struct AccountDeletionWarningContent: View {
    var ongoingTradeCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AccountDeletionWarningRow(
                systemImage: "person.crop.circle.badge.xmark",
                title: "アカウントが使えなくなります",
                detail: "表示名、ユーザーID、プロフィール、推し設定などをMegrum上で使えなくなります。"
            )
            AccountDeletionWarningRow(
                systemImage: "shippingbox.circle",
                title: "グッズ・ほしいものの情報を確認できなくなります",
                detail: "登録したグッズ、ほしいもの、交換条件、通知設定などは通常画面から参照できなくなります。"
            )
            AccountDeletionWarningRow(
                systemImage: "checkmark.shield",
                title: "安全確認に必要な記録は残る場合があります",
                detail: "取引チャット、証跡、評価、通報対応に必要な記録は、規約対応と安全確認のため一定期間保持される場合があります。"
            )
            AccountDeletionWarningRow(
                systemImage: "arrow.left.arrow.right.circle",
                title: "進行中の取引がある場合は退会できません",
                detail: "取引完了またはキャンセル後に、もう一度退会手続きをしてください。"
            )

            if ongoingTradeCount > 0 {
                AccountDeletionBlockedBanner(ongoingTradeCount: ongoingTradeCount)
            }
        }
        .accountDeletionCardStyle()
    }
}

struct AccountDeletionReasonRow: View {
    var reason: AccountDeletionReason
    var isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.55))

                Text(reason.displayName)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(reason.displayName)、\(isSelected ? "選択中" : "未選択")")
    }
}

struct AccountDeletionAlertLabel: View {
    var message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct AccountDeletionWarningRow: View {
    var systemImage: String
    var title: String
    var detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(detail)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct AccountDeletionBlockedBanner: View {
    var ongoingTradeCount: Int

    var body: some View {
        Label {
            Text("現在進行中の取引が\(ongoingTradeCount)件あるため退会できません。")
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.system(size: 14, weight: .black, design: .rounded))
        .foregroundStyle(Color(red: 0.86, green: 0.29, blue: 0.38))
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 1.0, green: 0.94, blue: 0.95), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

extension View {
    func accountDeletionCardStyle() -> some View {
        padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: MegrumTheme.lavender.opacity(0.07), radius: 18, y: 10)
    }
}
