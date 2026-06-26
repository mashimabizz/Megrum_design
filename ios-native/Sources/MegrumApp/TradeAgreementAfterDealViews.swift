import MegrumCore
import MegrumDesign
import SwiftUI

enum TradeAgreementDisclosureRoute: String, Identifiable {
    case mailingAddress
    case paymentInfo

    var id: String { rawValue }
}

struct TradeAgreementDisclosureActionsCard: View {
    var showsMailingInfo: Bool
    var showsPaymentInfo: Bool
    var onOpenMailingInfo: () -> Void
    var onOpenPaymentInfo: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if showsMailingInfo {
                TradeAgreementDisclosureButton(
                    title: "郵送先",
                    systemImage: "lock.fill",
                    action: onOpenMailingInfo
                )
            }
            if showsPaymentInfo {
                TradeAgreementDisclosureButton(
                    title: "支払い情報",
                    systemImage: "yensign.circle.fill",
                    action: onOpenPaymentInfo
                )
            }
        }
        .padding(10)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct TradeAgreementDisclosureButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.48), lineWidth: 1.2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityHint("成立後に公開された\(title)を確認します")
    }
}

struct TradeAgreementSystemTimeline: View {
    var proposal: TradeProposal
    var partnerPaymentMethods: [UserPaymentMethod]
    var partnerPaymentNote: String?
    var partnerMailingAddress: TradeMailingAddressSnapshot?
    var partnerPaymentSettings: TradePaymentSettingsSnapshot?
    var onOpenMailingInfo: () -> Void
    var onOpenPaymentInfo: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Label(agreementTitle, systemImage: "sparkles")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)

            if showsAgreementDetails {
                timelineDot
            }

            if supportsMailExchange {
                TradeAgreementTimelineActionRow(
                    title: "郵送先が公開されました",
                    actionTitle: "見る",
                    isAvailable: true,
                    unavailableTitle: "",
                    action: onOpenMailingInfo
                )

                if showsPaymentInfo {
                    timelineDot
                }
            }

            if showsPaymentInfo {
                TradeAgreementTimelineActionRow(
                    title: "支払い情報が公開されました",
                    actionTitle: "見る",
                    isAvailable: true,
                    unavailableTitle: "",
                    action: onOpenPaymentInfo
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .accessibilityElement(children: .contain)
    }

    private var agreementTitle: String {
        "\(proposal.exchangeMethod.displayName)で取引が成立しました"
    }

    private var supportsMailExchange: Bool {
        proposal.exchangeMethod == .mail || proposal.exchangeMethod == .both
    }

    private var showsPaymentInfo: Bool {
        proposal.cashOffer || !partnerPaymentMethods.isEmpty || partnerPaymentNote.nilIfBlank != nil
    }

    private var showsAgreementDetails: Bool {
        supportsMailExchange || showsPaymentInfo
    }

    private var timelineDot: some View {
        Circle()
            .fill(MegrumTheme.muted.opacity(0.32))
            .frame(width: 7, height: 7)
            .accessibilityHidden(true)
    }
}

private struct TradeAgreementTimelineActionRow: View {
    var title: String
    var actionTitle: String
    var isAvailable: Bool
    var unavailableTitle: String
    var action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(isAvailable ? title : unavailableTitle)
                .font(.system(size: 13.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)

            if isAvailable {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct TradeAgreementDisclosureSheet: View {
    var route: TradeAgreementDisclosureRoute
    var proposal: TradeProposal
    var partnerHandle: String
    var partnerMailingAddress: TradeMailingAddressSnapshot?
    var partnerPaymentMethods: [UserPaymentMethod]
    var partnerPaymentNote: String?
    var partnerPaymentSettings: TradePaymentSettingsSnapshot?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    content
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle(routeTitle)
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(routeTitle, systemImage: routeIconName)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text("@\(partnerHandle) から成立後に公開された情報です。")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .mailingAddress:
            mailingAddressContent
        case .paymentInfo:
            paymentInfoContent
        }
    }

    private var mailingAddressContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if supportsMailExchange {
                if let partnerMailingAddress {
                    TradeAgreementDisclosureInfoRow(title: "宛名", value: partnerMailingAddress.recipientName)
                    TradeAgreementDisclosureInfoRow(title: "郵便番号", value: partnerMailingAddress.formattedPostalCode)
                    TradeAgreementDisclosureInfoRow(title: "住所", value: partnerMailingAddress.addressLine)
                    TradeAgreementDisclosureInfoRow(title: "電話番号", value: partnerMailingAddress.phoneNumberText)
                } else {
                    TradeAgreementDisclosureInfoRow(title: "ステータス", value: "公開待ち")
                    Text("成立時の郵送先スナップショットがまだ取得できていません。")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ContentUnavailableView(
                    "郵送先は不要です",
                    systemImage: "mappin.and.ellipse",
                    description: Text("この取引は現地交換のため、郵送先の開示はありません。")
                )
            }
        }
        .tradeAgreementDisclosureCardStyle()
    }

