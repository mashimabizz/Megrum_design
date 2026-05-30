import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct SettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                NavigationLink {
                    AddressSettingsScreen(appState: appState)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("住所設定")
                                .font(.body.weight(.semibold))
                            Text(addressStatusText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    } icon: {
                        Image(systemName: "shippingbox")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }

                NavigationLink {
                    BlockedUsersScreen(appState: appState)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("ブロックした人")
                                .font(.body.weight(.semibold))
                            Text("一覧と解除")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    } icon: {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }
            }
        }
        .navigationTitle("設定")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .task {
            if appState.mailingAddress == nil {
                await appState.loadMailingAddress()
            }
        }
    }

    private var addressStatusText: String {
        guard let address = appState.mailingAddress, address.isReady else {
            return "未登録"
        }
        return address.summary
    }
}

@MainActor
struct BlockedUsersScreen: View {
    @ObservedObject var appState: MegrumAppState
    @State private var userPendingUnblock: BlockedUser?
    @State private var isShowingUnblockDialog = false

    var body: some View {
        List {
            Section {
                if appState.isLoadingBlockedUsers {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        Text("読み込んでいます")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                } else if appState.blockedUsers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ブロック中のユーザーはいません")
                            .font(.headline.weight(.bold))
                        Text("必要になった時は、プロフィールや掲示板のメニューから追加できます。")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(appState.blockedUsers) { user in
                        BlockedUserRow(
                            user: user,
                            isUnblocking: appState.unblockingUserID == user.userID,
                            onUnblock: {
                                userPendingUnblock = user
                                isShowingUnblockDialog = true
                            }
                        )
                    }
                }
            } header: {
                Text("\(appState.blockedUsers.count)人")
            }
        }
        .navigationTitle("ブロックした人")
        .megrumInlineNavigationTitle()
        .task {
            await appState.loadBlockedUsers()
        }
        .refreshable {
            await appState.loadBlockedUsers()
        }
        .confirmationDialog("ブロックを解除しますか？", isPresented: $isShowingUnblockDialog, titleVisibility: .visible) {
            if let user = userPendingUnblock {
                Button("解除", role: .destructive) {
                    Task {
                        _ = await appState.unblockUser(user.userID)
                        userPendingUnblock = nil
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            if let user = userPendingUnblock {
                Text("\(user.displayName)さんをブロックした人から外します。")
            }
        }
    }
}

private struct BlockedUserRow: View {
    var user: BlockedUser
    var isUnblocking: Bool
    var onUnblock: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MegrumTheme.ink)
                Text("@\(user.handle)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
                Text(blockedAtText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted.opacity(0.85))
            }

            Spacer(minLength: 8)

            Button {
                onUnblock()
            } label: {
                if isUnblocking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("解除")
                        .font(.subheadline.weight(.bold))
                }
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .disabled(isUnblocking)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var avatar: some View {
        if let avatarURL = user.avatarURL {
            AsyncImage(url: avatarURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                avatarPlaceholder
            }
            .frame(width: 46, height: 46)
            .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(MegrumTheme.lavender.opacity(0.18))
            .frame(width: 46, height: 46)
            .overlay {
                Text(String(user.displayName.prefix(1)))
                    .font(.headline.weight(.black))
                    .foregroundStyle(MegrumTheme.lavender)
            }
    }

    private var blockedAtText: String {
        guard let blockedAt = user.blockedAt else {
            return "ブロック中"
        }
        return blockedAt.formatted(.dateTime.month().day()) + "からブロック中"
    }
}

@MainActor
struct AddressSettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    @State private var recipientName = ""
    @State private var postalCode = ""
    @State private var prefecture = ""
    @State private var city = ""
    @State private var line1 = ""
    @State private var line2 = ""
    @State private var phoneNumber = ""
    @State private var postalCodeLookupTask: Task<Void, Never>?
    @State private var lastAppliedPostalCode = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                form
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("住所設定")
        .megrumInlineNavigationTitle()
        .task {
            await appState.loadMailingAddress()
            apply(address: appState.mailingAddress)
        }
        .onDisappear {
            postalCodeLookupTask?.cancel()
        }
        .onChange(of: appState.mailingAddress) { _, address in
            apply(address: address)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("住所設定")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("取引で必要になる住所を、本人だけが編集できます")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
    }

    private var form: some View {
        VStack(spacing: 12) {
            TextField("宛名", text: $recipientName)
                .focused($focusedField, equals: .recipientName)
                .textContentType(.name)
                .submitLabel(.next)
                .onSubmit { focusedField = .postalCode }
                .megrumTextFieldStyle()

            HStack(spacing: 10) {
                TextField("郵便番号（ハイフンなし）", text: $postalCode)
                    .focused($focusedField, equals: .postalCode)
                    .textContentType(.postalCode)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .onChange(of: postalCode) { _, value in
                        let normalized = normalizedPostalCode(value)
                        if normalized != value {
                            postalCode = normalized
                        }
                        schedulePostalCodeLookup(normalized)
                    }

                if appState.isLookingUpPostalCode {
                    ProgressView()
                        .controlSize(.small)
                }
            }
                .megrumTextFieldStyle()

            TextField("都道府県", text: $prefecture)
                .focused($focusedField, equals: .prefecture)
                .textContentType(.addressState)
                .submitLabel(.next)
                .onSubmit { focusedField = .city }
                .megrumTextFieldStyle()

            TextField("市区町村", text: $city)
                .focused($focusedField, equals: .city)
                .textContentType(.addressCity)
                .submitLabel(.next)
                .onSubmit { focusedField = .line1 }
                .megrumTextFieldStyle()

            TextField("番地・建物名", text: $line1)
                .focused($focusedField, equals: .line1)
                .textContentType(.streetAddressLine1)
                .submitLabel(.next)
                .onSubmit { focusedField = .line2 }
                .megrumTextFieldStyle()

            TextField("補足住所（任意）", text: $line2)
                .focused($focusedField, equals: .line2)
                .textContentType(.streetAddressLine2)
                .submitLabel(.next)
                .onSubmit { focusedField = .phoneNumber }
                .megrumTextFieldStyle()

            TextField("電話番号（任意）", text: $phoneNumber)
                .focused($focusedField, equals: .phoneNumber)
                .textContentType(.telephoneNumber)
                #if os(iOS)
                .keyboardType(.phonePad)
                #endif
                .megrumTextFieldStyle()

            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(red: 0.851, green: 0.51, blue: 0.42).opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            HStack(spacing: 10) {
                if appState.isSavingMailingAddress {
                    ProgressView()
                        .controlSize(.small)
                }
                Text("保存する")
                    .font(.system(size: 16, weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 18))
        .tint(MegrumTheme.lavender)
        .disabled(appState.isSavingMailingAddress || !draftAddress.isReady)
    }

    private var draftAddress: MailingAddress {
        MailingAddress(
            userID: appState.viewer?.id ?? NativePreviewData.viewerID,
            recipientName: recipientName.trimmingCharacters(in: .whitespacesAndNewlines),
            postalCode: normalizedPostalCode(postalCode),
            prefecture: prefecture.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            line1: line1.trimmingCharacters(in: .whitespacesAndNewlines),
            line2: line2.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank,
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        )
    }

    private func save() async {
        focusedField = nil
        if await appState.saveMailingAddress(draftAddress) {
            dismiss()
        }
    }

    private func apply(address: MailingAddress?) {
        guard let address else {
            return
        }
        recipientName = address.recipientName
        postalCode = address.postalCode
        prefecture = address.prefecture
        city = address.city
        line1 = address.line1
        line2 = address.line2 ?? ""
        phoneNumber = address.phoneNumber ?? ""
        lastAppliedPostalCode = address.postalCode
    }

    private func normalizedPostalCode(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(7))
    }

    private func schedulePostalCodeLookup(_ value: String) {
        postalCodeLookupTask?.cancel()
        guard value.count == 7, value != lastAppliedPostalCode else {
            return
        }

        postalCodeLookupTask = Task { [value] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else {
                return
            }
            guard let address = await appState.lookupPostalCode(value) else {
                return
            }
            guard !Task.isCancelled else {
                return
            }
            prefecture = address.prefecture
            city = address.city
            line1 = address.line1Suggestion
            lastAppliedPostalCode = address.postalCode
        }
    }

    private enum Field {
        case recipientName
        case postalCode
        case prefecture
        case city
        case line1
        case line2
        case phoneNumber
    }
}

private extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}
