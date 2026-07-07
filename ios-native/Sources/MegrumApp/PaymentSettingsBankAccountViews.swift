import MegrumCore
import MegrumDesign
import SwiftUI

// MARK: - 口座リスト（設定画面のカード）

struct PaymentSettingsBankAccountsCard: View {
    var accounts: [BankReceivingAccount]
    var canAddAccount: Bool
    var onAdd: () -> Void
    var onEdit: (BankReceivingAccount) -> Void
    var onDelete: (UUID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if accounts.isEmpty {
                PaymentSettingsEmptyAccountRow()
            } else {
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    PaymentSettingsBankAccountRow(
                        account: account,
                        onEdit: { onEdit(account) },
                        onDelete: { onDelete(account.id) }
                    )
                    if index < accounts.count - 1 {
                        PaymentSettingsDivider()
                    }
                }
            }

            if canAddAccount {
                if !accounts.isEmpty {
                    PaymentSettingsDivider()
                }
                PaymentSettingsAddAccountButton(action: onAdd)
            }
        }
        .paymentSettingsCardStyle()
    }
}

struct PaymentSettingsEmptyAccountRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.columns")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MegrumTheme.muted)
            Text("受け取り口座がまだありません")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 18)
    }
}

struct PaymentSettingsBankAccountRow: View {
    var account: BankReceivingAccount
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onEdit) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(MegrumTheme.sky.opacity(0.13))
                        Image(systemName: "building.columns")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(MegrumTheme.sky)
                    }
                    .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(titleText)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(isBlank ? MegrumTheme.muted : MegrumTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(subtitleText)
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted.opacity(0.7))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(titleText)を削除")
        }
        .padding(.vertical, 12)
    }

    private var isBlank: Bool {
        account.bankName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var titleText: String {
        isBlank ? "銀行を選択" : account.bankName
    }

    private var subtitleText: String {
        let parts = [
            account.branchName.nilIfBlank,
            account.accountType.nilIfBlank,
            maskedNumber
        ].compactMap { $0 }
        return parts.isEmpty ? "口座情報を入力" : parts.joined(separator: " ・ ")
    }

    private var maskedNumber: String? {
        let digits = account.accountNumber.filter(\.isNumber)
        guard !digits.isEmpty else {
            return nil
        }
        return "****\(digits.suffix(4))"
    }
}

struct PaymentSettingsAddAccountButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
                Text("受け取り口座を追加する")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct PaymentAccountEditorContext: Identifiable {
    let id = UUID()
    var account: BankReceivingAccount
    var isNew: Bool
}

// MARK: - 口座エディタ（iOS標準 Form）

struct PaymentSettingsBankAccountEditorSheet: View {
    private static let accountTypeOptions = ["普通", "当座"]

    let isNew: Bool
    var onSave: (BankReceivingAccount) -> Void
    var onCancel: () -> Void

    @State private var account: BankReceivingAccount
    @Environment(\.dismiss) private var dismiss

    init(
        account: BankReceivingAccount,
        isNew: Bool,
        onSave: @escaping (BankReceivingAccount) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.isNew = isNew
        self.onSave = onSave
        self.onCancel = onCancel
        var initial = account
        if !Self.accountTypeOptions.contains(initial.accountType) {
            initial.accountType = Self.accountTypeOptions[0]
        }
        _account = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        BankPickerView(selectedID: account.bankId, selectedName: account.bankName) { bankId, name in
                            account.bankId = bankId
                            account.bankName = name
                        }
                    } label: {
                        HStack {
                            Text("銀行名")
                            Spacer()
                            Text(account.bankName.nilIfBlank ?? "選択")
                                .foregroundStyle(account.bankName.nilIfBlank == nil ? .secondary : .primary)
                        }
                    }
                } footer: {
                    Text("銀行名は相手にも表示され、同じ銀行どうしなら見つけやすくなります。")
                }

                Section("口座情報（あなただけが確認できます）") {
                    TextField("支店名（例：渋谷支店）", text: $account.branchName)
                    Picker("口座種別", selection: $account.accountType) {
                        ForEach(Self.accountTypeOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    TextField("口座番号（例：1234567）", text: $account.accountNumber)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    TextField("口座名義（例：ヤマダ ハナコ）", text: $account.holder)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                }
            }
            .navigationTitle(isNew ? "受け取り口座を追加" : "受け取り口座を編集")
            .megrumInlineNavigationTitle()
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(account.normalized())
                        dismiss()
                    }
                    .disabled(!account.normalized().isComplete)
                }
                #endif
            }
        }
    }
}

// MARK: - 銀行ピッカー（iOS標準 searchable List）

struct BankPickerView: View {
    let selectedID: String?
    let selectedName: String
    var onSelect: (String?, String) -> Void

    @State private var query: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let results = BankMaster.search(query)

            if !trimmed.isEmpty,
               !results.contains(where: { $0.name == trimmed }) {
                Section("自由入力") {
                    Button {
                        onSelect(nil, trimmed)
                        dismiss()
                    } label: {
                        Label("「\(trimmed)」を使う", systemImage: "square.and.pencil")
                    }
                }
            }

            Section("銀行から選ぶ") {
                ForEach(results) { entry in
                    Button {
                        onSelect(entry.id, entry.name)
                        dismiss()
                    } label: {
                        HStack {
                            Text(entry.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if entry.id == selectedID {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(MegrumTheme.lavender)
                            }
                        }
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "銀行名で検索")
        #endif
        .navigationTitle("銀行を選ぶ")
        .megrumInlineNavigationTitle()
    }
}
