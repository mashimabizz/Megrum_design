import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeMutualMatchSelectedPreviewCard: View {
    var pair: HomeMutualMatchProposalPair
    var review: HomeMutualMatchConditionReview

    @State private var isShowingConditionHelp = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)

                Text("何を交換するか")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }

            HStack(spacing: 10) {
                HomeMutualMatchPreviewSide(
                    title: "求めるグッズ",
                    item: pair.receiverDisplayItem,
                    tint: MegrumTheme.lavender
                )

                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(MegrumTheme.muted.opacity(0.64))

                HomeMutualMatchPreviewSide(
                    title: "譲るグッズ",
                    item: pair.senderDisplayItem,
                    tint: MegrumTheme.pink
                )
            }

            Divider().opacity(0.45)

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 6) {
                    Text("確認ポイント")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)

                    Button {
                        isShowingConditionHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(MegrumTheme.lavender)
                            .frame(width: 26, height: 26)
                            .background(MegrumTheme.lavender.opacity(0.10), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("確認ポイントの説明を開く")
                    .popover(isPresented: $isShowingConditionHelp) {
                        HomeMutualMatchConditionHelpPopover()
                            .presentationCompactAdaptation(.popover)
                    }

                    Spacer(minLength: 0)
                }

                ForEach(HomeMutualMatchConditionReviewPointPolicy.points(for: pair, review: review)) { point in
                    HomeMutualMatchConditionReviewRow(point: point)
                }
            }
        }
        .padding(14)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.lavender.opacity(0.08), radius: 14, y: 8)
        .accessibilityElement(children: .contain)
    }
}

struct HomeMutualMatchConditionHelpPopover: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("タグの見方")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text("相互マッチはグッズ条件で候補に残し、交換条件・支払条件は相談が必要な点だけをタグで出します。")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    helpRow(
                        tag: "交換条件不一致",
                        detail: "片方が現地交換のみ、もう片方が郵送交換のみなど、共通の交換手段がない場合。"
                    )
                    helpRow(
                        tag: "要相談",
                        detail: "双方が現地交換・郵送OKなど、交換手段が一意に決まらない場合。片方が現地/郵送を指定していればその手段で決まります。"
                    )
                    helpRow(
                        tag: "交換場所要相談 / 都道府県未設定",
                        detail: "現地交換で都道府県が違う、または片方の都道府県が未設定の場合。"
                    )
                    helpRow(
                        tag: "日程要相談",
                        detail: "片方でも日程が相談になっている、日程が合わない、または1日に決まらない場合。"
                    )
                    helpRow(
                        tag: "送料要相談",
                        detail: "郵送交換で、どちらかの送料負担が要相談になっている場合。"
                    )
                    helpRow(
                        tag: "金額込み候補 / 金額不足",
                        detail: "定価・金額指定を含む候補です。提示金額が足りない場合は金額不足になります。"
                    )
                    helpRow(
                        tag: "支払条件のタグ",
                        detail: "金額条件がある時だけ確認します。共通手段がない、未設定、その他のみの場合に相談タグが出ます。"
                    )
                }
            }
            .padding(18)
        }
        .frame(width: 320, height: 430)
        .background(MegrumTheme.canvas)
    }

    private func helpRow(tag: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tag)
                .font(.system(size: 12.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
            Text(detail)
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct HomeMutualMatchPreviewSide: View {
    var title: String
    var item: HomeMutualMatchProposalItem
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                HomeMutualMatchDisplayArtwork(item: item, tint: tint)
                    .frame(height: 92)

                Text(title)
                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.92), in: Capsule())
                    .padding(6)
            }

            Text(item.title)
                .font(.system(size: 12.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            if item.data.kind != .goods, !item.subtitle.isEmpty {
                Text(item.subtitle)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HomeMutualMatchDisplayArtwork: View {
    var item: HomeMutualMatchProposalItem
    var tint: Color

    var body: some View {
        Group {
            if let goods = item.goods {
                HomeTinyGoodsThumbnail(goods: goods)
            } else {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .overlay {
                        VStack(spacing: 7) {
                            Image(systemName: item.data.kind == .fixedPrice ? "tag.fill" : "yensign.circle.fill")
                                .font(.system(size: 24, weight: .black))
                                .foregroundStyle(tint)
                            Text(item.title)
                                .font(.system(size: 19, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            if !item.subtitle.isEmpty {
                                Text(item.subtitle)
                                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                                    .foregroundStyle(tint)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .strokeBorder(tint.opacity(0.28), lineWidth: 1)
                    }
            }
        }
        .accessibilityLabel(item.title)
    }
}

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
