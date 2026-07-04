import Foundation
import MegrumDesign
import SwiftUI

struct HomeOtherExchangeRows<LeadingContent: View>: View {
    var addedCandidateIDs: Set<UUID> = []
    var excludedGoodsIDs: Set<UUID> = []
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void
    var showsLeadingDivider: Bool = false
    private let listingHitPayloadsOverride: [HomeExtraHitPayload]?
    private let wishHitPayloadsOverride: [HomeExtraHitPayload]?
    private let leadingContent: LeadingContent

    init(
        addedCandidateIDs: Set<UUID> = [],
        excludedGoodsIDs: Set<UUID> = [],
        listingHitPayloads: [HomeExtraHitPayload]? = nil,
        wishHitPayloads: [HomeExtraHitPayload]? = nil,
        onOpenNestedSheet: @escaping (HomeDiscoverySheet) -> Void,
        showsLeadingDivider: Bool = false,
        @ViewBuilder leadingContent: () -> LeadingContent
    ) {
        self.addedCandidateIDs = addedCandidateIDs
        self.excludedGoodsIDs = excludedGoodsIDs
        self.onOpenNestedSheet = onOpenNestedSheet
        self.showsLeadingDivider = showsLeadingDivider
        self.listingHitPayloadsOverride = listingHitPayloads
        self.wishHitPayloadsOverride = wishHitPayloads
        self.leadingContent = leadingContent()
    }

    private var listingHitPayloads: [HomeExtraHitPayload] {
        HomeOtherExchangePolicy.visiblePayloads(
            rawListingHitPayloads,
            excluding: excludedGoodsIDs
        )
    }

    private var wishHitPayloads: [HomeExtraHitPayload] {
        HomeOtherExchangePolicy.visibleWishPayloads(
            rawWishHitPayloads,
            excluding: excludedGoodsIDs,
            listingHitPayloads: listingHitPayloads
        )
    }

    private var rawListingHitPayloads: [HomeExtraHitPayload] {
        listingHitPayloadsOverride ?? []
    }

    private var rawWishHitPayloads: [HomeExtraHitPayload] {
        wishHitPayloadsOverride ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("他にも交換できそうなもの")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            VStack(alignment: .leading, spacing: 16) {
                leadingContent

                if showsLeadingDivider && (!listingHitPayloads.isEmpty || !wishHitPayloads.isEmpty) {
                    Divider().opacity(0.45)
                }

                if !listingHitPayloads.isEmpty {
                    imageSection(
                        title: "相手の個別募集にヒット",
                        color: MegrumTheme.pink,
                        payloads: listingHitPayloads
                    )
                }

                if !listingHitPayloads.isEmpty && !wishHitPayloads.isEmpty {
                    Divider().opacity(0.45)
                }

                if !wishHitPayloads.isEmpty {
                    imageSection(
                        title: "ほしいものでHit",
                        color: MegrumTheme.sky,
                        payloads: wishHitPayloads
                    )
                }

                if !showsLeadingDivider && listingHitPayloads.isEmpty && wishHitPayloads.isEmpty {
                    HomeOtherExchangeEmptyPanel()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private func imageSection(
        title: String,
        color: Color,
        payloads: [HomeExtraHitPayload]
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(color)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(payloads) { payload in
                        HomeOtherExchangeThumbnailButton(
                            goods: payload.goods,
                            selected: addedCandidateIDs.contains(payload.goods.id)
                        ) {
                            onOpenNestedSheet(payload.nestedSheet)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

extension HomeOtherExchangeRows where LeadingContent == EmptyView {
    init(
        addedCandidateIDs: Set<UUID> = [],
        excludedGoodsIDs: Set<UUID> = [],
        onOpenNestedSheet: @escaping (HomeDiscoverySheet) -> Void
    ) {
        self.init(
            addedCandidateIDs: addedCandidateIDs,
            excludedGoodsIDs: excludedGoodsIDs,
            onOpenNestedSheet: onOpenNestedSheet,
            showsLeadingDivider: false
        ) {
            EmptyView()
        }
    }
}
