import MegrumDesign
import SwiftUI

struct TradeAgreementNextStepFooter: View {
    var isAddingEvidence: Bool
    var action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.sky],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 15)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text("次のステップ")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                Text("交換したら証跡写真を撮る")
                    .font(.system(size: 16.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }

            Spacer(minLength: 6)

            Button(action: action) {
                HStack(spacing: 7) {
                    if isAddingEvidence {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 13, weight: .black))
                    }
                    Text("撮る")
                        .lineLimit(1)
                }
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 15)
                .frame(minHeight: 42)
                .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(isAddingEvidence)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(MegrumTheme.lavender.opacity(0.22), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("次のステップ。交換したら証跡写真を撮る")
        .accessibilityHint("撮るボタンで写真を撮るかアルバムから選ぶかを選択できます")
    }
}

struct TradeEvaluationNextStepFooter: View {
    var isSubmitting: Bool
    var action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 21, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 3) {
                Text("次のステップ")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                Text("評価を入力する")
                    .font(.system(size: 16.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button(action: action) {
                HStack(spacing: 7) {
                    if isSubmitting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 14, weight: .black))
                    }
                    Text("評価入力")
                        .lineLimit(1)
                }
                .font(.system(size: 13.5, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(minHeight: 42)
                .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(MegrumTheme.lavender.opacity(0.22), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("次のステップ。評価を入力する")
    }
}
