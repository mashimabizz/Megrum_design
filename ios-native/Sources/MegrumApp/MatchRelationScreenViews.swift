import MegrumCore
import MegrumDesign
import SwiftUI

struct MatchRelationLoadingPanel: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
                .tint(MegrumTheme.lavender)
            Text("マイグッズと個別募集を確認しています")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct MatchRelationSectionHeader: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MatchRelationContent: View {
    var isLoading: Bool
    var ownDetails: [MatchRelationListingDetail]
    var partnerDetails: [MatchRelationListingDetail]
    var partnerHandle: String
    var highlightedItemID: UUID
    var selectedCandidateIDsByListingID: [UUID: Set<UUID>]
    var selectedHaveIDsByListingID: [UUID: Set<UUID>]
    var targetItem: GoodsItem
    var simpleSenderItems: [GoodsItem]
    var showsSummary: Bool
    var summarySenderItems: [GoodsItem]
    var summaryReceiverItems: [GoodsItem]
    var onToggleHave: (UUID, UUID) -> Void
    var onOpenPopup: (MatchRelationWishPopupTarget) -> Void

    private var showsSimplePanel: Bool {
        ownDetails.isEmpty && partnerDetails.isEmpty && !isLoading
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if isLoading {
                MatchRelationLoadingPanel()
            }

            if !ownDetails.isEmpty {
                MatchRelationSectionHeader(title: "あなたの個別募集")
                relationCards(ownDetails)
            }

            if !partnerDetails.isEmpty {
                MatchRelationSectionHeader(title: "@\(partnerHandle) の個別募集")
                relationCards(partnerDetails)
            }

            if showsSimplePanel {
                MatchRelationSimplePanel(
                    targetItem: targetItem,
                    senderItems: simpleSenderItems
                )
            }

            if showsSummary {
                MatchRelationSummaryPanel(
                    senderItems: summarySenderItems,
                    receiverItems: summaryReceiverItems
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 112)
    }

    @ViewBuilder
    private func relationCards(_ details: [MatchRelationListingDetail]) -> some View {
        VStack(spacing: 14) {
            ForEach(Array(details.enumerated()), id: \.element.id) { index, detail in
                MatchRelationTreeCard(
                    detail: detail,
                    index: index,
                    partnerHandle: partnerHandle,
                    highlightedItemID: highlightedItemID,
                    selectedCandidateIDs: selectedCandidateIDsByListingID[detail.id] ?? [],
                    selectedHaveIDs: selectedHaveIDsByListingID[detail.id] ?? [],
                    onToggleHave: { haveID in
                        onToggleHave(detail.id, haveID)
                    },
                    onOpenPopup: onOpenPopup
                )
            }
        }
    }
}

struct MatchRelationTreeCard: View {
    var detail: MatchRelationListingDetail
    var index: Int
    var partnerHandle: String
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var selectedHaveIDs: Set<UUID>
    var onToggleHave: (UUID) -> Void
    var onOpenPopup: (MatchRelationWishPopupTarget) -> Void

    private var cashOption: IndividualListingWishOption? {
        detail.listing.options.first(where: \.isCashOffer)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("個別募集\(index + 1)")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text("選択肢 \(detail.selectableOptionCount) 件")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                Spacer()
                if let cashOption {
                    Text(cashText(cashOption))
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
                }
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    MatchRelationOwnerLabel(
                        title: detail.isMyListing ? "@\(partnerHandle) が譲る候補" : "@\(partnerHandle) が譲るもの",
                        color: MegrumTheme.pink
                    )
                    if detail.isMyListing {
                        MatchRelationOptionList(
                            detail: detail,
                            viewpoint: .mine,
                            partnerHandle: partnerHandle,
                            highlightedItemID: highlightedItemID,
                            selectedCandidateIDs: selectedCandidateIDs,
                            onOpenPopup: onOpenPopup
                        )
                    } else {
                        MatchRelationHaveList(
                            detail: detail,
                            highlightedItemID: highlightedItemID,
                            selectedHaveIDs: selectedHaveIDs,
                            onToggleHave: onToggleHave
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 10) {
                    MatchRelationOwnerLabel(
                        title: detail.isMyListing ? "あなたが譲るもの" : "あなたが譲れる候補",
                        color: MegrumTheme.lavender
                    )
                    if detail.isMyListing {
                        MatchRelationHaveList(
                            detail: detail,
                            highlightedItemID: highlightedItemID,
                            selectedHaveIDs: selectedHaveIDs,
                            onToggleHave: onToggleHave
                        )
                    } else {
                        MatchRelationOptionList(
                            detail: detail,
                            viewpoint: .partner,
                            partnerHandle: partnerHandle,
                            highlightedItemID: highlightedItemID,
                            selectedCandidateIDs: selectedCandidateIDs,
                            onOpenPopup: onOpenPopup
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.04), radius: 8, y: 2)
    }

    private func cashText(_ option: IndividualListingWishOption) -> String {
        TradeAmountFormatter.fixedPrice(amount: option.cashAmount, fallback: "定価も可")
    }
}

private struct MatchRelationOwnerLabel: View {
    var title: String
    var color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(2)
    }
}

private struct MatchRelationOptionList: View {
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
                Text(option.option.logic == .all ? "セット（AND）" : "いずれか（OR）")
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

struct MatchRelationWishBottomSheet: View {
    var target: MatchRelationWishPopupTarget
    var partnerHandle: String
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var onToggleCandidate: (UUID) -> Void
    var onClose: () -> Void

    private var candidateAccent: Color {
        target.viewpoint == .mine ? MegrumTheme.pink : MegrumTheme.lavender
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.56)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 8) {
                    Text("🎯")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(target.wish.item.title)
                            .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)
                        Text(MatchRelationPopupCopy.subtitle(
                            quantity: target.wish.quantity,
                            candidateCount: target.wish.candidates.count
                        ))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Button(action: onClose) {
                        Text("×")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(width: 28, height: 28)
                            .background(MegrumTheme.ink.opacity(0.04), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(MatchRelationVisual.background)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(MegrumTheme.ink.opacity(0.04))
                        .frame(height: 1)
                }

                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .center, spacing: 0) {
                        MatchRelationGoodsThumbnail(item: target.wish.item, size: 104)
                        Text(target.exchangeType.displayName)
                            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(MegrumTheme.lavender, in: Capsule())
                            .padding(.top, 7)
                        Text(MatchRelationPopupCopy.fallbackTitle(target.fallbackHave.item.title))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .padding(.top, 5)
                    }
                    .frame(width: 110, alignment: .top)

                    VStack(alignment: .leading, spacing: 9) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            MatchRelationMiniAvatar(
                                title: target.viewpoint == .mine ? "@\(partnerHandle)" : "あなた",
                                color: candidateAccent
                            )
                            Text(MatchRelationPopupCopy.candidateOwnerTitle(
                                viewpoint: target.viewpoint,
                                partnerHandle: partnerHandle
                            ))
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(candidateAccent)
                                .lineLimit(1)
                            Text("（タップで選択）")
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                        }

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
                            alignment: .leading,
                            spacing: 6
                        ) {
                            ForEach(target.wish.candidates) { candidate in
                                MatchRelationPopupCandidateButton(
                                    candidate: candidate,
                                    isSelected: selectedCandidateIDs.contains(candidate.item.id),
                                    isHighlighted: candidate.item.id == highlightedItemID,
                                    onTap: {
                                        onToggleCandidate(candidate.item.id)
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .padding(12)

                Button(action: onClose) {
                    Text("戻る")
                        .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.top, 2)
                .padding(.bottom, 22)
            }
            .frame(maxWidth: .infinity)
            .background(.white, in: UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
            .shadow(color: .black.opacity(0.25), radius: 40, y: -10)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct MatchRelationMiniAvatar: View {
    var title: String
    var color: Color

    var body: some View {
        Text(title.prefix(1).uppercased())
            .font(.system(size: 8, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 16, height: 16)
            .background(color, in: Circle())
    }
}

private struct MatchRelationPopupCandidateButton: View {
    var candidate: MatchRelationCandidate
    var isSelected: Bool
    var isHighlighted: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .center, spacing: 0) {
                    MatchRelationGoodsThumbnail(item: candidate.item, size: 56)

                    Text(candidate.item.title)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .frame(maxWidth: 64)
                        .padding(.top, 3)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                if isHighlighted {
                    Text("選択元")
                        .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(MegrumTheme.pink, in: Capsule())
                        .offset(x: -8, y: -8)
                }

                if isSelected {
                    Text("✓")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(MegrumTheme.lavender, in: Circle())
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                        .offset(x: 8, y: -8)
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 82, alignment: .top)
            .background(
                isHighlighted
                    ? Color(red: 1, green: 247 / 255, blue: 251 / 255)
                    : (isSelected ? MegrumTheme.lavender.opacity(0.08) : .white),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isHighlighted ? MegrumTheme.pink : (isSelected ? MegrumTheme.lavender : .clear),
                        lineWidth: isHighlighted || isSelected ? 2 : 0
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

struct MatchRelationBottomBar: View {
    var senderCount: Int
    var receiverCount: Int
    var isEnabled: Bool
    var showsReset: Bool
    var onSecondary: () -> Void
    var onStart: () -> Void

    var body: some View {
        let totalSelectionCount = max(senderCount, receiverCount)
        HStack(spacing: 10) {
            Button(action: onSecondary) {
                Text(MatchRelationBottomBarCopy.secondaryTitle(showsReset: showsReset))
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 92)
                    .frame(height: 54)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            Button(action: onStart) {
                Text(
                    MatchRelationBottomBarCopy.primaryTitle(
                        isEnabled: isEnabled,
                        showsReset: showsReset,
                        totalSelectionCount: totalSelectionCount
                    )
                )
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(MegrumTheme.lavender.opacity(isEnabled ? 1 : 0.42), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: MegrumTheme.lavender.opacity(isEnabled ? 0.24 : 0), radius: 14, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MegrumTheme.ink.opacity(0.08))
                .frame(height: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 12, y: -4)
    }
}

struct MatchRelationHeader: View {
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(width: 56, height: 56)
                    .background(.white, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            Text("関係図")
                .font(.system(size: 27, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MegrumTheme.ink.opacity(0.06))
                .frame(height: 1)
        }
    }
}

enum MatchRelationVisual {
    static let background = Color(red: 0.984, green: 0.976, blue: 0.988)
}
