import MegrumCore
import SwiftUI

struct IndividualListingEditorContent: View {
    @Binding var draft: IndividualListingDraft
    @Binding var havesTab: IndividualListingHavesStep.Tab
    @Binding var haveSelectionFilter: IndividualListingSelectionFilter
    @Binding var wishSelectionFilter: IndividualListingSelectionFilter
    var step: IndividualListingEditorStep
    var inventory: [GoodsItem]
    var wishes: [WishItem]
    var genres: [OshiGenre]
    var myOshiGroupIDs: Set<UUID> = []
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
                myOshiGroupIDs: myOshiGroupIDs,
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
                acceptsOutsideCondition: $draft.acceptsOutsideCondition,
                note: $draft.note
            )
        }
    }
}
