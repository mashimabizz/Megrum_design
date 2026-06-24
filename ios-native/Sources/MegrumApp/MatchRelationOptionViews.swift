import MegrumCore
import MegrumDesign
import SwiftUI

struct MatchRelationOwnerLabel: View {
    var title: String
    var color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(2)
    }
}

struct MatchRelationOptionList: View {
    var detail: MatchRelationListingDetail
    var viewpoint: MatchRelationViewpoint
    var partnerHandle: String
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var onOpenPopup: (MatchRelationWishPopupTarget) -> Void

    private var visibleOptions: [MatchRelationOption] {
        detail.options
            .filter { !$0.option.isCashOffer }
            .filter { option in option.wishes.contains { !$0.candidates.isEmpty } }
            .sorted { lhs, rhs in
                if lhs.matched != rhs.matched {
                    return lhs.matched && !rhs.matched
                }
                return lhs.option.position < rhs.option.position
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if visibleOptions.isEmpty {
                Text("候補なし")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .padding(.vertical, 14)
            } else {
                ForEach(visibleOptions) { option in
                    MatchRelationOptionGroup(
                        listingID: detail.id,
                        viewpoint: viewpoint,
                        partnerHandle: partnerHandle,
                        option: option,
                        fallbackHave: MatchRelationComposer.defaultFallbackHave(
                            for: detail,
                            highlightedItemID: highlightedItemID
                        ),
                        highlightedItemID: highlightedItemID,
                        selectedCandidateIDs: selectedCandidateIDs,
                        onOpenPopup: onOpenPopup
                    )
                }
            }
        }
    }
}

private struct MatchRelationOptionGroup: View {
    var listingID: UUID
    var viewpoint: MatchRelationViewpoint
    var partnerHandle: String
    var option: MatchRelationOption
    var fallbackHave: MatchRelationHave?
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var onOpenPopup: (MatchRelationWishPopupTarget) -> Void

    private var visibleWishes: [MatchRelationWish] {
        option.wishes.filter { !$0.candidates.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Text("#\(option.option.position)")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(option.option.logic == .all ? .white : MegrumTheme.lavender)
                    .padding(.horizontal, 6)
                    .frame(height: 18)
                    .background(option.option.logic == .all ? MegrumTheme.lavender : .white, in: Capsule())
                    .overlay {
                        if option.option.logic != .all {
                            Capsule()
                                .strokeBorder(MegrumTheme.lavender.opacity(0.34), lineWidth: 1)
                        }
                    }
                Text(optionLogicText)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
            }

            if fallbackHave != nil {
                ForEach(visibleWishes) { wish in
                    MatchRelationWishRow(
                        wish: wish,
                        exchangeType: option.option.exchangeType,
                        highlightedItemID: highlightedItemID,
                        selectedCandidateIDs: selectedCandidateIDs,
                        candidateOwnerTitle: MatchRelationPopupCopy.candidateOwnerTitle(
                            viewpoint: viewpoint,
                            partnerHandle: partnerHandle
                        ),
                        onOpen: {
                            if let fallbackHave {
                                onOpenPopup(
                                    MatchRelationComposer.popupTarget(
                                        listingID: listingID,
                                        viewpoint: viewpoint,
                                        option: option,
                                        wish: wish,
                                        fallbackHave: fallbackHave
                                    )
                                )
                            }
                        }
                    )
                }
            }
        }
        .padding(6)
        .background(
            (option.option.logic == .all ? MegrumTheme.lavender.opacity(0.03) : MegrumTheme.lavender.opacity(0.02)),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    option.option.logic == .all ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.34),
                    style: StrokeStyle(lineWidth: option.option.logic == .all ? 2 : 1, dash: option.option.logic == .all ? [] : [5, 4])
                )
        }
    }

    private var optionLogicText: String {
        switch option.option.logic {
        case .all:
            return "セット（AND）"
        case .one:
            return "いずれか（OR）"
        case .atLeast:
            return ListingLogic.minimumCountTitle(option.option.minimumCount)
        }
    }
}

private struct MatchRelationWishRow: View {
    var wish: MatchRelationWish
    var exchangeType: IndividualListingExchangeType
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var candidateOwnerTitle: String
    var onOpen: () -> Void

    private var selectedCandidates: [MatchRelationCandidate] {
        MatchRelationComposer.selectedCandidates(
            for: wish,
            selectedCandidateIDs: selectedCandidateIDs
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onOpen) {
                HStack(spacing: 9) {
                    MatchRelationGoodsThumbnail(item: wish.item, size: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 3) {
                            Text("🎯")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                            Text(wish.item.title)
                                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink)
                                .lineLimit(1)
                        }
                        Text("\(exchangeType.displayName) / 候補 \(wish.candidates.count) 件")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Text("×\(wish.quantity)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(MegrumTheme.lavender)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !selectedCandidates.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("選択中")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    HStack(spacing: -8) {
                        ForEach(selectedCandidates) { candidate in
                            MatchRelationGoodsThumbnail(item: candidate.item, size: 34)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(
                                            candidate.item.id == highlightedItemID ? MegrumTheme.pink.opacity(0.9) : .white,
                                            lineWidth: 1.5
                                        )
                                }
                        }
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(MegrumTheme.ink.opacity(0.04))
                        .frame(height: 1)
                }
            }
        }
        .accessibilityHint("\(candidateOwnerTitle)をシートで開き、候補グッズをタップして選択します")
        .background(MatchRelationVisual.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.04), lineWidth: 1)
        }
    }
}
