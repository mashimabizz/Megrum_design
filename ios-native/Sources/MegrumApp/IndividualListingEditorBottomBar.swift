import MegrumCore
import MegrumDesign
import SwiftUI

enum IndividualListingEditorBottomBarPresentation {
    static let addOptionTitle = "選択肢に追加"
    static let selectAllVisibleTitle = "すべて登録"
    static let deselectAllVisibleTitle = "すべて解除"

    static func selectedCountTitle(_ count: Int) -> String {
        "選択中\(count)件"
    }
}

struct IndividualListingEditorBottomBar: View {
    var step: IndividualListingEditorStep
    var havesTab: IndividualListingHavesStep.Tab
    var optionKind: IndividualListingOptionKind
    var selectedHaveCount: Int
    var selectedWishCount: Int
    var stagedOptionCount: Int
    @Binding var haveLogic: ListingLogic
    @Binding var haveMinimumCount: Int
    @Binding var wishLogic: ListingLogic
    @Binding var wishMinimumCount: Int
    var usesConditionLogicChoice: Bool
    var showsSelectAllVisibleButton: Bool
    var selectAllVisibleButtonTitle: String
    var canSelectAllVisible: Bool
    var isDisabled: Bool
    var isSaving: Bool
    var onBack: () -> Void
    var onSelectAllVisible: () -> Void
    var onAddOption: () -> Void
    var onPrimary: () -> Void

    var body: some View {
        VStack(spacing: 13) {
            if showsLogicControls {
                IndividualListingBottomBarLogicControls(
                    logic: logicBinding,
                    minimumCount: minimumCountBinding,
                    selectedCount: displayedSelectedCount,
                    allowsMinimumLogic: allowsMinimumLogic,
                    showsSingleChoiceButton: showsSingleChoiceButton,
                    allTitle: logicAllTitle
                )
            }

            IndividualListingBottomBarActionRow(
                step: step,
                showsSelectAllVisibleButton: showsSelectAllVisibleButton,
                selectAllVisibleButtonTitle: selectAllVisibleButtonTitle,
                canSelectAllVisible: canSelectAllVisible,
                isDisabled: isDisabled,
                isSaving: isSaving,
                onBack: onBack,
                onSelectAllVisible: onSelectAllVisible,
                onAddOption: onAddOption,
                onPrimary: onPrimary
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22, style: .continuous)
                .fill(.white.opacity(0.92))
                .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 18, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var showsLogicControls: Bool {
        if step == .haves {
            return havesTab == .goods && selectedHaveCount > 1
        }
        if step == .options {
            return (optionKind == .wish && selectedWishCount > 1)
                || (optionKind == .condition && usesConditionLogicChoice)
        }
        return false
    }

    private var displayedSelectedCount: Int {
        step == .haves ? selectedHaveCount : selectedWishCount
    }

    private var logicBinding: Binding<ListingLogic> {
        step == .haves ? $haveLogic : $wishLogic
    }

    private var minimumCountBinding: Binding<Int> {
        step == .haves ? $haveMinimumCount : $wishMinimumCount
    }

    private var allowsMinimumLogic: Bool {
        if step == .haves {
            return havesTab == .goods && selectedHaveCount >= 2
        }
        return step == .options && optionKind == .wish && selectedWishCount >= 2
    }

    private var showsSingleChoiceButton: Bool {
        step == .options && optionKind == .condition
    }

    private var logicAllTitle: String {
        step == .haves ? "すべて譲る" : (optionKind == .condition ? "全部ほしい" : "すべて希望")
    }
}

private struct IndividualListingBottomBarLogicControls: View {
    @Binding var logic: ListingLogic
    @Binding var minimumCount: Int
    var selectedCount: Int
    var allowsMinimumLogic: Bool
    var showsSingleChoiceButton: Bool
    var allTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(IndividualListingEditorBottomBarPresentation.selectedCountTitle(selectedCount))
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .layoutPriority(1)
            IndividualListingFooterLogicSegment(
                selection: $logic,
                minimumCount: $minimumCount,
                selectedCount: selectedCount,
                allowsMinimumLogic: allowsMinimumLogic,
                showsSingleChoiceButton: showsSingleChoiceButton,
                allTitle: allTitle
            )
            .frame(maxWidth: .infinity)
        }
    }
}

private struct IndividualListingBottomBarActionRow: View {
    var step: IndividualListingEditorStep
    var showsSelectAllVisibleButton: Bool
    var selectAllVisibleButtonTitle: String
    var canSelectAllVisible: Bool
    var isDisabled: Bool
    var isSaving: Bool
    var onBack: () -> Void
    var onSelectAllVisible: () -> Void
    var onAddOption: () -> Void
    var onPrimary: () -> Void

    @ViewBuilder
    var body: some View {
        if step == .exchange {
            HStack(spacing: 15) {
                IndividualListingEditorBackBottomBarButton(action: onBack)

                primaryButton(title: "保存する")
            }
        } else if step == .options {
            HStack(spacing: 10) {
                if showsSelectAllVisibleButton {
                    selectAllVisibleButton
                }
                secondaryAddOptionButton
                primaryButton(title: "交換条件へ進む")
            }
        } else {
            HStack(spacing: 10) {
                if showsSelectAllVisibleButton {
                    selectAllVisibleButton
                }
                primaryButton(title: "この内容で次へ")
            }
        }
    }

    private var selectAllVisibleButton: some View {
        IndividualListingEditorSelectAllVisibleButton(
            title: selectAllVisibleButtonTitle,
            canSelectAllVisible: canSelectAllVisible,
            action: onSelectAllVisible
        )
    }

    private var secondaryAddOptionButton: some View {
        IndividualListingEditorAddOptionButton(
            width: secondaryAddOptionButtonWidth,
            isDisabled: isDisabled,
            action: onAddOption
        )
    }

    private var secondaryAddOptionButtonWidth: CGFloat {
        showsSelectAllVisibleButton ? 116 : 136
    }

    private func primaryButton(title: String) -> some View {
        IndividualListingEditorPrimaryBottomBarButton(
            title: title,
            isSaving: isSaving,
            isDisabled: isDisabled,
            action: onPrimary
        )
    }
}
