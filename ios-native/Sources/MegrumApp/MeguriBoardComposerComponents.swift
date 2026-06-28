import MegrumDesign
import SwiftUI

struct BoardThreadDraftMapPreview: View {
    var title: String
    var summary: String
    var hasThumbnail: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MegrumTheme.lavender.opacity(0.12))

                Image(systemName: hasThumbnail ? "photo.fill" : "text.bubble.fill")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(MegrumTheme.lavender)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)

                Text(summary)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(2)

                Label("地図ではこのカードがピン上に出ます", systemImage: "mappin.and.ellipse")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct BoardThreadThumbnailPickerLabel: View {
    var hasThumbnail: Bool

    var body: some View {
        Label(hasThumbnail ? "写真を変更" : "写真を選ぶ", systemImage: "photo")
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(.white.opacity(0.9), in: Capsule())
    }
}

struct BoardPrefecturePickerSheet: View {
    var selectedPrefecture: String?
    var onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(japanesePrefectures, id: \.self) { prefecture in
            Button {
                onSelect(prefecture)
                dismiss()
            } label: {
                HStack {
                    Text(prefecture)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Spacer()

                    if selectedPrefecture == prefecture {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(prefecture)をチャットルームの都道府県に設定")
        }
        .navigationTitle("都道府県を選択")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

private let japanesePrefectures = [
    "北海道",
    "青森県",
    "岩手県",
    "宮城県",
    "秋田県",
    "山形県",
    "福島県",
    "茨城県",
    "栃木県",
    "群馬県",
    "埼玉県",
    "千葉県",
    "東京都",
    "神奈川県",
    "新潟県",
    "富山県",
    "石川県",
    "福井県",
    "山梨県",
    "長野県",
    "岐阜県",
    "静岡県",
    "愛知県",
    "三重県",
    "滋賀県",
    "京都府",
    "大阪府",
    "兵庫県",
    "奈良県",
    "和歌山県",
    "鳥取県",
    "島根県",
    "岡山県",
    "広島県",
    "山口県",
    "徳島県",
    "香川県",
    "愛媛県",
    "高知県",
    "福岡県",
    "佐賀県",
    "長崎県",
    "熊本県",
    "大分県",
    "宮崎県",
    "鹿児島県",
    "沖縄県"
]
