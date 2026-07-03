import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeProposalResponsePanel: View {
    var proposal: TradeProposal
    var viewerID: UUID?
    var isResponding: Bool
    var onAgree: (ExchangeMethod?) -> Void
    var onReject: () -> Void
    var onCounterProposal: () -> Void
    @State private var methodSelectionState = TradeAgreementMethodSelectionState()

    private var canAgree: Bool {
        guard let viewerID, proposal.isParticipant(viewerID) else {
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

    private var isWaitingForPartner: Bool {
        guard let viewerID, proposal.isParticipant(viewerID) else {
            return true
        }
        return proposal.agreementBy(viewerID) && !proposal.partnerAgreement(for: viewerID)
    }

    private var needsExchangeMethodChoice: Bool {
        proposal.exchangeMethod == .both
    }

    private var panelTitle: String {
        switch proposal.status {
        case .agreementOneSide:
            if isWaitingForPartner {
                return "相手の合意待ち"
            }
            return "あなたの合意待ち"
        case .negotiating:
            return "条件を相談中"
        case .sent:
            return "打診中"
        default:
            return "合意状況"
        }
    }

    private var panelSubtitle: String {
        guard let viewerID, proposal.isParticipant(viewerID) else {
            return "この打診の参加者だけが合意操作をできます。"
        }
        if proposal.agreementBy(viewerID), !proposal.partnerAgreement(for: viewerID) {
            return "あなたは合意済みです。相手の確認を待っています。"
        }
        if proposal.partnerAgreement(for: viewerID) {
            return "相手は合意済みです。内容を確認して進められます。"
        }
        return "双方の合意で取引フェーズへ進めます。"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(panelTitle)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(panelSubtitle)
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 7) {
                agreementStateChip(
                    text: myAgreed ? "私 合意済" : "私 未合意",
                    done: myAgreed
                )
                agreementStateChip(
                    text: partnerAgreed ? "相手 合意済" : "相手 未合意",
                    done: partnerAgreed
                )
            }

            if canAgree {
                if needsExchangeMethodChoice {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("交換手段を選ぶ")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                        Picker("交換手段", selection: $methodSelectionState.selectedExchangeMethod) {
                            Text(ExchangeMethod.hand.displayName).tag(ExchangeMethod.hand)
                            Text(ExchangeMethod.mail.displayName).tag(ExchangeMethod.mail)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Button {
                    onAgree(methodSelectionState.agreementExchangeMethod(needsChoice: needsExchangeMethodChoice))
                } label: {
                    Group {
                        if isResponding {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label("この内容で合意する", systemImage: "checkmark.circle.fill")
                        }
                    }
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(isResponding)

                Button(action: onCounterProposal) {
                    Label("条件を相談する", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.bordered)
                .tint(MegrumTheme.lavender)
                .disabled(isResponding)

                Button(role: .destructive, action: onReject) {
                    Label("見送る", systemImage: "xmark.circle")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.bordered)
                .disabled(isResponding)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: isWaitingForPartner ? "clock" : "checkmark.circle.fill")
                    Text(isWaitingForPartner ? "相手の合意を待っています" : "返答済みです")
                }
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.white.opacity(0.72), in: Capsule())
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(MegrumTheme.lavender.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.34), lineWidth: 1)
        }
    }

    private func agreementStateChip(text: String, done: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: done ? "checkmark.circle.fill" : "clock")
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .font(.system(size: 10.5, weight: .black, design: .rounded))
        .foregroundStyle(done ? MegrumTheme.ok : MegrumTheme.muted)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(done ? MegrumTheme.ok.opacity(0.12) : MegrumTheme.ink.opacity(0.06), in: Capsule())
    }
}
