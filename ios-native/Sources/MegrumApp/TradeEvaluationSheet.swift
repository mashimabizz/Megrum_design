import MegrumDesign
import SwiftUI

struct TradeEvaluationSheet: View {
    @State private var draftState = TradeEvaluationDraftState()
    var isSubmitting: Bool
    /// iter1226.423：送信失敗を画面内に表示する（以前は何も出ず詰まって見えた）。
    var errorMessage: String?
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
                        draftState.stars = value
                    } label: {
                        Image(systemName: value <= draftState.stars ? "star.fill" : "star")
                            .font(.system(size: 30, weight: .bold))
                            // 評価の星は候補シート・やりとり一覧と同じ黄色に統一（iter1226.382 / FB6-4）。
                            .foregroundStyle(value <= draftState.stars ? MegrumRating.starColor : MegrumTheme.muted.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)

            TextField("コメント（任意）", text: $draftState.comment, axis: .vertical)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .lineLimit(3...5)
                .padding(14)
                .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Button {
                Task {
                    await onSubmit(draftState.stars, draftState.submittedComment)
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
