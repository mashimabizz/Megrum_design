import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomArchiveReactionMessageSheet: View {
    var target: GroomArchiveReactionMessageTarget
    var isSending: Bool
    @Binding var draft: String
    var onCancel: () -> Void
    var onSend: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    GroomThumbnailCircle(url: target.sourceGroom.imageURL, size: 74)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(target.displayName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)
                        Text("グルームへのメッセージ")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    Spacer(minLength: 0)
                }

                TextField("メッセージを入力", text: $draft, axis: .vertical)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(3...6)
                    .padding(14)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(MegrumTheme.lavender.opacity(0.14), lineWidth: 1)
                    }

                Button(action: onSend) {
                    HStack(spacing: 8) {
                        if isSending {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        Text("送信")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(MegrumTheme.lavender, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

                Spacer(minLength: 0)
            }
            .padding(22)
            .background(MegrumTheme.canvas)
            .navigationTitle("メッセージ")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", action: onCancel)
                }
            }
        }
    }
}
