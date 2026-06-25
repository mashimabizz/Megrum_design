import MegrumDesign
import SwiftUI

struct BoardReplyInput: View {
    @Binding var text: String
    var isSending: Bool
    var isDisabled = false
    var onSend: () -> Void

    private var canSend: Bool {
        !text.isBlank && !isSending && !isDisabled
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "photo")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
            Image(systemName: "camera")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            TextField("この話題に返信する", text: $text, axis: .vertical)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .lineLimit(1...3)
                .submitLabel(.send)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 40)
                .background(.white.opacity(0.94), in: Capsule())
                .overlay(Capsule().strokeBorder(MegrumTheme.ink.opacity(0.09), lineWidth: 1))
                .onSubmit {
                    if canSend {
                        onSend()
                    }
                }
                .disabled(isDisabled)

            Button(action: onSend) {
                Group {
                    if isSending {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(MegrumTheme.lavender, in: Circle())
                .shadow(color: MegrumTheme.lavender.opacity(0.34), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .opacity(canSend ? 1 : 0.45)
        }
        .foregroundStyle(MegrumTheme.lavender)
        .padding(.horizontal, 20)
        .frame(height: 68)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .shadow(color: MegrumTheme.ink.opacity(0.10), radius: 18, y: -5)
        .opacity(isDisabled ? 0.62 : 1)
    }
}
