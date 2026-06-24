import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingEditorSheet: View {
    @ObservedObject var appState: MegrumAppState
    var onLocalEditSaved: ((IndividualListing) -> Void)?
    var onSaved: (() -> Void)?

    @Environment(\.dismiss) var dismiss
    @State var draft: IndividualListingDraft
    @State var step: IndividualListingEditorStep
    @State var havesTab: IndividualListingHavesStep.Tab = .goods
    @State var haveSelectionFilter = IndividualListingSelectionFilter()
    @State var wishSelectionFilter = IndividualListingSelectionFilter()
    @State var stagedOptionSummaries: [IndividualListingOptionReviewItem] = []
    @State var showsOptionReview = false
    @State var optionToastMessage: String?
    @State var optionToastID = UUID()
    @State var saveErrorMessage: String?

    init(
        appState: MegrumAppState,
        preselectedWishID: UUID? = nil,
        initialOptionKind: IndividualListingOptionKind? = nil,
        initialStep: IndividualListingEditorStep = .haves,
        onSaved: (() -> Void)? = nil
    ) {
        self.appState = appState
        self.onLocalEditSaved = nil
        self.onSaved = onSaved
        var draft = IndividualListingDraft(mode: .create(preselectedWishID: preselectedWishID))
        if let initialOptionKind {
            draft.setOptionKind(initialOptionKind)
        }
        self._draft = State(initialValue: draft)
        self._step = State(initialValue: initialOptionKind == nil ? initialStep : .options)
        self._havesTab = State(initialValue: draft.haveOfferKind == .cash ? .cash : .goods)
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
        let draft = IndividualListingDraft(mode: .edit(listing))
        self._draft = State(initialValue: draft)
        self._step = State(initialValue: initialStep)
        self._havesTab = State(initialValue: draft.haveOfferKind == .cash ? .cash : .goods)
    }

    var body: some View {
        IndividualListingEditorContent(
            draft: $draft,
            havesTab: $havesTab,
            haveSelectionFilter: $haveSelectionFilter,
            wishSelectionFilter: $wishSelectionFilter,
            step: step,
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
            onShowOptionReview: { showsOptionReview = true },
            onToggleHave: toggleHave,
            onToggleWish: toggleWish,
            onLoadCharacters: loadConditionCharacters,
            onCreateOshiRequest: createOshiRequest
        )
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .safeAreaInset(edge: .bottom) {
            IndividualListingEditorBottomBar(
                step: step,
                havesTab: havesTab,
                optionKind: draft.optionKind,
                selectedHaveCount: draft.selectedHaveIDs.count,
                selectedWishCount: draft.optionKind == .condition ? max(1, draft.conditionMemberIDs.count) : draft.selectedWishIDs.count,
                stagedOptionCount: stagedOptionSummaries.count,
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
            if let optionToastMessage {
                IndividualListingOptionAddedToast(message: optionToastMessage)
                    .padding(.bottom, 112)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showsOptionReview) {
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
                saveErrorMessage = nil
            }
        } message: {
            Text(saveErrorMessage ?? IndividualListingEditorSaveFailurePresentation.fallbackMessage)
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
        .onChange(of: havesTab) { _, newValue in
            draft.setHaveOfferKind(newValue == .cash ? .cash : .goods)
        }
    }
}
