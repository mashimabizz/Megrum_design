import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeIndividualListingDetailPopup: View {
    var detail: HomeIndividualListingDetailContext

    var body: some View {
        HomeSheetScaffold(bottomButton: nil) {
            VStack(alignment: .leading, spacing: 14) {
                Text("個別募集の詳細")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                HomeIndividualListingCombinationPanels(detail: detail)
            }
        }
    }
}

private struct HomeIndividualListingCombinationPanels: View {
    var detail: HomeIndividualListingDetailContext

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            HomeIndividualListingWantedPanel(detail: detail)
                .frame(maxWidth: .infinity)

            HomeIndividualListingOfferedPanel(detail: detail)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct HomeIndividualListingWantedPanel: View {
    var detail: HomeIndividualListingDetailContext

    private var sortedOptions: [HomeIndividualListingWantedOption] {
        detail.wantedOptions.sorted { lhs, rhs in
            if lhs.position == rhs.position {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.position < rhs.position
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("求めるもの")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Divider()

            VStack(spacing: 0) {
                ForEach(Array(sortedOptions.enumerated()), id: \.element.id) { index, option in
                    HomeIndividualListingWantedRow(index: index + 1, option: option)
                    if index < sortedOptions.count - 1 {
                        Divider()
                    }
                }

                if sortedOptions.isEmpty {
                    Text("求めるものが未設定です")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .padding(.vertical, 12)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 274, alignment: .topLeading)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }
}

private struct HomeIndividualListingWantedRow: View {
    var index: Int
    var option: HomeIndividualListingWantedOption

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Text(IndividualListingListPresentation.optionTitle(index: index))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .padding(.horizontal, 9)
                    .frame(height: 25)
                    .background(MegrumTheme.lavender.opacity(0.11), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                Spacer(minLength: 0)

                if let logicTitle {
                    Text(logicTitle)
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.66)
                }
            }

            if option.isCashOffer {
                HomeIndividualListingCashToken(amount: option.cashAmount)
            } else {
                FlowLayout(spacing: 7, rowSpacing: 7) {
                    ForEach(displayTokens, id: \.self) { token in
                        Text(token)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                            .lineLimit(1)
                            .minimumScaleFactor(0.64)
                            .padding(.horizontal, 9)
                            .frame(height: 28)
                            .background(MegrumTheme.sky.opacity(0.16), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                }
            }
        }
        .padding(.vertical, 12)
    }

    private var displayTokens: [String] {
        var tokens = [option.title]
        if let subtitle = option.subtitle?.nilIfBlank,
           !subtitle.localizedCaseInsensitiveContains("該当するグッズ"),
           subtitle != option.title {
            tokens.append(subtitle)
        }
        return tokens
    }

    private var logicTitle: String? {
        guard !option.isCashOffer else {
            return nil
        }
        switch option.logic {
        case .all:
            return "全部ほしい"
        case .one:
            return nil
        case .atLeast:
            return ListingLogic.minimumCountTitle(option.minimumCount)
        }
    }
}

private struct HomeIndividualListingCashToken: View {
    var amount: Int?

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "yensign")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(MegrumTheme.lavender, in: Circle())

            Text(TradeAmountFormatter.fixedPrice(amount: amount))
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .padding(.horizontal, 9)
        .frame(height: 42)
        .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct HomeIndividualListingOfferedPanel: View {
    var detail: HomeIndividualListingDetailContext

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("譲るもの")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Divider()

            VStack(spacing: 12) {
                Spacer(minLength: 0)

                if detail.offeredItems.isEmpty {
                    ListingOfferCashCard(amount: detail.offeredCashAmount)
                } else {
                    HomeIndividualListingOfferedStack(items: detail.offeredItems)
                        .frame(height: 138)

                    Text(offerCaption)
                        .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.74))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 214)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 274, alignment: .topLeading)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }

    private var offerCaption: String {
        let count = detail.offeredItems.reduce(0) { $0 + $1.quantity }
        if count > 1 {
            switch detail.offeredLogic {
            case .one:
                return "\(count)点からどれか"
            case .all:
                return "\(count)点セット"
            case .atLeast:
                return "\(detail.offeredMinimumCount)点以上"
            }
        }
        return detail.offeredItems.first?.title ?? "グッズ"
    }
}

private struct HomeIndividualListingOfferedStack: View {
    var items: [HomeIndividualListingOfferedItem]

    private var visibleItems: [HomeIndividualListingOfferedItem] {
        Array(items.prefix(3))
    }

    var body: some View {
        ZStack {
            ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                ListingGoodsImage(url: item.imageURL, title: item.title, cornerRadius: 14)
                    .frame(width: 86, height: 108)
                    .scaleEffect(index == 0 ? 1 : 0.92)
                    .offset(x: offset(for: index), y: index == 0 ? 0 : 5)
                    .zIndex(Double(visibleItems.count - index))
                    .accessibilityLabel(item.title)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func offset(for index: Int) -> CGFloat {
        guard visibleItems.count > 1 else {
            return 0
        }
        return CGFloat(index) * 28 - CGFloat(visibleItems.count - 1) * 14
    }
}
