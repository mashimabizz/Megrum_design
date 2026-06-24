import MegrumDesign
import SwiftUI

#if DEBUG
struct ListingConditionOfferGoodsPanel: View {
    private let imageNames = ["twice_sana_1", "twice_momo_1", "twice_dahyun_1"]

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 12)

            Text("譲るもの")
                .font(.system(size: ListingConditionDesignMetrics.offerLabelSize, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ListingConditionLargeGoodsThumbnail(imageName: imageNames[0])
                    ListingConditionLargeGoodsThumbnail(imageName: imageNames[1])
                }
                HStack(spacing: 8) {
                    ListingConditionLargeGoodsThumbnail(imageName: imageNames[2])
                    ListingConditionMoreGoodsTile()
                }
            }

            Text("画像付きの複数グッズ")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 10)
                .frame(height: 25)
                .background(MegrumTheme.lavender.opacity(0.09), in: Capsule())

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ListingConditionDesignColors.faintPanel, in: RoundedRectangle(cornerRadius: ListingConditionDesignMetrics.panelRadius))
        .overlay {
            RoundedRectangle(cornerRadius: ListingConditionDesignMetrics.panelRadius)
                .strokeBorder(MegrumTheme.ink.opacity(0.05), lineWidth: 1)
        }
    }
}

struct ListingConditionOfferPricePanel: View {
    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 20)

            VStack(spacing: 12) {
                Text("譲るもの")
                    .font(.system(size: ListingConditionDesignMetrics.offerLabelSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)

                VStack(spacing: 10) {
                    Image(systemName: "gift.circle.fill")
                        .font(.system(size: ListingConditionDesignMetrics.offerIconSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)

                    Text("定価 800円")
                        .font(.system(size: ListingConditionDesignMetrics.offerPriceSize, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(
                    width: ListingConditionDesignMetrics.offerCardWidth,
                    height: ListingConditionDesignMetrics.offerCardHeight
                )
                .background(ListingConditionDesignColors.priceFill, in: RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ListingConditionDesignColors.faintPanel, in: RoundedRectangle(cornerRadius: ListingConditionDesignMetrics.panelRadius))
        .overlay {
            RoundedRectangle(cornerRadius: ListingConditionDesignMetrics.panelRadius)
                .strokeBorder(MegrumTheme.ink.opacity(0.05), lineWidth: 1)
        }
    }
}

struct ListingConditionBottomPanel: View {
    @State private var acceptsOtherProposal = true

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {} label: {
                    Image(systemName: "plus")
                        .font(.system(size: 30, weight: .light, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(
                            width: ListingConditionDesignMetrics.addButtonSize,
                            height: ListingConditionDesignMetrics.addButtonSize
                        )
                        .background(
                            LinearGradient(
                                colors: [MegrumTheme.lavender, MegrumTheme.lavender.opacity(0.72)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("条件を追加")

                Text("条件を追加")
                    .font(.system(size: ListingConditionDesignMetrics.addLabelSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)

                Spacer()
            }

            Divider()
                .background(ListingConditionDesignColors.divider)

            Toggle(isOn: $acceptsOtherProposal) {
                Text("それ以外の打診も受け付ける")
                    .font(.system(size: ListingConditionDesignMetrics.toggleLabelSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }
            .tint(MegrumTheme.lavender)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: ListingConditionDesignMetrics.bottomPanelHeight)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(MegrumTheme.ink.opacity(0.06), lineWidth: 1)
        }
    }
}

private struct ListingConditionLargeGoodsThumbnail: View {
    var imageName: String

    var body: some View {
        ListingConditionThumbnail(imageName: imageName)
            .frame(width: 54, height: 54)
    }
}

private struct ListingConditionMoreGoodsTile: View {
    var body: some View {
        VStack(spacing: 3) {
            Text("+")
                .font(.system(size: 20, weight: .black, design: .rounded))
            Text("3点")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(MegrumTheme.lavender)
        .frame(width: 54, height: 54)
        .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
    }
}
#endif
