import MegrumDesign
import SwiftUI

struct GoodsSharePromptOverlay: View {
    var context: GoodsSharePostContext
    var isPreparing: Bool
    var errorMessage: String?
    var onDismiss: () -> Void
    var onShare: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.promptTitle)
                            .font(.title3.weight(.black))
                            .foregroundStyle(MegrumTheme.ink)
                        Text(context.promptDescription)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    Spacer(minLength: 12)

                    Button("閉じる", systemImage: "xmark", action: onDismiss)
                        .labelStyle(.iconOnly)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(width: 36, height: 36)
                        .background(MegrumTheme.canvas, in: Circle())
                        .accessibilityLabel("ポスト作成の案内を閉じる")
                }

                GoodsSharePromptPreview(items: context.shareItems)

                Button(action: onShare) {
                    HStack(spacing: 10) {
                        if isPreparing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(context.shareButtonTitle)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56)
                    .padding(.horizontal, 12)
                    .background(
                        LinearGradient(
                            colors: [MegrumTheme.lavender, MegrumTheme.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isPreparing)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(MegrumTheme.pink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(22)
            .frame(maxWidth: 350)
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.20), radius: 26, y: 16)
            .padding(.horizontal, 24)
        }
    }
}
