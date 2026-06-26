import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct PaymentSettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.megrumSlidePresentationDismiss) private var slideDismiss
    @FocusState private var focusedField: PaymentSettingsField?
    @State private var draft = PaymentSettingsDraft.empty
    @State private var validationMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PaymentSettingsSectionTitle("対応できる方法")
                methodsCard

                if draft.contains(.bankTransfer) {
                    PaymentSettingsSectionTitle("銀行振込の受け取り口座")
                    bankCard
                }

                validationErrorView
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 104)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("支払い方法の設定")
        .megrumInlineNavigationTitle()
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
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

    private var methodsCard: some View {
        VStack(spacing: 0) {
            methodRow(.bankTransfer, description: "口座情報を登録して、必要な相手に表示します")
            PaymentSettingsDivider()
            methodRow(.paypay, description: "リンク登録なし。対応可否だけを表示します")
            PaymentSettingsDivider()
            methodRow(.cashExchange, description: "現地で差額を手渡しできます")
            PaymentSettingsDivider()
            methodRow(.other, description: "自由入力で支払い方法を補足できます")
            if draft.contains(.other) {
                PaymentSettingsDivider()
                otherInlineField
            }
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
        }
        .paymentSettingsCardStyle()
    }

    private var otherInlineField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("その他")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 88, alignment: .leading)

                TextField("8文字まで", text: otherNoteBinding)
                    .focused($focusedField, equals: .otherNote)
                    #if os(iOS)
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

            HStack {
                Spacer()
                Text("\(draft.otherNote.count)/\(PaymentSettingsDraft.otherNoteMaxLength)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var validationErrorView: some View {
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

    private var bottomBar: some View {
        HStack(spacing: 18) {
            Button("キャンセル") {
                closeScreen()
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
            MegrumHaptics.selectionChanged()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(draft.contains(method) ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.72), lineWidth: 2.2)
                        .frame(width: 28, height: 28)
                    if draft.contains(method) {
                        Circle()
                            .fill(MegrumTheme.lavender)
                            .frame(width: 18, height: 18)
                    }
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(paymentMethodIconTint(method).opacity(0.13))
                    Image(systemName: paymentMethodIconName(method))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(paymentMethodIconTint(method))
                }
                .frame(width: 68, height: 68)

                VStack(alignment: .leading, spacing: 4) {
                    Text(method.displayName)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(description)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(method.displayName)、\(draft.contains(method) ? "選択中" : "未選択")")
    }

    private func paymentMethodIconName(_ method: UserPaymentMethod) -> String {
        switch method {
        case .bankTransfer:
            "building.columns"
        case .paypay:
            "p.square.fill"
        case .cashExchange:
            "banknote"
        case .other:
            "ellipsis.message"
        }
    }

    private func paymentMethodIconTint(_ method: UserPaymentMethod) -> Color {
        switch method {
        case .bankTransfer:
            MegrumTheme.sky
        case .paypay:
            MegrumTheme.conditionExact
        case .cashExchange:
            MegrumTheme.ok
        case .other:
            MegrumTheme.pink
        }
    }

    private var otherNoteBinding: Binding<String> {
        Binding(
            get: { draft.otherNote },
            set: { draft.otherNote = PaymentSettingsDraft.limitedOtherNote($0) }
        )
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
                closeScreen()
            }
        }
    }

    private func closeScreen() {
        if let onClose {
            onClose()
        } else if let slideDismiss {
            slideDismiss()
        } else {
            dismiss()
        }
    }

}
