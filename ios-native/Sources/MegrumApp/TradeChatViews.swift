import Foundation
import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI

struct TradeChatPartnerStrip: View {
    var presentation: TradeDetailHeroPresentation
    var onOpenProfile: () -> Void = {}

    var body: some View {
        Button(action: onOpenProfile) {
            HStack(spacing: 10) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                MegrumTheme.lavender.opacity(0.42),
                                MegrumTheme.sky.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                    .overlay {
                        Text(presentation.partnerInitial)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text("@\(presentation.partnerHandle)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(MegrumTheme.muted.opacity(0.42))
                            .frame(width: 4.5, height: 4.5)
                        Text(presentation.partnerMetaText)
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                }

                Spacer(minLength: 8)

                Text(presentation.agreementLabel)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(statusForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusBackground, in: Capsule())
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("@\(presentation.partnerHandle)。\(presentation.partnerMetaText)。\(presentation.agreementLabel)")
        .accessibilityHint("プロフィールを開きます")
    }

    private var statusForeground: Color {
        switch presentation.statusLabel {
        case "取引予定", "完了":
            return MegrumTheme.ok
        case "見送り", "キャンセル", "期限切れ":
            return MegrumTheme.muted
        default:
            return MegrumTheme.lavender
        }
    }

    private var statusBackground: Color {
        switch presentation.statusLabel {
        case "取引予定", "完了":
            return MegrumTheme.ok.opacity(0.15)
        case "見送り", "キャンセル", "期限切れ":
            return MegrumTheme.ink.opacity(0.06)
        default:
            return MegrumTheme.lavender.opacity(0.14)
        }
    }
}

struct TradeCollapsedSummaryCard: View {
    var label: String
    var summary: String
    var systemImage: String
    var action: (() -> Void)?

    var body: some View {
        if let action {
            Button(action: action) {
                cardContent
            }
            .buttonStyle(.plain)
            .accessibilityHint("詳細を開きます")
        } else {
            cardContent
        }
    }

    private var cardContent: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 22, height: 22)
                .background(MegrumTheme.lavender.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            Text(label)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)

            Text(summary)
                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Spacer(minLength: 4)

            Text("詳細")
                .font(.system(size: 10.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.14), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

struct TradeChatTimestampDivider: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10.5, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.78), in: Capsule())
            .frame(maxWidth: .infinity)
            .accessibilityLabel("メッセージ日時 \(text)")
    }
}

struct TradeAgreementCompactBar: View {
    var proposal: TradeProposal
    var viewerID: UUID?
    var isResponding: Bool
    var onAgree: (ExchangeMethod?) -> Void
    var onReject: () -> Void
    var onCounterProposal: () -> Void
    @State private var selectedExchangeMethod: ExchangeMethod = .hand

    private var isInitialSenderWaiting: Bool {
        guard let viewerID else {
            return false
        }
        return proposal.status == .sent && proposal.isSender(viewerID)
    }

    private var canAgree: Bool {
        guard let viewerID, proposal.isParticipant(viewerID), !isInitialSenderWaiting else {
            return false
        }
        return !proposal.agreementBy(viewerID)
    }

    private var myAgreed: Bool {
        viewerID.map { proposal.agreementBy($0) } ?? false
    }

    private var partnerAgreed: Bool {
        viewerID.map { proposal.partnerAgreement(for: $0) } ?? false
    }

    private var needsExchangeMethodChoice: Bool {
        proposal.exchangeMethod == .both && canAgree
    }

    private var statusText: String {
        if isInitialSenderWaiting {
            return "相手の返信待ちです"
        }
        if myAgreed {
            return "あなたは承認済み。相手の承認待ちです。"
        }
        if partnerAgreed {
            return "相手は承認済み。内容を確認してください。"
        }
        return "双方の合意で取引フェーズへ進めます。"
    }

    private var acceptText: String {
        if isInitialSenderWaiting {
            return "相手の返信待ち"
        }
        if myAgreed {
            return "承認済み"
        }
        if partnerAgreed {
            return "承認へ"
        }
        return "承認へ"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(MegrumTheme.lavender)
                Text(statusText)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                Spacer(minLength: 6)
            }

