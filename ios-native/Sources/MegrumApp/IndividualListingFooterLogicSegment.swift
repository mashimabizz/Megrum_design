import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingFooterLogicSegment: View {
    @Binding var selection: ListingLogic
    @Binding var minimumCount: Int
    var selectedCount: Int
    var allowsMinimumLogic: Bool
    var showsSingleChoiceButton: Bool
    var allTitle: String
    @State private var presentationState = IndividualListingFooterLogicPresentationState()

    var body: some View {
        HStack(spacing: 0) {
            if showsSingleChoiceButton {
                IndividualListingLogicSegmentButton(
                    title: "どれか1つだけ",
                    isSelected: selection == .one
                ) {
                    selectLogic(.one)
                }
            }
            if allowsMinimumLogic {
                IndividualListingLogicSegmentButton(
                    title: minimumTitle,
                    isSelected: selection == .atLeast
                ) {
                    selectLogic(.atLeast)
                }
                .popover(isPresented: $presentationState.isShowingMinimumPicker, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
                    IndividualListingMinimumCountPicker(
                        selection: $selection,
                        minimumCount: $minimumCount,
                        choices: minimumChoices
                    ) {
                        presentationState.dismissMinimumPicker()
                    }
                }
            }
            IndividualListingLogicSegmentButton(
                title: allTitle,
                isSelected: selection == .all
            ) {
                selectLogic(.all)
            }
        }
        .padding(3)
        .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
        }
    }

    private var minimumTitle: String {
        ListingLogic.minimumCountTitle(minimumCount)
    }

    private var minimumChoices: [Int] {
        presentationState.minimumChoices(selectedCount: selectedCount)
    }

    private func selectLogic(_ logic: ListingLogic) {
        withAnimation(.smooth(duration: 0.18)) {
            selection = presentationState.selectLogic(logic)
        }
    }
}

private struct IndividualListingLogicSegmentButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(MegrumTheme.lavender)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

private struct IndividualListingMinimumCountPicker: View {
    @Binding var selection: ListingLogic
    @Binding var minimumCount: Int
    var choices: [Int]
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("何個以上にしますか？")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            ForEach(choices, id: \.self) { count in
                Button {
                    minimumCount = count
                    selection = .atLeast
                    onDismiss()
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
}
