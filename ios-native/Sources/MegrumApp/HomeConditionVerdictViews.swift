import MegrumDesign
import SwiftUI

/// 相手候補シートの「この人とどう交換できそう？」ブロック。
/// 生の条件羅列ではなく、現地・郵送・お金を判定済みの宣言文＋バッジで出す。
struct HomeConditionVerdictBlock: View {
    var verdict: HomeConditionVerdict
    var onOpenCalendar: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("この人とどう交換できそう？")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            VStack(alignment: .leading, spacing: 9) {
                ForEach(verdict.lines) { line in
                    HomeConditionVerdictRow(
                        line: line,
                        onOpenCalendar: line.showsCalendarButton ? onOpenCalendar : nil
                    )
                }
            }
        }
    }
}

struct HomeConditionVerdictRow: View {
    var line: ConditionVerdictLine
    var onOpenCalendar: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(badgeColor.opacity(0.14))
                Image(systemName: line.iconSystemName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(badgeColor)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .center, spacing: 6) {
                    verdictText
                        .fixedSize(horizontal: false, vertical: true)
                    badgeView
                }

                if let subtitle = line.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let onOpenCalendar {
                    Button(action: onOpenCalendar) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text("相手の会える日を見る")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                        }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(MegrumTheme.lavender.opacity(0.1), in: Capsule())
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 1)
                }
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var verdictText: Text {
        line.segments.reduce(Text("")) { partial, segment in
            partial + Text(segment.text).fontWeight(segment.bold ? .bold : .regular)
        }
        .font(.system(size: 13.5, design: .rounded))
        .foregroundStyle(MegrumTheme.ink)
    }

    private var badgeView: some View {
        Text(badgeText)
            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
            .padding(.horizontal, 7)
            .padding(.vertical, 1.5)
            .background(badgeColor.opacity(0.16), in: Capsule())
            .foregroundStyle(badgeColor)
            .fixedSize()
    }

    private var badgeText: String {
        switch line.badge {
        case .ok:
            "OK"
        case .needsTalk:
            "要相談"
        case .check:
            "要確認"
        }
    }

    private var badgeColor: Color {
        switch line.badge {
        case .ok:
            MegrumTheme.ok
        case .needsTalk:
            MegrumTheme.conditionPossible
        case .check:
            MegrumTheme.conditionExact
        }
    }

    private var accessibilityText: String {
        [line.plainText, line.subtitle, "判定: \(badgeText)"]
            .compactMap { $0 }
            .joined(separator: "。")
    }
}
