import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingEditorSheet: View {
    @ObservedObject var appState: MegrumAppState
    var onLocalEditSaved: ((IndividualListing) -> Void)?
    var onSaved: (() -> Void)?
    var onCreatedListing: ((IndividualListing) -> Void)?

    @Environment(\.dismiss) var dismiss
    @State var draft: IndividualListingDraft
    @State var presentationState: IndividualListingEditorPresentationState

    init(
        appState: MegrumAppState,
        preselectedWishID: UUID? = nil,
        initialOptionKind: IndividualListingOptionKind? = nil,
        defaultExchangeSummary: IndividualListingExchangeSummary = IndividualListingExchangeSummary(),
        initialStep: IndividualListingEditorStep = .haves,
        onSaved: (() -> Void)? = nil,
        onCreatedListing: ((IndividualListing) -> Void)? = nil
    ) {
        self.appState = appState
        self.onLocalEditSaved = nil
        self.onSaved = onSaved
        self.onCreatedListing = onCreatedListing
        var draft = IndividualListingDraft(
            mode: .create(preselectedWishID: preselectedWishID),
            defaultExchangeSummary: defaultExchangeSummary
        )
        if let initialOptionKind {
            draft.setOptionKind(initialOptionKind)
        }
        let resolvedInitialStep = initialOptionKind == nil ? initialStep : .options
        _draft = State(initialValue: draft)
        _presentationState = State(
            initialValue: IndividualListingEditorPresentationState(
                initialStep: resolvedInitialStep,
                draft: draft
            )
        )
    }

    init(
        appState: MegrumAppState,
        editing listing: IndividualListing,
        initialStep: IndividualListingEditorStep = .haves,
        onSaved: (() -> Void)? = nil,
        onLocalEditSaved: @escaping (IndividualListing) -> Void
    ) {
        self.appState = appState
        self.onLocalEditSaved = onLocalEditSaved
        self.onSaved = onSaved
        self.onCreatedListing = nil
        var draft = IndividualListingDraft(mode: .edit(listing))
        var presentationState = IndividualListingEditorPresentationState(
            initialStep: initialStep,
            draft: draft
        )
        // 既存の選択肢は全て「追加済み」として読み込み、編集中の選択肢は
        // 空から始める。こうすると新しく選んだものは末尾に追加され、
        // 既存の選択肢（定価など）を上書きしない。
        let existingOptions = listing.options.sorted { $0.position < $1.position }
        for (index, option) in existingOptions.enumerated() {
            presentationState.appendStagedOption(
                IndividualListingOptionReviewItemFactory.make(
                    from: option,
                    title: "選択肢\(index + 1)",
                    wishes: appState.wishes,
                    groups: appState.oshiGroups,
                    goodsTypes: appState.goodsTypes,
                    characters: appState.oshiCharacters
                )
            )
        }
        if !existingOptions.isEmpty {
            draft.resetCurrentOptionSelection()
            draft.setOptionKind(.wish)
        }
        _draft = State(initialValue: draft)
        _presentationState = State(initialValue: presentationState)
    }

    var body: some View {
        IndividualListingEditorContent(
            draft: $draft,
            havesTab: $presentationState.havesTab,
            haveSelectionFilter: $presentationState.haveSelectionFilter,
            wishSelectionFilter: $presentationState.wishSelectionFilter,
            step: presentationState.step,
            inventory: appState.inventory,
            wishes: appState.wishes,
            genres: appState.oshiGenres,
            groups: appState.oshiGroups,
            characters: appState.oshiCharacters,
            goodsTypes: appState.goodsTypes,
            stepValidationMessage: stepValidationMessage,
            optionReviewCount: optionReviewItems.count,
            onBack: goBack,
            onSelectStep: selectStep,
            onShowOptionReview: { presentationState.showOptionReview() },
            onToggleHave: toggleHave,
            onToggleWish: toggleWish,
            onLoadCharacters: loadConditionCharacters,
            onCreateOshiRequest: createOshiRequest
        )
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .safeAreaInset(edge: .bottom) {
            IndividualListingEditorBottomBar(
                step: presentationState.step,
                havesTab: presentationState.havesTab,
                optionKind: draft.optionKind,
                selectedHaveCount: draft.selectedHaveIDs.count,
                selectedWishCount: draft.optionKind == .condition ? max(1, draft.conditionMemberIDs.count) : draft.selectedWishIDs.count,
                stagedOptionCount: presentationState.stagedOptionSummaries.count,
                haveLogic: haveLogicBinding,
                haveMinimumCount: haveMinimumCountBinding,
                wishLogic: wishLogicBinding,
                wishMinimumCount: wishMinimumCountBinding,
                usesConditionLogicChoice: draft.usesConditionLogicChoice,
                showsSelectAllVisibleButton: showsSelectAllVisibleButton,
                selectAllVisibleButtonTitle: selectAllVisibleButtonTitle,
                canSelectAllVisible: canSelectAllVisible,
                isDisabled: stepValidationMessage != nil || isSaving,
                isSaving: isSaving,
                onBack: goBack,
                onSelectAllVisible: selectAllVisibleItems,
                onAddOption: addCurrentOption,
                onPrimary: primaryAction
            )
        }
        .overlay(alignment: .bottom) {
            if let optionToastMessage = presentationState.optionToastMessage {
                IndividualListingOptionAddedToast(message: optionToastMessage)
                    .padding(.bottom, 112)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $presentationState.showsOptionReview) {
            IndividualListingOptionReviewSheet(
                items: optionReviewItems,
                onDelete: deleteOptionReviewItem
            )
        }
        .alert(
            IndividualListingEditorSaveFailurePresentation.title,
            isPresented: saveErrorBinding
        ) {
            Button("OK", role: .cancel) {
                presentationState.clearSaveError()
            }
        } message: {
            Text(presentationState.saveErrorMessage ?? IndividualListingEditorSaveFailurePresentation.fallbackMessage)
        }
        .onAppear {
            draft.ensureDefaultCondition(
                groupID: appState.oshiGroups.first?.id,
                goodsTypeID: appState.goodsTypes.first?.id
            )
            seedDraftDefaultsIfNeeded()
            loadSelectedConditionCharacters()
        }
        .onChange(of: appState.oshiGroups.map(\.id)) { _, _ in
            draft.ensureDefaultCondition(
                groupID: appState.oshiGroups.first?.id,
                goodsTypeID: appState.goodsTypes.first?.id
            )
            loadSelectedConditionCharacters()
        }
        .onChange(of: draft.conditionGroupID) { _, _ in
            loadSelectedConditionCharacters()
        }
        .onChange(of: presentationState.havesTab) { _, newValue in
            draft.setHaveOfferKind(newValue == .cash ? .cash : .goods)
        }
    }
}
