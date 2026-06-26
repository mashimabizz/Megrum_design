import Foundation
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

struct OwnProfileEditProfileFields: View {
    @Binding var draft: OwnProfileEditDraft
    var onSubmitSave: () -> Void
    @FocusState private var focusedField: Field?
    @State private var isBirthDatePickerExpanded = false

    var body: some View {
        Section {
            displayNameField
            handleField
            bioField
            birthDateRow
            if isBirthDatePickerExpanded {
                birthDatePicker
            }
            genderPicker
            prefecturePicker
        }
    }

    @ViewBuilder
    private var prefecturePicker: some View {
#if os(iOS)
        Picker("活動エリア", selection: $draft.prefecture) {
            Text("未設定").tag("")
            ForEach(OwnProfileEditValidation.japanPrefectures, id: \.self) { prefecture in
                Text(prefecture).tag(prefecture)
            }
        }
        .pickerStyle(.navigationLink)
#else
        Picker("活動エリア", selection: $draft.prefecture) {
            Text("未設定").tag("")
            ForEach(OwnProfileEditValidation.japanPrefectures, id: \.self) { prefecture in
                Text(prefecture).tag(prefecture)
            }
        }
#endif
    }

    private var genderPicker: some View {
        Picker("性別", selection: genderSelection) {
            Text(UserGender.female.displayName).tag(UserGender.female)
            Text(UserGender.male.displayName).tag(UserGender.male)
        }
    }

    private var genderSelection: Binding<UserGender> {
        Binding(
            get: {
                OwnProfileEditDraft.editableGender(draft.gender)
            },
            set: { newValue in
                draft.gender = newValue
            }
        )
    }

    @ViewBuilder
    private var handleField: some View {
#if os(iOS)
        LabeledContent("ユーザーネーム") {
            TextField("ユーザーネーム", text: $draft.handle)
                .multilineTextAlignment(.trailing)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .handle)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .bio
                }
        }
#else
        LabeledContent("ユーザーネーム") {
            TextField("ユーザーネーム", text: $draft.handle)
                .focused($focusedField, equals: .handle)
                .onSubmit {
                    focusedField = .bio
                }
        }
#endif
    }

    @ViewBuilder
    private var displayNameField: some View {
#if os(iOS)
        LabeledContent("名前") {
            TextField("名前", text: $draft.displayName)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: .displayName)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .handle
                }
        }
#else
        LabeledContent("名前") {
            TextField("名前", text: $draft.displayName)
                .focused($focusedField, equals: .displayName)
                .onSubmit {
                    focusedField = .handle
                }
        }
#endif
    }

    @ViewBuilder
    private var bioField: some View {
#if os(iOS)
        VStack(alignment: .leading, spacing: 8) {
            Text("自己紹介")
            TextField("自己紹介", text: $draft.bio, axis: .vertical)
                .lineLimit(3...6)
                .focused($focusedField, equals: .bio)
                .submitLabel(.done)
                .onSubmit {
                    focusedField = nil
                }
        }
#else
        VStack(alignment: .leading, spacing: 8) {
            Text("自己紹介")
            TextField("自己紹介", text: $draft.bio)
                .focused($focusedField, equals: .bio)
                .onSubmit {
                    focusedField = nil
                }
        }
#endif
    }

    private var birthDateRow: some View {
        Button {
            withAnimation(.snappy(duration: 0.18)) {
                isBirthDatePickerExpanded.toggle()
            }
        } label: {
            HStack {
                Text("生年月日")
                    .foregroundStyle(.primary)
                Spacer()
                Text(birthDateText)
                    .foregroundStyle(draft.birthDate == nil ? .secondary : .primary)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isBirthDatePickerExpanded ? 90 : 0))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("生年月日")
        .accessibilityValue(birthDateText)
    }

    private var birthDatePicker: some View {
        DatePicker(
            "生年月日",
            selection: birthDateSelection,
            in: ...Date(),
            displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .labelsHidden()
    }

    private var birthDateSelection: Binding<Date> {
        Binding(
            get: {
                draft.birthDate ?? Self.defaultBirthDate
            },
            set: { newValue in
                draft.birthDate = newValue
            }
        )
    }

    private var birthDateText: String {
        guard let birthDate = draft.birthDate else {
            return "未設定"
        }
        return Self.birthDateFormatter.string(from: birthDate)
    }

    private static let birthDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static var defaultBirthDate: Date {
        Calendar(identifier: .gregorian)
            .date(byAdding: .year, value: -20, to: .now)
            ?? .now
    }

    private enum Field {
        case displayName
        case handle
        case bio
    }
}
