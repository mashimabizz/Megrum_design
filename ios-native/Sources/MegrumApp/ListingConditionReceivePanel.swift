import MegrumDesign
import SwiftUI

#if DEBUG
struct ListingConditionReceivePanel: View {
    var scenario: ListingConditionScenario

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("受け取れる候補")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.top, 4)

            Divider()
                .background(ListingConditionDesignColors.divider)

            VStack(spacing: 0) {
                switch scenario {
                case .cashOffer:
                    ListingConditionPhotoOptionRow(
                        index: 1,
                        imageNames: ["twice_momo_1", "twice_momo_2"],
                        isSelected: false
                    )

                    ListingConditionDivider()

                    ListingConditionPhotoOptionRow(
                        index: 2,
                        imageNames: ["twice_sana_1", "twice_dahyun_1"],
                        isSelected: true
                    )

                    ListingConditionDivider()

                    ListingConditionPriceOptionRow(index: 3, amountText: "定価 1,200円")
                case .multipleGoodsAndConditions:
                    ListingConditionConditionOptionRow(
                        index: 1,
                        tagRows: [["TWICE", "サナ"], ["#2025LIVE"]],
                        isSelected: true
                    )

                    ListingConditionDivider()

                    ListingConditionConditionOptionRow(
                        index: 2,
                        tagRows: [["サナ", "モモ"], ["メンバー複数"]],
                        isSelected: false
                    )

                    ListingConditionDivider()

                    ListingConditionConditionOptionRow(
                        index: 3,
                        tagRows: [["サナ以外"], ["#2025LIVE", "トレカ"]],
                        isSelected: false
                    )
                }
            }
        }
        .padding(ListingConditionDesignMetrics.panelPadding)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(ListingConditionDesignColors.panel, in: RoundedRectangle(cornerRadius: ListingConditionDesignMetrics.panelRadius))
        .overlay {
            RoundedRectangle(cornerRadius: ListingConditionDesignMetrics.panelRadius)
                .strokeBorder(MegrumTheme.ink.opacity(0.06), lineWidth: 1)
        }
    }
}

private struct ListingConditionConditionOptionRow: View {
    var index: Int
    var tagRows: [[String]]
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("選択肢 \(index)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 11)
                .frame(height: ListingConditionDesignMetrics.optionLabelHeight)
                .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(tagRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 6) {
                        ForEach(row, id: \.self) { tag in
                            ListingConditionTagChip(title: tag)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: ListingConditionDesignMetrics.optionRowHeight)
        .padding(.horizontal, isSelected ? 10 : 0)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 18)
                    .fill(MegrumTheme.lavender.opacity(0.07))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(MegrumTheme.lavender)
                            .frame(width: 3)
                    }
            }
        }
    }
}

private struct ListingConditionTagChip: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 9)
            .frame(height: 27)
            .background(Color.white.opacity(0.78), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
            }
    }
}

private struct ListingConditionPhotoOptionRow: View {
    var index: Int
    var imageNames: [String]
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: ListingConditionDesignMetrics.optionRowGap) {
            Text("選択肢 \(index)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 11)
                .frame(height: ListingConditionDesignMetrics.optionLabelHeight)
                .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))

            HStack(spacing: ListingConditionDesignMetrics.optionThumbnailGap) {
                ForEach(imageNames.prefix(2), id: \.self) { imageName in
                    ListingConditionThumbnail(imageName: imageName)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: ListingConditionDesignMetrics.optionRowHeight)
        .padding(.horizontal, isSelected ? 10 : 0)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 18)
                    .fill(MegrumTheme.lavender.opacity(0.07))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(MegrumTheme.lavender)
                            .frame(width: 3)
                    }
            }
        }
    }
}

private struct ListingConditionPriceOptionRow: View {
    var index: Int
    var amountText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("選択肢 \(index)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 11)
                .frame(height: ListingConditionDesignMetrics.optionLabelHeight)
                .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 12) {
                Image(systemName: "yensign.circle.fill")
                    .font(.system(size: 27, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)

                Text(amountText)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: ListingConditionDesignMetrics.priceRowHeight)
            .padding(.horizontal, 10)
            .background(ListingConditionDesignColors.priceFill, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.top, 8)
    }
}

private struct ListingConditionDivider: View {
    var body: some View {
        Divider()
            .background(ListingConditionDesignColors.divider)
            .padding(.vertical, 12)
    }
}
#endif
