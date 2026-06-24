import MegrumDesign
import SwiftUI

#if DEBUG
struct ListingConditionDesignHeader: View {
    var body: some View {
        HStack {
            ListingConditionCircleIcon(systemName: "chevron.left")

            Spacer()

            VStack(spacing: 5) {
                Text("個別募集")
                    .font(.system(size: ListingConditionDesignMetrics.headerTitleSize, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Text("譲るものごとに条件を見る")
                    .font(.system(size: ListingConditionDesignMetrics.headerSubtitleSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            Spacer()

            ListingConditionCircleIcon(systemName: "ellipsis")
        }
    }
}

struct ListingConditionSwitcher: View {
    var scenario: ListingConditionScenario

    var body: some View {
        VStack(spacing: 11) {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 16, height: 40)

                ListingConditionSideCard(title: "交換条件 4", counter: "4/4")

                ListingConditionActiveCard()

                ListingConditionSideCard(title: "交換条件 2", counter: "2/4")

                Image(systemName: "chevron.right")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 16, height: 40)
            }

            HStack(spacing: 9) {
                Capsule()
                    .fill(MegrumTheme.lavender)
                    .frame(width: 28, height: 7)

                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index == 0 ? MegrumTheme.lavender.opacity(0.88) : MegrumTheme.muted.opacity(0.28))
                        .frame(width: 9, height: 9)
                }
            }
        }
    }
}

private struct ListingConditionCircleIcon: View {
    var systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .frame(
                width: ListingConditionDesignMetrics.headerButtonSize,
                height: ListingConditionDesignMetrics.headerButtonSize
            )
            .background(Color.white.opacity(0.90), in: Circle())
            .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 13, y: 7)
            .accessibilityHidden(true)
    }
}

private struct ListingConditionActiveCard: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("交換条件 1")
                    .font(.system(size: ListingConditionDesignMetrics.conditionTitleSize, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)

                Text("1/4")
                    .font(.system(size: ListingConditionDesignMetrics.conditionCounterSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
            .frame(maxWidth: .infinity)

            Button {} label: {
                VStack(spacing: 3) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("編集")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(MegrumTheme.lavender)
                .frame(
                    width: ListingConditionDesignMetrics.conditionEditButtonSize,
                    height: ListingConditionDesignMetrics.conditionEditButtonSize
                )
                .background(MegrumTheme.lavender.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.22), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("交換条件1を編集")
        }
        .padding(.leading, 18)
        .padding(.trailing, 12)
        .frame(
            width: ListingConditionDesignMetrics.conditionCardWidth,
            height: ListingConditionDesignMetrics.conditionCardHeight
        )
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: ListingConditionDesignMetrics.conditionCardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: ListingConditionDesignMetrics.conditionCardRadius)
                .strokeBorder(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.05), radius: 10, y: 5)
    }
}

private struct ListingConditionSideCard: View {
    var title: String
    var counter: String

    var body: some View {
        VStack(spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Text(counter)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(MegrumTheme.muted.opacity(0.52))
        .frame(
            width: ListingConditionDesignMetrics.sideConditionCardWidth,
            height: ListingConditionDesignMetrics.conditionCardHeight - 8
        )
        .background(Color.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }
}
#endif