            if needsExchangeMethodChoice {
                Picker("交換手段", selection: $selectedExchangeMethod) {
                    Text(ExchangeMethod.hand.displayName).tag(ExchangeMethod.hand)
                    Text(ExchangeMethod.mail.displayName).tag(ExchangeMethod.mail)
                }
                .pickerStyle(.segmented)
            }

            HStack(spacing: 8) {
                Button(role: .destructive, action: onReject) {
                    Text("見送る")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isResponding || myAgreed)

                Button(action: onCounterProposal) {
                    Text("調整")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(MegrumTheme.lavender)
                .disabled(isResponding || myAgreed)

                Button {
                    onAgree(needsExchangeMethodChoice ? selectedExchangeMethod : nil)
                } label: {
                    HStack(spacing: 5) {
                        if isResponding {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .black))
                        }
                        Text(acceptText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(canAgree ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.36), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isResponding || !canAgree)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MegrumTheme.lavender.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
        }
    }
}

struct TradeUnavailableChatActionSheet: View {
    var action: TradeUnavailableChatAction
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ContentUnavailableView {
            Label(action.title, systemImage: action.systemImage)
        } description: {
            Text(action.description)
        } actions: {
            Button("閉じる") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(MegrumTheme.lavender)
        }
        .navigationTitle(action.title)
        .megrumInlineNavigationTitle()
    }
}

struct TradeAssistanceRequestSheet: View {
    var kind: TradeAssistanceRequestKind
    var isSubmitting: Bool
    var onSubmit: (TradeAssistanceSystemIntent) async -> Void

    @State private var draft: TradeAssistanceRequestDraft

    init(
        kind: TradeAssistanceRequestKind,
        isSubmitting: Bool,
        onSubmit: @escaping (TradeAssistanceSystemIntent) async -> Void
    ) {
        self.kind = kind
        self.isSubmitting = isSubmitting
        self.onSubmit = onSubmit
        self._draft = State(initialValue: TradeAssistanceRequestDraft(kind: kind))
    }

    var body: some View {
        Form {
            Section {
                Label(kind.title, systemImage: kind.systemImage)
                    .font(.headline)
                    .foregroundStyle(MegrumTheme.ink)

                if kind == .late {
                    Picker("遅れる見込み", selection: $draft.delayBucket) {
                        ForEach(TradeLateDelayBucket.allCases) { bucket in
                            Text(bucket.title)
                                .tag(bucket)
                                .accessibilityLabel(bucket.accessibilityLabel)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("遅れる見込み")
                }
            } footer: {
                Text(kind.acknowledgementText)
            }

            Section("理由") {
                TextEditor(text: $draft.reason)
                    .frame(minHeight: 132)
                    .overlay(alignment: .topLeading) {
                        if draft.reason.isEmpty {
                            Text(kind.reasonPlaceholder)
                                .foregroundStyle(MegrumTheme.muted)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                    .accessibilityLabel(kind.reasonAccessibilityLabel)
            }

            Section {
                TextEditor(text: $draft.note)
                    .frame(minHeight: 96)
                    .overlay(alignment: .topLeading) {
                        if draft.note.isEmpty {
                            Text(kind.notePlaceholder)
                                .foregroundStyle(MegrumTheme.muted)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                    .accessibilityLabel(kind.noteAccessibilityLabel)
            } header: {
                Text("補足")
            } footer: {
                Text("補足は任意です。送信後は取引チャットにシステムメッセージとして残ります。")
            }

            Section {
                Toggle(kind.acknowledgementText, isOn: $draft.acknowledgesImpact)
                    .accessibilityLabel(kind.acknowledgementAccessibilityLabel)
            }

            if let intent = draft.systemIntent {
                Section("取引チャットへの反映文") {
                    Text(intent.messageBody)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(MegrumTheme.ink)
                        .accessibilityLabel("\(kind.title)の送信内容")
                }
            }
        }
        .navigationTitle(kind.title)
        .megrumInlineNavigationTitle()
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        guard let intent = draft.systemIntent else {
                            return
                        }
                        await onSubmit(intent)
                    }
                } label: {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("送信")
                    }
                }
                .disabled(!draft.isSubmittable || isSubmitting)
            }
        }
    }
}
