import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeIndividualListingWantedPanel: View {
    var detail: HomeIndividualListingDetailContext
    var selectedWantedOptionID: UUID?
    var onSelectWantedOption: ((HomeIndividualListingWantedOption) -> Void)?

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
                    HomeIndividualListingWantedSelectableRow(
                        index: index + 1,
                        option: option,
                        isSelected: selectedWantedOptionID == option.id,
                        onSelect: onSelectWantedOption.map { action in
                            { action(option) }
                        }
                    )
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

private struct HomeIndividualListingWantedSelectableRow: View {
    var index: Int
    var option: HomeIndividualListingWantedOption
    var isSelected: Bool
    var onSelect: (() -> Void)?

    var body: some View {
        Group {
            if let onSelect {
                Button(action: onSelect) {
                    content
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(IndividualListingListPresentation.optionTitle(index: index))、\(option.title)")
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            } else {
                content
            }
        }
    }

    private var content: some View {
        HomeIndividualListingWantedRow(index: index, option: option)
            .padding(.horizontal, isSelected ? 8 : 0)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(isSelected ? MegrumTheme.lavender.opacity(0.07) : Color.clear)
            )
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.72), lineWidth: 2)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
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
            } else if !option.previewItems.isEmpty {
                HStack(spacing: 8) {
                    ForEach(option.previewItems.prefix(2)) { item in
                        ListingGoodsImage(url: item.imageURL, title: item.title, cornerRadius: 9)
                            .frame(width: 50, height: 50)
                            .accessibilityLabel(item.title)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
