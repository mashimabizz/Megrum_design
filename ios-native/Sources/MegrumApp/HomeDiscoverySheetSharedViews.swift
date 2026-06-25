import MegrumDesign
import SwiftUI

struct HomeSelectedGoodsHeader: View {
    var title: String = "選んだグッズ"
    var goods: HomeMockGoods
    var conditionTags: HomeConditionTagSet
    var exchangeSummary: HomeDiscoveryOwnerExchangeSummary?
    var listingNote: String?
    var listingDetail: HomeIndividualListingDetailContext?
    var onOpenOwnerProfile: (UUID) -> Void = { _ in }
    @State private var presentedListingDetail: HomeIndividualListingDetailContext?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if usesOwnerSummaryAsHeader, let ownerSummary = goods.ownerSummary {
                HomeUserSummary(owner: ownerSummary, onOpenProfile: onOpenOwnerProfile)
            } else {
                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }

            HStack(alignment: .top, spacing: 20) {
                HomeSelectedGoodsSingleCard(goods: goods, conditionTags: conditionTags)
                    .frame(width: 136, height: 162)

                VStack(alignment: .leading, spacing: 10) {
                    if !usesOwnerSummaryAsHeader, let ownerSummary = goods.ownerSummary {
                        HomeUserSummary(owner: ownerSummary, onOpenProfile: onOpenOwnerProfile)
                    }

                    if let exchangeSummary {
                        HomeExchangeMethodBlock(summary: exchangeSummary)
                    }

                    HomePaymentBox(summaryText: goods.ownerPaymentSummaryText)

                    if let listingDetail {
                        HomeListingDetailButton {
                            presentedListingDetail = listingDetail
                        }
                    }
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let listingNote = listingNote?.nilIfBlank {
                HomeListingNoteBox(note: listingNote)
            }
        }
        .sheet(item: $presentedListingDetail) { detail in
            HomeIndividualListingDetailPopup(detail: detail)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var usesOwnerSummaryAsHeader: Bool {
        title == "選んだグッズ"
    }
}

struct HomeSelectedGoodsSingleCard: View {
    var goods: HomeMockGoods
    var conditionTags: HomeConditionTagSet

    var body: some View {
        HomeDiscoveryGoodsCard(
            goods: goods,
            goodsCondition: conditionTags.goods,
            exchangeCondition: conditionTags.exchange,
            paymentCondition: conditionTags.payment,
            prominence: 1,
            showsConditionOverlay: false
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("選んだグッズ")
    }
}

private struct HomeListingNoteBox: View {
    var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: "text.alignleft")
                Text("メモ")
            }
            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)

            Text(note)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MegrumTheme.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct HomeListingDetailButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                Text("個別募集の詳細を見る")
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }
            .foregroundStyle(MegrumTheme.lavender)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("個別募集の詳細を見る")
    }
}
