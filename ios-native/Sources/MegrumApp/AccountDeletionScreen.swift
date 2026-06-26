import MegrumDesign
import SwiftUI

@MainActor
struct AccountDeletionScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onCompleted: () -> Void
    @FocusState private var isNoteFocused: Bool
    @State private var step: AccountDeletionStep = .warning
    @State private var selectedReasons: Set<AccountDeletionReason> = []
    @State private var note = ""
    @State private var validationMessage: String?
    @State private var showsFinalConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                switch step {
                case .warning:
                    AccountDeletionWarningContent(ongoingTradeCount: ongoingTradeCount)
                case .reasons:
                    reasonForm
                }

                validationErrorView
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 108)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("退会")
        .megrumInlineNavigationTitle()
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    isNoteFocused = false
                }
                .font(.body.weight(.semibold))
            }
            #endif
        }
        .confirmationDialog(
            "退会しますか？",
            isPresented: $showsFinalConfirmation,
            titleVisibility: .visible
        ) {
            Button("退会する", role: .destructive) {
                submit()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("退会申請後はアカウントが削除申請中になり、Megrumの通常利用ができなくなります。")
        }
        .onChange(of: selectedReasons) {
            validationMessage = nil
        }
        .onChange(of: note) {
            validationMessage = nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(step.stepText)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
            Text(step.title)
                .font(.system(size: 27, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text(step.subtitle)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineSpacing(3)
        }
    }

    private var reasonForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 0) {
                ForEach(AccountDeletionReason.allCases) { reason in
                    AccountDeletionReasonRow(
                        reason: reason,
                        isSelected: selectedReasons.contains(reason)
                    ) {
                        toggle(reason)
                    }
                    if reason != AccountDeletionReason.allCases.last {
                        Divider()
                            .padding(.leading, 18)
                    }
                }
            }
            .accountDeletionCardStyle()

            VStack(alignment: .leading, spacing: 10) {
                Text("メモ")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: noteBinding)
                        .focused($isNoteFocused)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(minHeight: 128)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .scrollContentBackground(.hidden)
                        .background(MegrumTheme.canvas, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    if note.isEmpty {
                        Text("任意で詳しく教えてください")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted.opacity(0.62))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
                }

                HStack {
                    Text("個人情報や取引相手を特定できる内容は書かないでください。")
                    Spacer()
                    Text("\(note.count)/\(AccountDeletionDraftValidator.noteMaxLength)")
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            }
            .accountDeletionCardStyle()
        }
    }

    @ViewBuilder
    private var validationErrorView: some View {
        if let validationMessage {
            AccountDeletionAlertLabel(message: validationMessage)
        } else if let errorMessage = appState.errorMessage {
            AccountDeletionAlertLabel(message: errorMessage)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 14) {
            if step == .reasons {
                Button("戻る") {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        step = .warning
                    }
                }
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }

            Button {
                primaryAction()
            } label: {
                HStack(spacing: 10) {
                    if appState.isRequestingAccountDeletion {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    Text(step.primaryButtonTitle)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(primaryButtonBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(isPrimaryButtonDisabled)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(.white.opacity(0.96))
    }

    private var primaryButtonBackground: Color {
        if isPrimaryButtonDisabled {
            return MegrumTheme.muted.opacity(0.34)
        }
        return step == .warning ? MegrumTheme.lavender : Color(red: 0.86, green: 0.29, blue: 0.38)
    }

    private var isPrimaryButtonDisabled: Bool {
        if appState.isRequestingAccountDeletion {
            return true
        }
        return step == .warning && ongoingTradeCount > 0
    }

    private var ongoingTradeCount: Int {
        AccountDeletionEligibility
            .ongoingProposals(in: appState.proposals, viewerID: appState.viewer?.id)
            .count
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { note },
            set: { note = String($0.prefix(AccountDeletionDraftValidator.noteMaxLength)) }
        )
    }

    private func primaryAction() {
        switch step {
        case .warning:
            guard ongoingTradeCount == 0 else {
                validationMessage = "現在進行中の取引があるため退会できません"
                return
            }
            withAnimation(.easeInOut(duration: 0.18)) {
                step = .reasons
            }
        case .reasons:
            if let message = AccountDeletionDraftValidator.validationMessage(
                reasons: Array(selectedReasons),
                note: note
            ) {
                validationMessage = message
                return
            }
            isNoteFocused = false
            showsFinalConfirmation = true
        }
    }

    private func submit() {
        let input = AccountDeletionRequestInput(
            reasons: Array(selectedReasons),
            note: note
        ).normalized

        Task {
            if await appState.requestAccountDeletion(input) {
                onCompleted()
            }
        }
    }

    private func toggle(_ reason: AccountDeletionReason) {
        if selectedReasons.contains(reason) {
            selectedReasons.remove(reason)
        } else {
            selectedReasons.insert(reason)
        }
        MegrumHaptics.selectionChanged()
    }
}

private enum AccountDeletionStep: Equatable {
    case warning
    case reasons

    var stepText: String {
        switch self {
        case .warning:
            "1/2"
        case .reasons:
            "2/2"
        }
    }

    var title: String {
        switch self {
        case .warning:
            "退会前に確認してください"
        case .reasons:
            "退会理由を教えてください"
        }
    }

    var subtitle: String {
        switch self {
        case .warning:
            "退会するとMegrumの通常利用ができなくなります。大事な取引が残っていないか確認してください。"
        case .reasons:
            "今後の改善のため、当てはまる理由を選んでください。メモは任意です。"
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .warning:
            "理由入力へ進む"
        case .reasons:
            "退会する"
        }
    }
}

private struct AccountDeletionWarningContent: View {
    var ongoingTradeCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AccountDeletionWarningRow(
                systemImage: "person.crop.circle.badge.xmark",
                title: "アカウントが使えなくなります",
                detail: "表示名、ユーザーID、プロフィール、推し設定などをMegrum上で使えなくなります。"
            )
            AccountDeletionWarningRow(
                systemImage: "shippingbox.circle",
                title: "グッズ・Wishの情報を確認できなくなります",
                detail: "登録したグッズ、Wish、交換条件、通知設定などは通常画面から参照できなくなります。"
            )
            AccountDeletionWarningRow(
                systemImage: "checkmark.shield",
                title: "安全確認に必要な記録は残る場合があります",
                detail: "取引チャット、証跡、評価、通報対応に必要な記録は、規約対応と安全確認のため一定期間保持される場合があります。"
            )
            AccountDeletionWarningRow(
                systemImage: "arrow.left.arrow.right.circle",
                title: "進行中の取引がある場合は退会できません",
                detail: "取引完了またはキャンセル後に、もう一度退会手続きをしてください。"
            )

            if ongoingTradeCount > 0 {
                AccountDeletionBlockedBanner(ongoingTradeCount: ongoingTradeCount)
            }
        }
        .accountDeletionCardStyle()
    }
}

private struct AccountDeletionWarningRow: View {
    var systemImage: String
    var title: String
    var detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(detail)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct AccountDeletionBlockedBanner: View {
    var ongoingTradeCount: Int

    var body: some View {
        Label {
            Text("現在進行中の取引が\(ongoingTradeCount)件あるため退会できません。")
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.system(size: 14, weight: .black, design: .rounded))
        .foregroundStyle(Color(red: 0.86, green: 0.29, blue: 0.38))
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 1.0, green: 0.94, blue: 0.95), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct AccountDeletionReasonRow: View {
    var reason: AccountDeletionReason
    var isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.55))

                Text(reason.displayName)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(reason.displayName)、\(isSelected ? "選択中" : "未選択")")
    }
}

private struct AccountDeletionAlertLabel: View {
    var message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
            .fixedSize(horizontal: false, vertical: true)
    }
}

private extension View {
    func accountDeletionCardStyle() -> some View {
        padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: MegrumTheme.lavender.opacity(0.07), radius: 18, y: 10)
    }
}
