import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct SettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onOpenNotificationDestination: (MegrumTab) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                NavigationLink {
                    NotificationsScreen(appState: appState) { tab in
                        dismiss()
                        onOpenNotificationDestination(tab)
                    }
                } label: {
                    Label {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("通知")
                                    .font(.body.weight(.semibold))
                                Text(notificationStatusText)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(MegrumTheme.muted)
                            }

                            Spacer()

                            if appState.unreadNotificationCount > 0 {
                                Text("\(appState.unreadNotificationCount)")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(MegrumTheme.pink, in: Capsule())
                            }
                        }
                    } icon: {
                        Image(systemName: "bell")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }

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
            if appState.notifications.isEmpty {
                await appState.loadNotifications()
            }
        }
    }

    private var notificationStatusText: String {
        guard !appState.notifications.isEmpty else {
            return "未読なし"
        }
        if appState.unreadNotificationCount > 0 {
            return "未読 \(appState.unreadNotificationCount)件"
        }
        return "すべて既読"
    }

    private var addressStatusText: String {
        guard let address = appState.mailingAddress, address.isReady else {
            return "未登録"
        }
        return address.summary
    }
}

private struct MeguriMessagePeerRoute: Identifiable, Hashable {
    var peerID: UUID

    var id: UUID { peerID }
}

