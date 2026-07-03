import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingReceivePanel: View {
    var options: [IndividualListingWishOption]
    var wishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    var canEdit: Bool
    var onAddCondition: () -> Void
    @State private var presentationState = IndividualListingReceivePanelPresentationState()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("求めるもの")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Divider()

            VStack(spacing: 0) {
                if IndividualListingListPresentation.usesCollapsedOptionSummary(optionCount: options.count) {
                    Button {
                        presentationState.showOptionBreakdown()
                    } label: {
                        IndividualListingCollapsedOptionsRow(
                            options: options,
                            wishByID: wishByID,
                            groups: groups,
                            goodsTypes: goodsTypes
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("選択肢\(options.count)件の内訳を表示")
                } else {
                    ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                        IndividualListingOptionRow(
                            index: index + 1,
                            option: option,
                            wishByID: wishByID,
                            groups: groups,
                            characters: characters,
                            goodsTypes: goodsTypes
                        )
                        if index < options.count - 1 {
                            Divider()
                        }
                    }
                }

                if options.isEmpty {
                    IndividualListingEmptyOptionRow()
                }

                if canEdit {
                    IndividualListingAddConditionRow(action: onAddCondition)
                        .padding(.top, options.isEmpty ? 0 : 10)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
        .sheet(isPresented: $presentationState.isShowingOptionBreakdown) {
            IndividualListingOptionBreakdownSheet(
                options: options,
                wishByID: wishByID,
                groups: groups,
                characters: characters,
                goodsTypes: goodsTypes
            )
        }
    }
}

private struct IndividualListingCollapsedOptionsRow: View {
    var options: [IndividualListingWishOption]
    var wishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var goodsTypes: [GoodsType]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(options.prefix(2).enumerated()), id: \.element.id) { _, option in
                IndividualListingOptionThumbnail(
                    option: option,
                    wishByID: wishByID,
                    groups: groups,
                    goodsTypes: goodsTypes
                )
            }

            IndividualListingOtherOptionsThumbnail()

            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct IndividualListingOptionBreakdownSheet: View {
    @Environment(\.dismiss) private var dismiss
    var options: [IndividualListingWishOption]
    var wishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                        IndividualListingOptionRow(
                            index: index + 1,
                            option: option,
                            wishByID: wishByID,
                            groups: groups,
                            characters: characters,
                            goodsTypes: goodsTypes
                        )
                        if index < options.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle("選択肢の内訳")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct IndividualListingOfferPanel: View {
    var listing: IndividualListing
    var haveItems: [GoodsItem]
    var goodsTypes: [GoodsType]
    var fallbackCashAmount: Int?
    var canEdit: Bool = false
    var onEdit: () -> Void = {}

    private var displayGoods: [HomeMockGoods] {
        haveItems.enumerated().map { index, item in
            HomeMockGoods.from(item: item, index: index, goodsTypes: goodsTypes)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("譲るもの")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if canEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                            .frame(width: 30, height: 30)
                            .background(MegrumTheme.lavender.opacity(0.10), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("譲るものを編集")
                }

                Spacer(minLength: 0)
            }

            Divider()

            VStack(spacing: 16) {
                Spacer(minLength: 0)

                if displayGoods.isEmpty {
                    ListingOfferCashCard(amount: fallbackCashAmount)
                } else {
                    HomeDiscoveryRotaryCard(
                        goods: displayGoods,
                        goodsCondition: .direct,
                        exchangeCondition: .possible,
                        paymentCondition: .compatible,
                        showsConditionOverlay: false
                    )
                    .frame(height: 172)

                    Text(offerCaption)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.74))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 320)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 404)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }

    private var offerCaption: String {
        let count = listing.haves.reduce(0) { $0 + $1.quantity }
        if count > 1 {
            switch listing.haveLogic {
            case .one:
                return "\(count)点からどれか"
            case .all:
                return "\(count)点セット"
            case .atLeast:
                return "\(listing.haveMinimumCount)点以上"
            }
        }
        return haveItems.first?.title ?? "グッズ"
    }
}

struct IndividualListingPanelEditButton: View {
    var accessibilityLabel: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "pencil")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(MegrumTheme.lavender, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.70), lineWidth: 1)
                }
                .shadow(color: MegrumTheme.ink.opacity(0.14), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
