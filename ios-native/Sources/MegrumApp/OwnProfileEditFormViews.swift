import MegrumCore
import MegrumDesign
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
        Section("アイコン画像") {
            HStack(alignment: .center, spacing: 16) {
                OwnProfileAvatarImage(
                    avatarURL: draft.visibleAvatarURL,
                    localData: draft.localAvatarData,
                    initial: draft.normalizedDisplayName.first.map(String.init) ?? "M",
                    size: 72
                )

                VStack(alignment: .leading, spacing: 10) {
#if canImport(PhotosUI)
                    PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                        Label("写真を選ぶ", systemImage: "photo")
                    }
#endif

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
                .buttonStyle(.borderless)
            }

            if draft.hasLocalAvatarUpload {
                Label("保存すると新しいアイコンに更新されます", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(MegrumTheme.lavender)
            } else if draft.clearsAvatar {
                Label("保存するとアイコンを削除します", systemImage: "trash")
                    .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
            }

            if let avatarError {
                Label(avatarError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
            }
        }
    }
}

struct OwnProfileEditProfileFields: View {
    @Binding var draft: OwnProfileEditDraft
    var onSubmitSave: () -> Void
    @FocusState private var focusedField: Field?

    var body: some View {
        Section("基本情報") {
            handleField
            displayNameField
        }

        Section("公開情報") {
            Picker("性別", selection: $draft.gender) {
                Text("未設定").tag(UserGender?.none)
                ForEach(UserGender.allCases) { option in
                    Text(option.displayName).tag(Optional(option))
                }
            }

            prefecturePicker
        }
    }

    @ViewBuilder
    private var prefecturePicker: some View {
#if os(iOS)
        Picker("活動エリア", selection: $draft.prefecture) {
            Text("指定なし").tag("")
            ForEach(OwnProfileEditValidation.japanPrefectures, id: \.self) { prefecture in
                Text(prefecture).tag(prefecture)
            }
        }
        .pickerStyle(.navigationLink)
#else
        Picker("活動エリア", selection: $draft.prefecture) {
            Text("指定なし").tag("")
            ForEach(OwnProfileEditValidation.japanPrefectures, id: \.self) { prefecture in
                Text(prefecture).tag(prefecture)
            }
        }
#endif
    }

    @ViewBuilder
    private var handleField: some View {
#if os(iOS)
        TextField("ユーザーID", text: $draft.handle)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focusedField, equals: .handle)
            .submitLabel(.next)
            .onSubmit {
                focusedField = .displayName
            }
#else
        TextField("ユーザーID", text: $draft.handle)
            .focused($focusedField, equals: .handle)
            .onSubmit {
                focusedField = .displayName
            }
#endif
    }

    @ViewBuilder
    private var displayNameField: some View {
#if os(iOS)
        TextField("表示名", text: $draft.displayName)
            .focused($focusedField, equals: .displayName)
            .submitLabel(.done)
            .onSubmit {
                onSubmitSave()
            }
#else
        TextField("表示名", text: $draft.displayName)
            .focused($focusedField, equals: .displayName)
            .onSubmit {
                onSubmitSave()
            }
#endif
    }

    private enum Field {
        case handle
        case displayName
    }
}
