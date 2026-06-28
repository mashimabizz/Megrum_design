#if canImport(PhotosUI)
import PhotosUI
#endif
import SwiftUI

struct OwnProfileEditAvatarSection: View {
    @Binding var draft: OwnProfileEditDraft
    var avatarError: String?
    var onShowCamera: () -> Void
    var onDeleteAvatar: () -> Void
#if canImport(PhotosUI)
    @Binding var selectedAvatarItem: PhotosPickerItem?

    init(
        draft: Binding<OwnProfileEditDraft>,
        avatarError: String?,
        selectedAvatarItem: Binding<PhotosPickerItem?>,
        onShowCamera: @escaping () -> Void,
        onDeleteAvatar: @escaping () -> Void
    ) {
        self._draft = draft
        self.avatarError = avatarError
        self._selectedAvatarItem = selectedAvatarItem
        self.onShowCamera = onShowCamera
        self.onDeleteAvatar = onDeleteAvatar
    }
#else
    init(
        draft: Binding<OwnProfileEditDraft>,
        avatarError: String?,
        onShowCamera: @escaping () -> Void,
        onDeleteAvatar: @escaping () -> Void
    ) {
        self._draft = draft
        self.avatarError = avatarError
        self.onShowCamera = onShowCamera
        self.onDeleteAvatar = onDeleteAvatar
    }
#endif

    var body: some View {
        Section {
            VStack(spacing: 0) {
                avatarPickerButton
                    .contextMenu {
#if os(iOS)
                        Button(action: onShowCamera) {
                            Label("カメラで撮影", systemImage: "camera")
                        }
#endif

                        if draft.hasVisibleAvatar || draft.clearsAvatar {
                            Button(role: .destructive, action: onDeleteAvatar) {
                                Label("アイコンを削除", systemImage: "trash")
                            }
                        }
                    }
                    .accessibilityLabel("プロフィール画像を変更")

                if let avatarError {
                    Label(avatarError, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
                        .padding(.top, 12)
                }
            }
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var avatarPickerButton: some View {
#if canImport(PhotosUI)
        ZStack {
            avatarContent
            PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 82, height: 82)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
#else
        Button(action: onShowCamera) {
            avatarContent
        }
        .buttonStyle(.plain)
#endif
    }

    private var avatarContent: some View {
        OwnProfileAvatarImage(
            avatarURL: draft.visibleAvatarURL,
            localData: draft.localAvatarData,
            initial: draft.normalizedDisplayName.first.map(String.init) ?? "M",
            size: 82,
            showsChrome: false
        )
    }
}
