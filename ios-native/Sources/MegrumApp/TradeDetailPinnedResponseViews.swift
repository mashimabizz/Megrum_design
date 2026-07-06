import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeIncomingProposalSummaryCard: View {
    var label: String
    var summary: String
    var offeredGoods: [GoodsItem] = []
    var requestedGoods: [GoodsItem] = []
    var offeredGoodsCount: Int = 0
    var requestedGoodsCount: Int = 0
    var action: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 15, weight: .black))
                    Text(label)
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 118, height: 48)
            }
            .buttonStyle(.plain)
            .accessibilityHint("個別募集の詳細を開きます")

            Rectangle()
                .fill(MegrumTheme.ink.opacity(0.08))
                .frame(width: 1, height: 48)

            // 打診内容は文章ではなく小さなグッズ画像で見せる（画像が無い時のみ文章）。
            Group {
                if offeredGoods.isEmpty && requestedGoods.isEmpty {
                    Text(summary)
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                } else {
                    TradeProposalGoodsPreviewStrip(
                        offeredGoods: offeredGoods,
                        requestedGoods: requestedGoods,
                        offeredGoodsCount: offeredGoodsCount,
                        requestedGoodsCount: requestedGoodsCount
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)

            Button(action: action) {
                Text("詳細")
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 54, height: 48)
            }
            .buttonStyle(.plain)
            .accessibilityHint("個別募集の詳細を開きます")
        }
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct TradeIncomingProposalResponseCard: View {
    var presentation: TradeProposalResponsePresentation
    @Binding var selectedExchangeMethod: ExchangeMethod?
    @Binding var selectedPaymentOptionID: String?
    var isCondensedForKeyboard: Bool
    var isResponding: Bool
    var onAgree: () -> Void
    var onReject: () -> Void
    var onCounterProposal: () -> Void

    private var effectiveExchangeMethod: ExchangeMethod? {
        selectedExchangeMethod ?? presentation.defaultSelectedExchangeMethod
    }

    private var effectivePaymentOptionID: String? {
        selectedPaymentOptionID ?? presentation.defaultPaymentOptionID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let responseHeaderText = presentation.responseHeaderText, !isCondensedForKeyboard {
                Text(responseHeaderText)
                    .font(.system(size: presentation.viewerHasCounterProposal ? 13.5 : 18, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if presentation.needsExchangeMethodSelection {
                TradeResponseMethodSelector(
                    presentation: presentation,
                    selectedExchangeMethod: $selectedExchangeMethod,
                    effectiveExchangeMethod: effectiveExchangeMethod
                )
            }

            if presentation.showsPaymentSelector {
                TradeResponsePaymentSelector(
                    presentation: presentation,
                    selectedPaymentOptionID: $selectedPaymentOptionID,
                    effectivePaymentOptionID: effectivePaymentOptionID
                )
            }

            actionButtons
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.05), radius: 14, x: 0, y: 8)
        .animation(.snappy(duration: 0.18), value: isCondensedForKeyboard)
        .onAppear {
            if selectedExchangeMethod == nil {
                selectedExchangeMethod = presentation.defaultSelectedExchangeMethod
            }
            if selectedPaymentOptionID == nil {
                selectedPaymentOptionID = presentation.defaultPaymentOptionID
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                if presentation.showsPrimaryAgreeAction {
                    primaryActionButton
                }
                counterProposalButton
            }

            Button(action: onReject) {
                Text("見送る")
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
            }
            .buttonStyle(.plain)
            .disabled(isResponding || !presentation.canReject)
        }
    }

    private var primaryActionButton: some View {
        Button(action: onAgree) {
            HStack(spacing: 7) {
                if isResponding {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: primaryActionImageName)
                        .font(.system(size: 13.5, weight: .black))
                }
                Text(presentation.primaryActionTitle(selectedExchangeMethod: effectiveExchangeMethod))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .font(.system(size: 13.6, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isResponding || !presentation.canAgree)
    }

    private var counterProposalButton: some View {
        Button(action: onCounterProposal) {
            Label("条件を変えて再打診", systemImage: "arrow.triangle.2.circlepath")
                .font(.system(size: 13.4, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .foregroundStyle(MegrumTheme.lavender)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.38), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(isResponding || !presentation.canCounterProposal)
    }

    private var primaryActionImageName: String {
        switch effectiveExchangeMethod {
        case .mail:
            "shippingbox.fill"
        case .hand:
            "mappin.circle.fill"
        case .both, nil:
            "checkmark.circle.fill"
        }
    }
}

/// 打診内容のミニプレビュー：ゆずる⇄うけとるのグッズ画像を枠内サイズで並べる。
struct TradeProposalGoodsPreviewStrip: View {
    var offeredGoods: [GoodsItem]
    var requestedGoods: [GoodsItem]
    var offeredGoodsCount: Int
    var requestedGoodsCount: Int

    private static let visibleLimit = 2

    var body: some View {
        HStack(spacing: 7) {
            sideThumbs(goods: offeredGoods, totalCount: offeredGoodsCount)

            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)

            sideThumbs(goods: requestedGoods, totalCount: requestedGoodsCount)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ゆずる \(offeredGoodsCount)点、うけとる \(requestedGoodsCount)点")
    }

    @ViewBuilder
    private func sideThumbs(goods: [GoodsItem], totalCount: Int) -> some View {
        HStack(spacing: 4) {
            if goods.isEmpty {
                TradeProposalGoodsPreviewPlaceholder()
            } else {
                ForEach(goods.prefix(Self.visibleLimit)) { item in
                    TradeProposalGoodsPreviewThumb(item: item)
                }
                if totalCount > Self.visibleLimit {
                    Text("+\(totalCount - Self.visibleLimit)")
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }
        }
    }
}

private struct TradeProposalGoodsPreviewThumb: View {
    var item: GoodsItem

    var body: some View {
        ZStack {
            if let imageURL = item.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        MegrumTheme.lavender.opacity(0.14)
                    }
                }
            } else {
                MegrumTheme.lavender.opacity(0.14)
            }
        }
        .frame(width: 34, height: 34)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.22), lineWidth: 1)
        }
    }
}

private struct TradeProposalGoodsPreviewPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.10))
            .frame(width: 34, height: 34)
            .overlay {
                Image(systemName: "yensign.circle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender.opacity(0.8))
            }
    }
}
