import MegrumDesign
import SwiftUI

struct HomeMutualMatchConditionReviewRow: View {
    var point: HomeMutualMatchConditionReviewPoint

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(tint)
                .frame(width: 25, height: 25)
                .background(tint.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(point.title)
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Text(point.tagTitle)
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(tint.opacity(0.10), in: Capsule())
                }

                if point.showsCounterpartValues {
                    VStack(alignment: .leading, spacing: 4) {
                        valueLine(label: "相手", value: point.partnerValue)
                        valueLine(label: "自分", value: point.viewerValue)
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(tint.opacity(0.055), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func valueLine(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .font(.system(size: 10.5, weight: .black, design: .rounded))
                .foregroundStyle(tint)
                .frame(width: 26, alignment: .leading)

            Text(value)
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tint: Color {
        switch point.status {
        case .matched:
            return MegrumTheme.ok
        case .needsDecision:
            return MegrumTheme.conditionPossible
        case .mismatch:
            return MegrumTheme.conditionWarning
        case .skipped:
            return MegrumTheme.muted
        }
    }

    private var systemImage: String {
        switch point.status {
        case .matched:
            return "checkmark.circle.fill"
        case .needsDecision:
            return "bubble.left.and.bubble.right.fill"
        case .mismatch:
            return "exclamationmark.triangle.fill"
        case .skipped:
            return "minus.circle.fill"
        }
    }
}

private extension HomeMutualMatchConditionReviewPoint {
    var showsCounterpartValues: Bool {
        !partnerValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !viewerValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
