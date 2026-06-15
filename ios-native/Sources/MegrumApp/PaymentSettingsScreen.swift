import MegrumCore
import MegrumDesign
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct PaymentSettingsDraft: Equatable, Sendable {
    var methods: [UserPaymentMethod]
    var bankName: String
    var bankBranchName: String
    var bankAccountType: String
    var bankAccountNumber: String
    var bankAccountHolder: String
    var otherNote: String

    static let empty = PaymentSettingsDraft(
        methods: [],
        bankName: "",
        bankBranchName: "",
        bankAccountType: "",
        bankAccountNumber: "",
        bankAccountHolder: "",
        otherNote: ""
    )

    init(settings: UserPaymentSettings?, viewer: UserProfile?) {
        self.methods = UserPaymentMethod.normalized(viewer?.paymentMethods ?? settings?.methods ?? [])
        self.bankName = settings?.bankName ?? ""
        self.bankBranchName = settings?.bankBranchName ?? ""
        self.bankAccountType = settings?.bankAccountType ?? ""
        self.bankAccountNumber = settings?.bankAccountNumber ?? ""
        self.bankAccountHolder = settings?.bankAccountHolder ?? ""
        self.otherNote = settings?.otherNote ?? viewer?.paymentNote ?? ""
    }

    init(
        methods: [UserPaymentMethod],
        bankName: String,
        bankBranchName: String,
        bankAccountType: String,
        bankAccountNumber: String,
        bankAccountHolder: String,
        otherNote: String
    ) {
        self.methods = UserPaymentMethod.normalized(methods)
        self.bankName = bankName
        self.bankBranchName = bankBranchName
        self.bankAccountType = bankAccountType
        self.bankAccountNumber = bankAccountNumber
        self.bankAccountHolder = bankAccountHolder
        self.otherNote = otherNote
    }

    var normalized: PaymentSettingsDraft {
        PaymentSettingsDraft(
            methods: methods,
            bankName: trimmed(bankName),
            bankBranchName: trimmed(bankBranchName),
            bankAccountType: trimmed(bankAccountType),
            bankAccountNumber: normalizedAccountNumber,
            bankAccountHolder: trimmed(bankAccountHolder),
            otherNote: trimmed(otherNote)
        )
    }

    var summaryText: String {
        UserPaymentMethod.displayText(
            for: normalized.methods,
            otherNote: normalized.otherNote.nilIfBlank,
            emptyText: "未設定"
        )
    }

    var bankPreviewText: String? {
        let normalized = normalized
        guard normalized.methods.contains(.bankTransfer),
              !normalized.bankName.isEmpty,
              !normalized.bankBranchName.isEmpty,
              !normalized.bankAccountType.isEmpty,
              !normalized.bankAccountNumber.isEmpty
        else {
            return nil
        }
        return "口座: \(normalized.bankName) \(normalized.bankBranchName) \(normalized.bankAccountType) \(maskedAccountNumber(normalized.bankAccountNumber))"
    }

    var validationMessage: String? {
        let normalized = normalized
        if normalized.methods.contains(.bankTransfer) {
            let bankValues = [
                normalized.bankName,
                normalized.bankBranchName,
                normalized.bankAccountType,
                normalized.bankAccountNumber,
                normalized.bankAccountHolder
            ]
            if bankValues.contains(where: \.isEmpty) {
                return "銀行振込を選ぶ場合は口座情報を入力してください"
            }
        }
        if normalized.methods.contains(.other), normalized.otherNote.isEmpty {
            return "その他を選ぶ場合は自由入力を入力してください"
        }
        return nil
    }

    mutating func set(_ method: UserPaymentMethod, isSelected: Bool) {
        if isSelected {
            methods.append(method)
        } else {
            methods.removeAll { $0 == method }
        }
        methods = UserPaymentMethod.normalized(methods)
    }

    func contains(_ method: UserPaymentMethod) -> Bool {
        methods.contains(method)
    }

    func settings(userID: UUID) -> UserPaymentSettings {
        let normalized = normalized
        return UserPaymentSettings(
            userID: userID,
            methods: normalized.methods,
            bankName: normalized.bankName,
            bankBranchName: normalized.bankBranchName,
            bankAccountType: normalized.bankAccountType,
            bankAccountNumber: normalized.bankAccountNumber,
            bankAccountHolder: normalized.bankAccountHolder,
            otherNote: normalized.otherNote.nilIfBlank
        )
    }

    private var normalizedAccountNumber: String {
        String(bankAccountNumber.filter(\.isNumber).prefix(32))
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func maskedAccountNumber(_ value: String) -> String {
        let suffix = String(value.suffix(4))
        return "****\(suffix)"
    }
}

@MainActor
struct PaymentSettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var draft = PaymentSettingsDraft.empty
    @State private var validationMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                introCard

                PaymentSettingsSectionTitle("対応できる方法")
                methodsCard

                PaymentSettingsSectionTitle("銀行振込の受け取り口座")
                bankCard

                PaymentSettingsSectionTitle("その他")
                otherCard

                PaymentSettingsSectionTitle("相手に見える内容")
                previewCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 104)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("支払い条件")
        .megrumInlineNavigationTitle()
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                }
                .font(.body.weight(.semibold))
                .disabled(appState.isSavingPaymentSettings)
            }

            #if os(iOS)
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    focusedField = nil
                }
                .font(.body.weight(.semibold))
            }
            #endif
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .task {
            applyCurrentValues()
            await appState.loadPaymentSettings()
            applyCurrentValues()
        }
        .onChange(of: appState.viewer) {
            applyCurrentValues()
        }
        .onChange(of: appState.paymentSettings) {
            applyCurrentValues()
        }
        .onChange(of: draft) {
            validationMessage = nil
        }
    }

    private var introCard: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("受け付ける支払い方法")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text("取引ごとに、相手へ表示する方法を選べます")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            Spacer()

            Text("複数選択OK")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(MegrumTheme.lavender.opacity(0.14), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(MegrumTheme.lavender.opacity(0.24), lineWidth: 1)
                }
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 18, y: 10)
    }

    private var methodsCard: some View {
        VStack(spacing: 0) {
            methodRow(.bankTransfer, description: "口座情報を登録して、必要な相手に表示します")
            Divider().padding(.leading, 52)
            methodRow(.paypay, description: "リンク登録なし。対応可否だけを表示します")
            Divider().padding(.leading, 52)
            methodRow(.cashExchange, description: "現地で差額を手渡しできます")
            Divider().padding(.leading, 52)
            methodRow(.other, description: "自由入力で支払い方法を補足できます")
        }
        .paymentSettingsCardStyle()
    }

    private var bankCard: some View {
        VStack(spacing: 0) {
            PaymentSettingsTextFieldRow(
                title: "銀行名",
                placeholder: "みずほ銀行",
                text: $draft.bankName,
                focusedField: $focusedField,
                field: .bankName
            )
            PaymentSettingsDivider()
            PaymentSettingsTextFieldRow(
                title: "支店名",
                placeholder: "渋谷支店",
                text: $draft.bankBranchName,
                focusedField: $focusedField,
                field: .bankBranchName
            )
            PaymentSettingsDivider()
            PaymentSettingsTextFieldRow(
                title: "口座種別",
                placeholder: "普通",
                text: $draft.bankAccountType,
                focusedField: $focusedField,
                field: .bankAccountType
            )
            PaymentSettingsDivider()
            PaymentSettingsTextFieldRow(
                title: "口座番号",
                placeholder: "1234567",
                text: $draft.bankAccountNumber,
                keyboard: .numberPad,
                focusedField: $focusedField,
                field: .bankAccountNumber
            )
            PaymentSettingsDivider()
            PaymentSettingsTextFieldRow(
                title: "口座名義",
                placeholder: "ヤマダ ハナコ",
                text: $draft.bankAccountHolder,
                focusedField: $focusedField,
                field: .bankAccountHolder
            )

            Text("口座番号は相手向けプレビューでは一部マスクされます")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
        }
        .paymentSettingsCardStyle()
    }

    private var otherCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("自由入力")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            TextField("メルペイ、楽天ペイも相談可", text: $draft.otherNote, axis: .vertical)
                .focused($focusedField, equals: .otherNote)
                .lineLimit(1...3)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(MegrumTheme.canvas, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
                }
        }
        .paymentSettingsCardStyle()
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("プレビュー")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.13, green: 0.50, blue: 0.72))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 0.80, green: 0.93, blue: 1.0).opacity(0.55), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(Color(red: 0.13, green: 0.50, blue: 0.72).opacity(0.20), lineWidth: 1)
                }

            Text(draft.summaryText)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            if let bankPreviewText = draft.bankPreviewText {
                Text(bankPreviewText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            Text("取引で必要になった相手にだけ表示されます")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            if let validationMessage {
                Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
                    .padding(.top, 4)
            } else if let errorMessage = appState.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
                    .padding(.top, 4)
            }
        }
        .paymentSettingsCardStyle(strokeColor: MegrumTheme.sky.opacity(0.28))
    }

    private var bottomBar: some View {
        HStack(spacing: 18) {
            Button("キャンセル") {
                dismiss()
            }
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
            .frame(maxWidth: .infinity)
            .frame(height: 52)

            Button {
                save()
            } label: {
                HStack(spacing: 10) {
                    if appState.isSavingPaymentSettings {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    Text("保存する")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.sky],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
            .disabled(appState.isSavingPaymentSettings)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(.white.opacity(0.96))
    }

    private func methodRow(_ method: UserPaymentMethod, description: String) -> some View {
        Button {
            var next = draft
            next.set(method, isSelected: !draft.contains(method))
            draft = next
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: draft.contains(method) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(draft.contains(method) ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.55))
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(method.displayName)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(description)
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(method.displayName)、\(draft.contains(method) ? "選択中" : "未選択")")
    }

    private func applyCurrentValues() {
        draft = PaymentSettingsDraft(settings: appState.paymentSettings, viewer: appState.viewer)
    }

    private func save() {
        let normalized = draft.normalized
        if let message = normalized.validationMessage {
            validationMessage = message
            return
        }
        guard let userID = appState.viewer?.id else {
            validationMessage = "プロフィールを読み込めませんでした"
            return
        }

        focusedField = nil
        Task {
            if await appState.savePaymentSettings(normalized.settings(userID: userID)) {
                dismiss()
            }
        }
    }

    enum Field: Hashable {
        case bankName
        case bankBranchName
        case bankAccountType
        case bankAccountNumber
        case bankAccountHolder
        case otherNote
    }
}

private struct PaymentSettingsSectionTitle: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, 2)
    }
}

private struct PaymentSettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 104)
    }
}

private struct PaymentSettingsTextFieldRow: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    var keyboard: PaymentSettingsKeyboard = .default
    var focusedField: FocusState<PaymentSettingsScreen.Field?>.Binding
    var field: PaymentSettingsScreen.Field

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(width: 88, alignment: .leading)

            TextField(placeholder, text: $text)
                .focused(focusedField, equals: field)
                #if os(iOS)
                .keyboardType(keyboard.uiKeyboardType)
                .textInputAutocapitalization(.never)
                #endif
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(MegrumTheme.canvas, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
                }
        }
        .padding(.vertical, 5)
    }
}

private enum PaymentSettingsKeyboard {
    case `default`
    case numberPad

    #if os(iOS)
    var uiKeyboardType: UIKeyboardType {
        switch self {
        case .default:
            .default
        case .numberPad:
            .numberPad
        }
    }
    #endif
}

private extension View {
    func paymentSettingsCardStyle(strokeColor: Color = MegrumTheme.ink.opacity(0.08)) -> some View {
        padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.04), radius: 18, y: 10)
    }
}
