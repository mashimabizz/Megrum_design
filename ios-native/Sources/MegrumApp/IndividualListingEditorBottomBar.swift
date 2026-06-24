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
                logicControlRow
            }

            actionRow
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

    @ViewBuilder
    private var actionRow: some View {
        Group {
            if step == .exchange {
                HStack(spacing: 15) {
                    Button("戻る", action: onBack)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 132, height: 58)
                        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(MegrumTheme.lavender, lineWidth: 1.2)
                        }

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

    private var logicControlRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(IndividualListingEditorBottomBarPresentation.selectedCountTitle(displayedSelectedCount))
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .layoutPriority(1)
            IndividualListingFooterLogicSegment(
                selection: logicBinding,
                minimumCount: minimumCountBinding,
                selectedCount: displayedSelectedCount,
                allowsMinimumLogic: allowsMinimumLogic,
                showsSingleChoiceButton: showsSingleChoiceButton,
                allTitle: step == .haves ? "すべて譲る" : (optionKind == .condition ? "全部ほしい" : "すべて希望")
            )
            .frame(maxWidth: .infinity)
        }
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

    private func primaryButton(title: String) -> some View {
        Button(action: onPrimary) {
            Group {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [MegrumTheme.lavender, MegrumTheme.sky],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.46 : 1)
    }

    private var selectAllVisibleButton: some View {
        Button(action: onSelectAllVisible) {
            Text(selectAllVisibleButtonTitle)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(width: 104, height: 56)
                .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.32), lineWidth: 1.2)
                }
        }
        .buttonStyle(.plain)
        .disabled(!canSelectAllVisible)
        .opacity(canSelectAllVisible ? 1 : 0.42)
        .accessibilityLabel("表示中の項目を\(selectAllVisibleButtonTitle)")
    }

    private var secondaryAddOptionButton: some View {
        Button(action: onAddOption) {
            Text(IndividualListingEditorBottomBarPresentation.addOptionTitle)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(width: secondaryAddOptionButtonWidth, height: 56)
                .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.42), lineWidth: 1.2)
                }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.46 : 1)
    }

    private var secondaryAddOptionButtonWidth: CGFloat {
        showsSelectAllVisibleButton ? 116 : 136
    }
}

private struct IndividualListingFooterLogicSegment: View {
    @Binding var selection: ListingLogic
    @Binding var minimumCount: Int
    var selectedCount: Int
    var allowsMinimumLogic: Bool
    var showsSingleChoiceButton: Bool
    var allTitle: String
    @State private var showsMinimumPicker = false

    var body: some View {
        HStack(spacing: 0) {
            if showsSingleChoiceButton {
                logicButton(.one, title: "どれか1つだけ")
            }
            if allowsMinimumLogic {
                logicButton(.atLeast, title: minimumTitle)
            }
            logicButton(.all, title: allTitle)
        }
        .padding(3)
        .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
        }
    }

    private func logicButton(_ logic: ListingLogic, title: String) -> some View {
        let button = Button {
            withAnimation(.smooth(duration: 0.18)) {
                if logic == .atLeast {
                    selection = .atLeast
                    showsMinimumPicker = true
                } else {
                    selection = logic
                }
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(selection == logic ? .white : MegrumTheme.ink.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background {
                    if selection == logic {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(MegrumTheme.lavender)
                    }
                }
        }
        .buttonStyle(.plain)

        return Group {
            if logic == .atLeast {
                button
                    .popover(isPresented: $showsMinimumPicker, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
                        minimumPicker
                    }
            } else {
                button
            }
        }
    }

    private var minimumTitle: String {
        ListingLogic.minimumCountTitle(minimumCount)
    }

    private var minimumPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("何個以上にしますか？")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            ForEach(minimumChoices, id: \.self) { count in
                Button {
                    minimumCount = count
                    selection = .atLeast
                    showsMinimumPicker = false
                } label: {
                    HStack(spacing: 8) {
                        Text(ListingLogic.minimumCountTitle(count))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Spacer(minLength: 0)
                        if selection == .atLeast && minimumCount == count {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .black))
                        }
                    }
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(minWidth: 142, alignment: .leading)
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .background(
                        selection == .atLeast && minimumCount == count
                            ? MegrumTheme.lavender.opacity(0.12)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .presentationCompactAdaptation(.popover)
    }

    private var minimumChoices: [Int] {
        guard selectedCount >= 2 else {
            return []
        }
        return Array(1...selectedCount)
    }
}
