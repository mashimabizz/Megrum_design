import MegrumDesign
import PhotosUI
import SwiftUI

struct GroomStoryComposerScreen: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    var isCreating: Bool
    var canUseCamera: Bool
    var onOpenCamera: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("閉じる")

                    Spacer()

                    Text("グルームに追加")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Color.clear
                        .frame(width: 48, height: 48)
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)

                HStack {
                    Text("最近の項目")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.82))

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    Button(action: onOpenCamera) {
                        GroomComposerActionTile(
                            title: "カメラで撮る",
                            subtitle: canUseCamera ? "いまの現場を撮影" : "この端末では利用不可",
                            systemImage: "camera.fill",
                            isLoading: isCreating
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isCreating || !canUseCamera)
                    .opacity(canUseCamera ? 1 : 0.48)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        GroomComposerActionTile(
                            title: "写真を選ぶ",
                            subtitle: "最近の項目から追加",
                            systemImage: "photo.on.rectangle.angled",
                            isLoading: isCreating
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isCreating)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)

                Spacer()

                Text("投稿したグルームは近くの人にだけ表示されます。正確な位置は表示しません。")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 34)
                    .padding(.bottom, 24)
            }
        }
        .onChange(of: selectedPhotoItem) { _, item in
            if item != nil {
                dismiss()
            }
        }
    }
}

private struct GroomComposerActionTile: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white.opacity(0.12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    }

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 128)

            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(2)
        }
    }
}
