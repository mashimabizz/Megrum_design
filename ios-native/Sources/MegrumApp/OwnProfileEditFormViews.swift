import Foundation
import MegrumCore
import SwiftUI

struct OwnProfileEditProfileFields: View {
    @Binding var draft: OwnProfileEditDraft
    var onSubmitSave: () -> Void
    @FocusState private var focusedField: Field?
    @State private var presentationState = OwnProfileEditProfileFieldsPresentationState()

    var body: some View {
        Section {
            displayNameField
            handleField
            bioField
            birthDateRow
            if presentationState.isBirthDatePickerExpanded {
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

    /// ユーザーID（ハンドル）は初回登録から変更できないため、表示のみにする。
    private var handleField: some View {
        LabeledContent("ユーザーID") {
            VStack(alignment: .trailing, spacing: 2) {
                Text(draft.handle.isEmpty ? "未設定" : "@\(draft.handle)")
                    .foregroundStyle(.secondary)
                Text("登録後は変更できません")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
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
                    focusedField = .bio
                }
        }
#else
        LabeledContent("名前") {
            TextField("名前", text: $draft.displayName)
                .focused($focusedField, equals: .displayName)
                .onSubmit {
                    focusedField = .bio
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
                presentationState.toggleBirthDatePicker()
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
                    .rotationEffect(.degrees(presentationState.birthDateChevronDegrees))
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
                draft.birthDate ?? presentationState.birthDateSelectionFallback
            },
            set: { newValue in
                draft.birthDate = newValue
            }
        )
    }

    private var birthDateText: String {
        presentationState.birthDateText(for: draft.birthDate)
    }

    private enum Field {
        case displayName
        case handle
        case bio
    }
}
