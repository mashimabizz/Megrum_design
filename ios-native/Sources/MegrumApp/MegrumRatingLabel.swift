import MegrumDesign
import SwiftUI

/// 評価表示の共通定義。やりとり一覧・候補シートヘッダー・取引チャットヘッダー・評価入力で統一。iter1226.382 / FB6-4。
enum MegrumRating {
    /// 評価の星アイコンの色（黄色）。
    static let starColor = Color(red: 1.0, green: 0.72, blue: 0.0)

    /// 「X.X（X件）」形式（やりとり一覧と同じ）。評価が無ければ「-（N件）」。
    static func valueText(averageStars: Double?, evaluationCount: Int) -> String {
        if let averageStars, evaluationCount > 0 {
            return String(format: "%.1f（%d件）", averageStars, evaluationCount)
        }
        return "-（\(evaluationCount)件）"
    }
}

/// 黄色い星アイコン＋「X.X（X件）」。評価表記はここに集約する。
struct MegrumRatingLabel: View {
    var averageStars: Double?
    var evaluationCount: Int
    var starSize: CGFloat = 12
    var fontSize: CGFloat = 12.5
    var fontWeight: Font.Weight = .semibold
    var textColor: Color = MegrumTheme.muted

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: starSize, weight: .semibold))
                .foregroundStyle(MegrumRating.starColor)
            Text(MegrumRating.valueText(averageStars: averageStars, evaluationCount: evaluationCount))
                .font(.system(size: fontSize, weight: fontWeight, design: .rounded))
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("評価 \(MegrumRating.valueText(averageStars: averageStars, evaluationCount: evaluationCount))")
    }
}
