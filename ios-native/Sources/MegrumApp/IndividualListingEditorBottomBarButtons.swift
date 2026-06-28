import MegrumDesign
import SwiftUI

struct IndividualListingEditorBackBottomBarButton: View {
    var action: () -> Void

    var body: some View {
        Button("戻る") {
            MegrumHaptics.performButtonTap(action)
        }
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
            .frame(width: 132, height: 58)
            .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(MegrumTheme.lavender, lineWidth: 1.2)
            }
    }
}

struct IndividualListingEditorPrimaryBottomBarButton: View {
    var title: String
    var isSaving: Bool
    var isDisabled: Bool
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(action)
        } label: {
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
}

struct IndividualListingEditorSelectAllVisibleButton: View {
    var title: String
    var canSelectAllVisible: Bool
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(action)
        } label: {
            Text(title)
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
        .accessibilityLabel("表示中の項目を\(title)")
    }
}

struct IndividualListingEditorAddOptionButton: View {
    var width: CGFloat
    var isDisabled: Bool
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(action)
        } label: {
            Text(IndividualListingEditorBottomBarPresentation.addOptionTitle)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(width: width, height: 56)
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
}
