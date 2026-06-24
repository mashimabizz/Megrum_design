import MegrumDesign
import SwiftUI

struct TradeEvaluationSheet: View {
    @State private var stars = 5
    @State private var comment = ""
    var isSubmitting: Bool
    var onSubmit: (Int, String?) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("評価を送信")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Spacer()
            }

            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        stars = value
                    } label: {
                        Image(systemName: value <= stars ? "star.fill" : "star")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)

            TextField("コメント（任意）", text: $comment, axis: .vertical)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .lineLimit(3...5)
                .padding(14)
                .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                Task {
                    await onSubmit(stars, comment.nilIfBlank)
                }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("送信")
                    }
                }
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(MegrumTheme.lavender, in: Capsule())
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)

            Spacer(minLength: 0)
        }
        .padding(22)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("評価")
        .megrumInlineNavigationTitle()
    }
}
