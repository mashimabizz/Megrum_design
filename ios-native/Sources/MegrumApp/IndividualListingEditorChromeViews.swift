import Foundation
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
            IndividualListingEditorHeaderTopRow(
                title: title,
                showsOptionReviewButton: showsOptionReviewButton,
                optionReviewCount: optionReviewCount,
                onShowOptionReview: onShowOptionReview,
                onBack: onBack
            )

            IndividualListingEditorStepProgress(
                step: step,
                onSelectStep: onSelectStep
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

private struct IndividualListingEditorHeaderTopRow: View {
    var title: String
    var showsOptionReviewButton: Bool
    var optionReviewCount: Int
    var onShowOptionReview: () -> Void
    var onBack: () -> Void

    var body: some View {
        ZStack {
            IndividualListingEditorHeaderBackButton(action: onBack)

            Text(title)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            IndividualListingOptionReviewHeaderButton(
                isVisible: showsOptionReviewButton,
                count: optionReviewCount,
                action: onShowOptionReview
            )
        }
    }
}

private struct IndividualListingEditorHeaderBackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct IndividualListingOptionReviewHeaderButton: View {
    var isVisible: Bool
    var count: Int
    var action: () -> Void

    @ViewBuilder
    var body: some View {
        if isVisible {
            Button(action: action) {
                HStack(spacing: 4) {
                    Text("選択肢を確認")
                    if count > 0 {
                        Text("\(count)")
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
}

private struct IndividualListingEditorStepProgress: View {
    var step: IndividualListingEditorStep
    var onSelectStep: (IndividualListingEditorStep) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(step.rawValue)")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("/3")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            ForEach(IndividualListingEditorStep.allCases, id: \.id) { item in
                IndividualListingEditorStepDotButton(
                    item: item,
                    currentStep: step,
                    onSelectStep: onSelectStep
                )
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 40)
        .background(.white.opacity(0.92), in: Capsule())
        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 10, y: 4)
    }
}

private struct IndividualListingEditorStepDotButton: View {
    var item: IndividualListingEditorStep
    var currentStep: IndividualListingEditorStep
    var onSelectStep: (IndividualListingEditorStep) -> Void

    var body: some View {
        Button {
            onSelectStep(item)
        } label: {
            Color.clear
                .frame(width: 22, height: 22)
                .overlay {
                    Circle()
                        .fill(item == currentStep ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.22))
                        .frame(width: item == currentStep ? 16 : 9, height: item == currentStep ? 16 : 9)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
    }
}
