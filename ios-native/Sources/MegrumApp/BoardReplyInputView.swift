import MegrumDesign
import SwiftUI

struct BoardReplyInput: View {
    @Binding var text: String
    var isSending: Bool
    var isDisabled = false
    var canUseCamera = false
    var onOpenCamera: () -> Void = {}
    var onOpenPhotoLibrary: () -> Void = {}
    var onSend: () -> Void

    private var canSend: Bool {
        !text.isBlank && !isSending && !isDisabled
    }

    var body: some View {
        HStack(spacing: 10) {
            Menu {
                Button(action: onOpenPhotoLibrary) {
                    Label("写真を選ぶ", systemImage: "photo.on.rectangle")
                }

                Button(action: onOpenCamera) {
                    Label("カメラで撮る", systemImage: "camera")
                }
                .disabled(!canUseCamera)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.9), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(isSending || isDisabled)
            .opacity(isDisabled ? 0.45 : 1)

            TextField("メッセージ", text: $text, axis: .vertical)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .lineLimit(1...3)
                .submitLabel(.send)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 40)
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
                .frame(width: 42, height: 42)
                .background(MegrumTheme.lavender, in: Circle())
                .shadow(color: MegrumTheme.lavender.opacity(0.34), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .opacity(canSend ? 1 : 0.45)
        }
        .foregroundStyle(MegrumTheme.lavender)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            // 入力欄の背景を下端（ホームインジケータ側）まで同色で伸ばす
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
        .opacity(isDisabled ? 0.62 : 1)
    }
}
