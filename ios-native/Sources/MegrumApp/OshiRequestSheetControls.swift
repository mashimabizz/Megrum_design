import MegrumDesign
import SwiftUI

struct OshiFilterChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.84)
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .padding(.horizontal, 18)
                .frame(height: 46)
                .background(
                    isSelected ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .strokeBorder(isSelected ? MegrumTheme.lavender : .black.opacity(0.08), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct OshiRequestSubmitFooter: View {
    var canSubmit: Bool
    var onSubmit: () -> Void

    var body: some View {
        Button(action: onSubmit) {
            Text("送信して仮登録")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: OshiRequestSheetLayoutMetrics.submitButtonHeight)
                .background(
                    canSubmit ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.25),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(MegrumTheme.canvas.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.black.opacity(0.08))
                .frame(height: 0.5)
        }
    }
}