@MainActor
private struct NotificationsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onOpenDestination: (MegrumTab) -> Void
    @State private var filter: NotificationFilter = .all
    @State private var selectedMeguriPeer: MeguriMessagePeerRoute?

    var body: some View {
        List {
            Section {
                Picker("表示", selection: $filter) {
                    ForEach(NotificationFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            Section {
                if appState.isLoadingNotifications {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        Text("通知を読み込んでいます")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                } else if visibleNotifications.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(emptyTitle)
                            .font(.headline.weight(.bold))
                        Text("打診、取引チャット、掲示板の更新がここにまとまります。")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(visibleNotifications) { notification in
                        NotificationRow(notification: notification) {
                            Task {
                                await appState.markNotificationRead(notification.id)
                                if let peerID = notification.meguriMessagePeerID {
                                    selectedMeguriPeer = MeguriMessagePeerRoute(peerID: peerID)
                                } else if let destination = MegrumTab(notificationLinkPath: notification.linkPath) {
                                    onOpenDestination(destination)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("\(visibleNotifications.count)件")
            }
        }
        .navigationTitle("通知")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if appState.unreadNotificationCount > 0 {
                    Button("すべて既読") {
                        Task {
                            await appState.markAllNotificationsRead()
                        }
                    }
                    .disabled(appState.isMarkingNotificationsRead)
                }
            }
        }
        .task {
            await appState.loadNotifications()
        }
        .refreshable {
            await appState.loadNotifications()
        }
        .navigationDestination(item: $selectedMeguriPeer) { route in
            MeguriMessagesScreen(appState: appState, peerID: route.peerID)
        }
    }

    private var visibleNotifications: [MegrumNotification] {
        switch filter {
        case .all:
            appState.notifications
        case .unread:
            appState.notifications.filter(\.isUnread)
        case .trades:
            appState.notifications.filter { $0.kind.isTradeRelated }
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .all:
            "まだ通知はありません"
        case .unread:
            "未読の通知はありません"
        case .trades:
            "取引の通知はありません"
        }
    }
}

@MainActor
private struct MeguriMessagesScreen: View {
    @ObservedObject var appState: MegrumAppState
    var peerID: UUID
    @State private var draft = ""

    private var messages: [MeguriMessage] {
        appState.meguriMessages(with: peerID)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if appState.isLoadingMeguriMessages {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("読み込んでいます")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(MegrumTheme.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)
                        } else if messages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("まだメッセージはありません")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(MegrumTheme.ink)
                                Text("グルームへの返信から、そのまま会話を始められます。")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(MegrumTheme.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)
                        } else {
                            ForEach(messages) { message in
                                MeguriMessageBubble(
                                    message: message,
                                    isMine: message.senderID == appState.viewer?.id
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 18)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in
                    guard let lastID = messages.last?.id else {
                        return
                    }
                    withAnimation(.snappy(duration: 0.24)) {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }

            MeguriMessageInput(
                text: $draft,
                isSending: appState.sendingMeguriMessageRecipientID == peerID
            ) {
                Task {
                    let sent = await appState.sendMeguriMessage(recipientID: peerID, body: draft)
                    if sent {
                        draft = ""
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle(peerTitle)
        .megrumInlineNavigationTitle()
        .task {
            await appState.loadMeguriMessages()
            await appState.markMeguriMessagesRead(peerID: peerID)
        }
    }

    private var peerTitle: String {
        for message in messages {
            if message.senderID == peerID {
                return displayName(name: message.senderDisplayName, handle: message.senderHandle)
            }
            if message.recipientID == peerID {
                return displayName(name: message.recipientDisplayName, handle: message.recipientHandle)
            }
        }
        return "めぐりメッセージ"
    }

    private func displayName(name: String?, handle: String?) -> String {
        if let name, !name.isEmpty {
            return name
        }
        if let handle, !handle.isEmpty {
            return "@\(handle)"
        }
        return "めぐりメッセージ"
    }
}

private struct MeguriMessageBubble: View {
    var message: MeguriMessage
    var isMine: Bool

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
            Text(messageText)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(isMine ? .white : MegrumTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )

            Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }

    private var messageText: String {
        if message.locked {
            return "このメッセージは現在表示できません"
        }
        if let body = message.body, !body.isEmpty {
            return body
        }
        return message.messageType == .image ? "画像" : ""
    }
}

private struct MeguriMessageInput: View {
    @Binding var text: String
    var isSending: Bool
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("メッセージ", text: $text, axis: .vertical)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button(action: onSend) {
                Group {
                    if isSending {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 17, weight: .heavy))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(MegrumTheme.lavender, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            .accessibilityLabel("送信")
        }
    }
}

private enum NotificationFilter: String, CaseIterable, Identifiable {
    case all
    case unread
    case trades

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "すべて"
        case .unread:
            "未読"
        case .trades:
            "取引"
        }
    }
}

private struct NotificationRow: View {
    var notification: MegrumNotification
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: notification.kind.symbolName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(notification.kind.tint)
                    .frame(width: 42, height: 42)
                    .background(notification.kind.tint.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(notification.title)
                            .font(.headline.weight(notification.isUnread ? .black : .bold))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(2)

                        Spacer(minLength: 8)

                        Text(relativeTimeText)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    if let body = notification.body, !body.isEmpty {
                        Text(body)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(3)
                    }
                }

                if notification.isUnread {
                    Circle()
                        .fill(MegrumTheme.pink)
                        .frame(width: 9, height: 9)
                        .padding(.top, 7)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(notification.title)
    }

    private var relativeTimeText: String {
        let seconds = max(0, Int(Date().timeIntervalSince(notification.createdAt)))
        let minutes = seconds / 60
        if minutes < 1 {
            return "今"
        }
        if minutes < 60 {
            return "\(minutes)分前"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)時間前"
        }
        let days = hours / 24
        if days < 7 {
            return "\(days)日前"
        }
        return notification.createdAt.formatted(.dateTime.month().day())
    }
}

private extension MegrumNotificationKind {
    var symbolName: String {
        switch self {
        case .proposalReceived:
            "envelope.badge"
        case .proposalAccepted, .tradeCompleted:
            "checkmark.circle"
        case .proposalRejected:
            "xmark.circle"
        case .proposalRevised:
            "pencil.circle"
        case .evidenceAdded:
            "camera"
        case .evaluationReceived:
            "star"
        case .disputeReceived, .disputeResponded, .disputeClosed, .cancelRequested:
            "exclamationmark.triangle"
        case .expiresSoon:
            "clock"
        case .groomReply, .meguriMessage:
            "message"
        case .meguriBoardReply, .meguriBoardMention:
            "text.bubble"
        case .unknown:
            "bell"
        }
    }

    var tint: Color {
        switch self {
        case .proposalAccepted, .tradeCompleted:
            Color.green
        case .proposalRejected, .disputeReceived, .disputeResponded, .disputeClosed, .cancelRequested:
            Color.orange
        case .evaluationReceived, .meguriBoardMention, .expiresSoon:
            MegrumTheme.pink
        default:
            MegrumTheme.lavender
        }
    }

    var isTradeRelated: Bool {
        switch self {
        case .proposalReceived, .proposalAccepted, .proposalRejected, .proposalRevised,
             .evidenceAdded, .tradeCompleted, .evaluationReceived, .disputeReceived,
             .disputeResponded, .disputeClosed, .cancelRequested, .expiresSoon:
            true
        case .groomReply, .meguriMessage, .meguriBoardReply, .meguriBoardMention, .unknown:
            false
        }
    }
}

private extension MegrumTab {
    init?(notificationLinkPath: String?) {
        guard let linkPath = notificationLinkPath?.lowercased(), !linkPath.isEmpty else {
            return nil
        }
        if linkPath.contains("meguri") || linkPath.contains("groom") {
            self = .meguri
        } else if linkPath.contains("proposal")
            || linkPath.contains("trade")
            || linkPath.contains("deal")
            || linkPath.contains("dispute") {
            self = .trades
        } else if linkPath.contains("inventory") || linkPath.contains("goods") {
            self = .inventory
        } else if linkPath.contains("wish") {
            self = .wish
        } else {
            self = .home
        }
    }
}

private extension MegrumNotification {
    var meguriMessagePeerID: UUID? {
        guard kind == .groomReply || kind == .meguriMessage else {
            return nil
        }
        guard let linkPath, !linkPath.isEmpty else {
            return nil
        }

        if let components = URLComponents(string: linkPath) {
            for item in components.queryItems ?? [] {
                let key = item.name.lowercased()
                if (key == "userid" || key == "user_id" || key == "peerid" || key == "peer_id"),
                   let value = item.value,
                   let id = UUID(uuidString: value) {
                    return id
                }
            }
        }

        let separators = CharacterSet(charactersIn: "/?&=#")
        return linkPath
            .components(separatedBy: separators)
            .compactMap { UUID(uuidString: $0) }
            .first
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
