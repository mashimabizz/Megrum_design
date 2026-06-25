import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

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
