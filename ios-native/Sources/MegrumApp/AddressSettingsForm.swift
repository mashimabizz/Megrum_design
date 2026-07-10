import MegrumDesign
import SwiftUI

enum AddressSettingsField {
    case recipientName
    case postalCode
    case prefecture
    case city
    case line1
    case line2
    case phoneNumber
}

/// 住所設定フォーム（iter1226.407 刷新）：
/// フラットな7連TextFieldをやめ、「お届け先」「連絡先」の2枚のグループカード＋
/// 上ラベル付きフィールドに。郵便番号照会の成功は該当フィールドのフラッシュで伝える。
struct AddressSettingsForm: View {
    @Binding var recipientName: String
    @Binding var postalCode: String
    @Binding var prefecture: String
    @Binding var city: String
    @Binding var line1: String
    @Binding var line2: String
    @Binding var phoneNumber: String
    var focusedField: FocusState<AddressSettingsField?>.Binding
    var isLookingUpPostalCode: Bool
    /// 郵便番号照会の失敗通知（手入力を促す）。
    var postalLookupNotice: String?
    /// 照会成功で自動入力された時にインクリメントされ、対象フィールドをフラッシュさせる。
    var autoFillPulse: Int
    var inputErrorMessage: String?
    var appErrorMessage: String?
    var onPostalCodeChange: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            AddressSettingsSectionCard(title: "お届け先", systemImage: "shippingbox") {
                AddressLabeledField(
                    label: "宛名",
                    placeholder: "例：山田 花子",
                    text: $recipientName,
                    field: .recipientName,
                    focusedField: focusedField
                )
                .textContentType(.name)
                .submitLabel(.next)
                .onSubmit { focusedField.wrappedValue = .postalCode }

                VStack(alignment: .leading, spacing: 6) {
                    AddressLabeledField(
                        label: "郵便番号（ハイフンなし）",
                        placeholder: "例：5300001",
                        text: $postalCode,
                        field: .postalCode,
                        focusedField: focusedField
                    ) {
                        if isLookingUpPostalCode {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .textContentType(.postalCode)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .onChange(of: postalCode) { _, value in
                        onPostalCodeChange(value)
                    }

                    if let postalLookupNotice {
                        Text(postalLookupNotice)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.conditionPossible)
                    }
                }

                AddressLabeledField(
                    label: "都道府県",
                    placeholder: "例：大阪府",
                    text: $prefecture,
                    field: .prefecture,
                    focusedField: focusedField,
                    autoFillPulse: autoFillPulse
                )
                .textContentType(.addressState)
                .submitLabel(.next)
                .onSubmit { focusedField.wrappedValue = .city }

                AddressLabeledField(
                    label: "市区町村",
                    placeholder: "例：大阪市北区",
                    text: $city,
                    field: .city,
                    focusedField: focusedField,
                    autoFillPulse: autoFillPulse
                )
                .textContentType(.addressCity)
                .submitLabel(.next)
                .onSubmit { focusedField.wrappedValue = .line1 }

                AddressLabeledField(
                    label: "番地・建物名",
                    placeholder: "例：梅田1-1-1 ◯◯マンション101",
                    text: $line1,
                    field: .line1,
                    focusedField: focusedField,
                    autoFillPulse: autoFillPulse
                )
                .textContentType(.streetAddressLine1)
                .submitLabel(.next)
                .onSubmit { focusedField.wrappedValue = .line2 }

                AddressLabeledField(
                    label: "補足住所（任意）",
                    placeholder: "例：部屋番号・様方",
                    text: $line2,
                    field: .line2,
                    focusedField: focusedField
                )
                .textContentType(.streetAddressLine2)
                .submitLabel(.next)
                .onSubmit { focusedField.wrappedValue = .phoneNumber }
            }

            AddressSettingsSectionCard(title: "連絡先（任意）", systemImage: "phone") {
                AddressLabeledField(
                    label: "電話番号",
                    placeholder: "例：09012345678",
                    text: $phoneNumber,
                    field: .phoneNumber,
                    focusedField: focusedField
                )
                .textContentType(.telephoneNumber)
                #if os(iOS)
                .keyboardType(.phonePad)
                #endif
            }

            if let inputErrorMessage {
                AddressSettingsErrorBanner(message: inputErrorMessage)
            } else if let appErrorMessage {
                AddressSettingsErrorBanner(message: appErrorMessage)
            }
        }
    }
}

/// グループカード（白地・radius20・見出しアイコン付き）。
private struct AddressSettingsSectionCard<Content: View>: View {
    var title: String
    var systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MegrumTheme.lavender)
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.black.opacity(0.06), lineWidth: 1)
        }
    }
}

/// 上ラベル＋淡い塗りのフィールド。フォーカス時のみラベンダー枠、自動入力時はフラッシュ。
private struct AddressLabeledField<Trailing: View>: View {
    var label: String
    var placeholder: String
    @Binding var text: String
    var field: AddressSettingsField
    var focusedField: FocusState<AddressSettingsField?>.Binding
    var autoFillPulse: Int = 0
    @ViewBuilder var trailing: Trailing

    @State private var flashActive = false

    init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        field: AddressSettingsField,
        focusedField: FocusState<AddressSettingsField?>.Binding,
        autoFillPulse: Int = 0,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.field = field
        self.focusedField = focusedField
        self.autoFillPulse = autoFillPulse
        self.trailing = trailing()
    }

    private var isFocused: Bool {
        focusedField.wrappedValue == field
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            HStack(spacing: 10) {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .focused(focusedField, equals: field)
                trailing
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(
                MegrumTheme.ink.opacity(0.04),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(MegrumTheme.lavender.opacity(flashActive ? 0.16 : 0))
                    .allowsHitTesting(false)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isFocused ? MegrumTheme.lavender.opacity(0.85) : .clear,
                        lineWidth: 1.5
                    )
            }
            .animation(.easeOut(duration: 0.15), value: isFocused)
        }
        .onChange(of: autoFillPulse) { _, pulse in
            guard pulse > 0 else {
                return
            }
            withAnimation(.easeIn(duration: 0.12)) {
                flashActive = true
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 750_000_000)
                withAnimation(.easeOut(duration: 0.55)) {
                    flashActive = false
                }
            }
        }
    }
}
