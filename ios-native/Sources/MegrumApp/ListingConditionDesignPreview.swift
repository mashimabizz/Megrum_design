import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if DEBUG
struct ListingConditionDesignPreview: View {
    var scenario: ListingConditionScenario = .cashOffer

    var body: some View {
        ZStack {
            ListingConditionDesignColors.background
                .ignoresSafeArea()

            VStack(spacing: ListingConditionDesignMetrics.verticalGap) {
                ListingConditionDesignHeader()
                    .padding(.horizontal, ListingConditionDesignMetrics.screenPadding)

                ListingConditionSwitcher(scenario: scenario)
                    .padding(.top, 2)

                ListingConditionSplitContent(scenario: scenario)
                    .padding(.horizontal, ListingConditionDesignMetrics.screenPadding)
                    .padding(.top, 4)

                ListingConditionBottomPanel()
                    .padding(.horizontal, ListingConditionDesignMetrics.screenPadding)
                    .padding(.top, 2)
            }
            .padding(.top, ListingConditionDesignMetrics.topPadding)
            .padding(.bottom, ListingConditionDesignMetrics.bottomPadding)
        }
    }
}

enum ListingConditionScenario {
    case cashOffer
    case multipleGoodsAndConditions
}

private enum ListingConditionDesignMetrics {
    static let previewWidth: CGFloat = 368
    static let previewHeight: CGFloat = 800
    static let screenPadding: CGFloat = 10
    static let topPadding: CGFloat = 50
    static let bottomPadding: CGFloat = 8
    static let verticalGap: CGFloat = 10

    static let headerButtonSize: CGFloat = 44
    static let headerTitleSize: CGFloat = 25
    static let headerSubtitleSize: CGFloat = 14

    static let conditionCardWidth: CGFloat = 184
    static let conditionCardHeight: CGFloat = 86
    static let sideConditionCardWidth: CGFloat = 56
    static let conditionCardRadius: CGFloat = 18
    static let conditionTitleSize: CGFloat = 21
    static let conditionCounterSize: CGFloat = 19
    static let conditionEditButtonSize: CGFloat = 44

    static let splitHeight: CGFloat = 400
    static let splitSpacing: CGFloat = 8
    static let leftColumnRatio: CGFloat = 0.52
    static let panelRadius: CGFloat = 24
    static let panelPadding: CGFloat = 14

    static let optionRowHeight: CGFloat = 92
    static let optionLabelHeight: CGFloat = 28
    static let optionThumbnailSize: CGFloat = 58
    static let optionThumbnailGap: CGFloat = 8
    static let optionRowGap: CGFloat = 9
    static let priceRowHeight: CGFloat = 64

    static let offerCardWidth: CGFloat = 136
    static let offerCardHeight: CGFloat = 126
    static let offerIconSize: CGFloat = 40
    static let offerPriceSize: CGFloat = 22
    static let offerLabelSize: CGFloat = 13

    static let bottomPanelHeight: CGFloat = 116
    static let addButtonSize: CGFloat = 52
    static let addLabelSize: CGFloat = 21
    static let toggleLabelSize: CGFloat = 15
}

private enum ListingConditionDesignColors {
    static let background = Color(red: 0.986, green: 0.980, blue: 0.990)
    static let panel = Color.white.opacity(0.86)
    static let faintPanel = Color.white.opacity(0.62)
    static let priceFill = MegrumTheme.lavender.opacity(0.11)
    static let divider = MegrumTheme.ink.opacity(0.08)
}

private struct ListingConditionDesignHeader: View {
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

private struct ListingConditionSwitcher: View {
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

private struct ListingConditionSplitContent: View {
    var scenario: ListingConditionScenario

    var body: some View {
        GeometryReader { proxy in
            let leftWidth = floor((proxy.size.width - ListingConditionDesignMetrics.splitSpacing) * ListingConditionDesignMetrics.leftColumnRatio)
            let rightWidth = proxy.size.width - leftWidth - ListingConditionDesignMetrics.splitSpacing

            HStack(spacing: ListingConditionDesignMetrics.splitSpacing) {
                ListingConditionReceivePanel(scenario: scenario)
                    .frame(width: leftWidth)

                Group {
                    switch scenario {
                    case .cashOffer:
                        ListingConditionOfferPricePanel()
                    case .multipleGoodsAndConditions:
                        ListingConditionOfferGoodsPanel()
                    }
                }
                    .frame(width: rightWidth)
            }
        }
        .frame(height: ListingConditionDesignMetrics.splitHeight)
    }
}

private struct ListingConditionReceivePanel: View {
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

private struct ListingConditionThumbnail: View {
    var imageName: String

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(MegrumTheme.lavender.opacity(0.12))
            .overlay {
                imageLayer
            }
            .frame(
                width: ListingConditionDesignMetrics.optionThumbnailSize,
                height: ListingConditionDesignMetrics.optionThumbnailSize
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.78), lineWidth: 1)
            }
    }

    private var imageURL: URL? {
        Bundle.module.url(forResource: imageName, withExtension: "png", subdirectory: "TestGoodsImages")
            ?? URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/TestGoodsImages/\(imageName).png")
    }

    @ViewBuilder
    private var imageLayer: some View {
        #if canImport(UIKit)
        if let imageURL,
           let data = try? Data(contentsOf: imageURL),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
        #else
        placeholder
        #endif
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [
                MegrumTheme.lavender.opacity(0.42),
                MegrumTheme.pink.opacity(0.32)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct ListingConditionOfferGoodsPanel: View {
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

private struct ListingConditionLargeGoodsThumbnail: View {
    var imageName: String

    var body: some View {
        ListingConditionThumbnail(imageName: imageName)
            .frame(width: 54, height: 54)
    }
}

private struct ListingConditionOfferPricePanel: View {
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

private struct ListingConditionBottomPanel: View {
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

#Preview("個別募集 条件切替 定価") {
    ListingConditionDesignPreview()
        .frame(
            width: ListingConditionDesignMetrics.previewWidth,
            height: ListingConditionDesignMetrics.previewHeight
        )
}

#Preview("個別募集 複数グッズ 条件指定") {
    ListingConditionDesignPreview(scenario: .multipleGoodsAndConditions)
        .frame(
            width: ListingConditionDesignMetrics.previewWidth,
            height: ListingConditionDesignMetrics.previewHeight
        )
}
#endif
