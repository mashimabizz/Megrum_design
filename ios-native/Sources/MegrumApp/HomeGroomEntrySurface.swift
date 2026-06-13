import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeGroomEntrySummary: Equatable {
    var groomCount: Int
    var badgeText: String
    var title: String
    var detail: String

    init(groomCount: Int, localStatus: HomeLocalActivityStatus, venue: String) {
        self.groomCount = groomCount
        self.badgeText = groomCount == 0 ? "0件" : "\(groomCount)件"

        if groomCount == 0 {
            self.title = "近くのグルームはまだありません"
            self.detail = "現地の写真や列状況は、めぐりタブから投稿できます。"
        } else if localStatus.isVisibleToOthers {
            self.title = "近くのグルームも確認"
            self.detail = "\(venue)周辺の写真や現地状況を見ながら、交換相手を探せます。"
        } else {
            self.title = "グルームで現地状況を見る"
            self.detail = "現地交換モードをONにすると、周辺の写真とマッチ確認がつながります。"
        }
    }
}

struct HomeGroomEntrySurface: View {
    var summary: HomeGroomEntrySummary
    var onOpen: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MegrumTheme.sky.opacity(0.22))
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text("グルーム")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                    Text(summary.badgeText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Text(summary.title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)

                Text(summary.detail)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if let onOpen {
                Button(action: onOpen) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.74), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("グルームを開く")
            } else {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(width: 34, height: 34)
                    .accessibilityLabel("めぐりタブで確認")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.68), lineWidth: 1)
        }
    }
}