    private var paymentInfoContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            TradeAgreementDisclosureInfoRow(
                title: "支払い方法",
                value: UserPaymentMethod.displayText(
                    for: partnerPaymentMethods,
                    otherNote: partnerPaymentNote,
                    emptyText: proposal.cashOffer ? "未設定" : "支払いなし"
                )
            )

            if partnerPaymentMethods.contains(.bankTransfer) {
                if let partnerPaymentSettings, partnerPaymentSettings.hasBankTransferDetails {
                    TradeAgreementDisclosureInfoRow(title: "銀行名", value: partnerPaymentSettings.bankName)
                    TradeAgreementDisclosureInfoRow(title: "支店名", value: partnerPaymentSettings.bankBranchName)
                    TradeAgreementDisclosureInfoRow(title: "口座種別", value: partnerPaymentSettings.bankAccountType)
                    TradeAgreementDisclosureInfoRow(title: "口座番号", value: partnerPaymentSettings.bankAccountNumber)
                    TradeAgreementDisclosureInfoRow(title: "口座名義", value: partnerPaymentSettings.bankAccountHolder)
                } else {
                    TradeAgreementDisclosureInfoRow(title: "振込先", value: "未取得")
                    Text("成立時の支払い情報スナップショットがまだ取得できていません。")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if !proposal.cashOffer {
                Text("この取引は物々交換として成立しているため、支払い情報は不要です。")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else if partnerPaymentMethods.isEmpty {
                Text("相手の支払い情報はまだ取得できていません。")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tradeAgreementDisclosureCardStyle()
    }

    private var routeTitle: String {
        switch route {
        case .mailingAddress:
            "郵送先"
        case .paymentInfo:
            "支払い情報"
        }
    }

    private var routeIconName: String {
        switch route {
        case .mailingAddress:
            "shippingbox.fill"
        case .paymentInfo:
            "yensign.circle.fill"
        }
    }

    private var supportsMailExchange: Bool {
        proposal.exchangeMethod == .mail || proposal.exchangeMethod == .both
    }
}

private struct TradeAgreementDisclosureInfoRow: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TradeAgreementNextStepFooter: View {
    var isAddingEvidence: Bool
    var action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.sky],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 15)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text("次のステップ")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                Text("交換したら証跡写真を撮る")
                    .font(.system(size: 16.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }

            Spacer(minLength: 6)

            Button(action: action) {
                HStack(spacing: 7) {
                    if isAddingEvidence {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 13, weight: .black))
                    }
                    Text("撮る")
                        .lineLimit(1)
                }
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 15)
                .frame(minHeight: 42)
                .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(isAddingEvidence)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(MegrumTheme.lavender.opacity(0.22), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("次のステップ。交換したら証跡写真を撮る")
        .accessibilityHint("撮るボタンで写真を撮るかアルバムから選ぶかを選択できます")
    }
}

struct TradeEvaluationNextStepFooter: View {
    var isSubmitting: Bool
    var action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 21, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 3) {
                Text("次のステップ")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                Text("評価を入力する")
                    .font(.system(size: 16.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button(action: action) {
                HStack(spacing: 7) {
                    if isSubmitting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 14, weight: .black))
                    }
                    Text("評価入力")
                        .lineLimit(1)
                }
                .font(.system(size: 13.5, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(minHeight: 42)
                .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(MegrumTheme.lavender.opacity(0.22), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("次のステップ。評価を入力する")
    }
}

private extension View {
    func tradeAgreementDisclosureCardStyle() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
            }
    }
}
