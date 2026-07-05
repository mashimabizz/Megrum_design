import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

/// プロフィールの評価タップで開く、これまでの評価一覧シート。
struct UserEvaluationListSheet: View {
    var evaluations: [UserEvaluation]
    var isLoading: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if evaluations.isEmpty {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ContentUnavailableView(
                            "評価はまだありません",
                            systemImage: "star",
                            description: Text("取引が完了すると相手からの評価がここに表示されます。")
                        )
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(evaluations) { evaluation in
                                UserEvaluationRow(evaluation: evaluation)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle("評価一覧")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct UserEvaluationRow: View {
    var evaluation: UserEvaluation

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProfileVisualAvatar(
                url: evaluation.raterAvatarURL,
                fallback: evaluation.raterDisplayName,
                size: 42
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(evaluation.raterDisplayName.nilIfBlank ?? evaluation.raterHandle)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(evaluation.createdAt.formatted(date: .numeric, time: .omitted))
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < evaluation.stars ? "star.fill" : "star")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(
                                index < evaluation.stars
                                    ? Color(red: 0.98, green: 0.75, blue: 0.24)
                                    : MegrumTheme.muted.opacity(0.4)
                            )
                    }
                }

                if let comment = evaluation.comment?.nilIfBlank {
                    Text(comment)
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.82))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.12), lineWidth: 1)
        }
    }
}
