import MegrumDesign
import SwiftUI

struct DisputeReplyComposer: View {
    @Binding var draft: DisputeReplyDraft
    var isSubmitting: Bool
    var onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $draft.body)
                .frame(minHeight: 124)
                .overlay(alignment: .topLeading) {
                    if draft.body.isEmpty {
                        Text("事実関係、到着時刻、チャットで確認できる内容を書いてください")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted.opacity(0.68))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }

            Toggle("証跡やチャット内容も確認してほしい", isOn: $draft.includesEvidenceNote)

            if let validationMessage = draft.validationMessage, !draft.normalizedBody.isEmpty {
                Text(validationMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            Button(action: onSubmit) {
                Group {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("反論を送信", systemImage: "paperplane.fill")
                    }
                }
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(MegrumTheme.lavender, in: Capsule())
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!draft.isSubmittable || isSubmitting)
            .opacity(draft.isSubmittable ? 1 : 0.45)
        }
        .padding(.vertical, 6)
    }
}
