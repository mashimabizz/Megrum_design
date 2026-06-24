import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ListingSelectableImageTile: View {
    var imageURL: URL?
    var title: String
    var isSelected: Bool

    var body: some View {
        ListingGoodsImage(url: imageURL, title: title, cornerRadius: 13)
            .aspectRatio(0.78, contentMode: .fit)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(MegrumTheme.lavender, in: Circle())
                    .overlay {
                        Circle().stroke(.white, lineWidth: 2)
                    }
                    .opacity(isSelected ? 1 : 0)
                    .padding(8)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(MegrumTheme.lavender, lineWidth: 2.5)
                }
            }
    }
}

struct IndividualListingEditorContent: View {
    @Binding var draft: IndividualListingDraft
    @Binding var havesTab: IndividualListingHavesStep.Tab
    @Binding var haveSelectionFilter: IndividualListingSelectionFilter
    @Binding var wishSelectionFilter: IndividualListingSelectionFilter
    var step: IndividualListingEditorStep
    var inventory: [GoodsItem]
    var wishes: [WishItem]
    var genres: [OshiGenre]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    var stepValidationMessage: String?
    var optionReviewCount: Int
    var onBack: () -> Void
    var onSelectStep: (IndividualListingEditorStep) -> Void
    var onShowOptionReview: () -> Void
    var onToggleHave: (GoodsItem) -> Void
    var onToggleWish: (WishItem) -> Void
    var onLoadCharacters: (OshiGroup) -> Void
    var onCreateOshiRequest: (OshiRequestSheetPayload) -> Void

    var body: some View {
        VStack(spacing: 0) {
            IndividualListingEditorHeader(
                step: step,
                title: draft.navigationTitle,
                showsOptionReviewButton: step == .options,
                optionReviewCount: optionReviewCount,
                onShowOptionReview: onShowOptionReview,
                onSelectStep: onSelectStep,
                onBack: onBack
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    stepContent

                    if let stepValidationMessage {
                        Text(stepValidationMessage)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 126)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .haves:
            IndividualListingHavesStep(
                inventory: inventory,
                selectedIDs: draft.selectedHaveIDs,
                filter: $haveSelectionFilter,
                groups: groups,
                goodsTypes: goodsTypes,
                selectedTab: $havesTab,
                cashPricingMode: $draft.haveCashPricingMode,
                cashAmount: $draft.haveCashAmount,
                onToggle: onToggleHave
            )
        case .options:
            IndividualListingOptionsStep(
                optionKind: Binding(
                    get: { draft.optionKind },
                    set: { draft.setOptionKind($0) }
                ),
                inventory: inventory,
                wishes: wishes,
                selectedWishIDs: draft.selectedWishIDs,
                selectedWishLogic: $draft.wishLogic,
                wishFilter: $wishSelectionFilter,
                genres: genres,
                groups: groups,
                characters: characters,
                goodsTypes: goodsTypes,
                selectedConditionGroupID: Binding(
                    get: { draft.conditionGroupID },
                    set: { draft.setConditionGroupID($0) }
                ),
                selectedConditionMemberIDs: $draft.conditionMemberIDs,
                excludesSelectedConditionMembers: Binding(
                    get: { draft.excludesSelectedConditionMembers },
                    set: { draft.setExcludesSelectedConditionMembers($0) }
                ),
                selectedConditionGoodsTypeID: $draft.conditionGoodsTypeID,
                selectedConditionTagNames: $draft.conditionTagNames,
                conditionQuantity: $draft.conditionQuantity,
                cashPricingMode: $draft.cashPricingMode,
                cashAmount: $draft.cashAmount,
                onToggleWish: onToggleWish,
                onToggleConditionMember: { draft.toggleConditionMember($0) },
                onLoadCharacters: onLoadCharacters,
                onCreateOshiRequest: onCreateOshiRequest
            )
        case .exchange:
            IndividualListingExchangeStep(
                handoffMethod: $draft.handoffMethod,
                localPrefecture: $draft.localPrefecture,
                localPlaceMemo: $draft.localPlaceMemo,
                localSchedule: $draft.localSchedule,
                shippingFee: $draft.shippingFee,
                shippingDays: $draft.shippingDays,
                acceptsOutsideCondition: $draft.acceptsOutsideCondition
            )
        }
    }
}

struct IndividualListingEditorHeader: View {
    var step: IndividualListingEditorStep
    var title: String
    var showsOptionReviewButton: Bool
    var optionReviewCount: Int
    var onShowOptionReview: () -> Void
    var onSelectStep: (IndividualListingEditorStep) -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                if showsOptionReviewButton {
                    Button(action: onShowOptionReview) {
                        HStack(spacing: 4) {
                            Text("選択肢を確認")
                            if optionReviewCount > 0 {
                                Text("\(optionReviewCount)")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 18, minHeight: 18)
                                    .background(MegrumTheme.lavender, in: Circle())
                            }
                        }
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .padding(.horizontal, 10)
                        .frame(height: 34)
                        .background(.white.opacity(0.92), in: Capsule())
                        .overlay {
                            Capsule()
                                .strokeBorder(MegrumTheme.lavender.opacity(0.22), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            HStack(spacing: 12) {
                Text("\(step.rawValue)")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text("/3")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                ForEach(IndividualListingEditorStep.allCases, id: \.id) { item in
                    Button {
                        onSelectStep(item)
                    } label: {
                        Color.clear
                            .frame(width: 22, height: 22)
                            .overlay {
                                Circle()
                                    .fill(item == step ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.22))
                                    .frame(width: item == step ? 16 : 9, height: item == step ? 16 : 9)
                            }
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.title)
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 40)
            .background(.white.opacity(0.92), in: Capsule())
            .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 10, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}
