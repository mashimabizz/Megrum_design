import Foundation
import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI

struct TradeDetailContent: View {
    var proposal: TradeProposal
    var messages: [TradeMessage]
    var viewerID: UUID?
    var heroPresentation: TradeDetailHeroPresentation
    var latestDisputeSummary: TradeDisputeSummary?
    var tradeSummaryLine: String
    var requestedGoods: [GoodsItem]
    var offeredGoods: [GoodsItem]
    var requestedGoodsCount: Int
    var offeredGoodsCount: Int
    var partnerPaymentMethods: [UserPaymentMethod]
    var partnerPaymentNote: String?
    var partnerMailingAddress: TradeMailingAddressSnapshot?
    var partnerPaymentSettings: TradePaymentSettingsSnapshot?
    var viewerPaymentMethods: [UserPaymentMethod]
    var viewerPaymentNote: String?
    var viewerHasCounterProposal: Bool
    var isMessageComposerFocused: Bool
    var evidencePhotos: [TradeEvidencePhoto]
    @Binding var selectedEvidencePhotoItem: PhotosPickerItem?
    var partnerLastReadAt: Date?
    var evaluationState: TradeEvaluationPromptState
    var isResponding: Bool
    var isLoadingMessages: Bool
    var isApprovingCancel: Bool
    var isAddingEvidence: Bool
    var isApprovingEvidence: Bool
    var canUseCamera: Bool
    var onOpenDispute: (TradeDisputeSummary) -> Void
    var onOpenPartnerProfile: () -> Void
    var onAgree: (ExchangeMethod?) -> Void
    var onReject: () -> Void
    var onCounterProposal: () -> Void
    var onOpenEvidenceCamera: () -> Void
    var onOpenEvidenceList: () -> Void
    var onOpenImage: (URL) -> Void
    var onReplyToMessage: (TradeMessage) -> Void = { _ in }
    var onReportMessage: (TradeMessage) -> Void = { _ in }
    var onOpenEvidencePhoto: (TradeEvidencePhoto) -> Void
    var onApproveEvidence: (TradeEvidencePhoto) -> Void
    var onRate: () -> Void
    var onApproveCancel: () -> Void
    @State private var agreementDisclosureRoute: TradeAgreementDisclosureRoute?
    /// iter1226.463：描画するのは最新N件だけ。上へ遡るたびに1ページ分ずつ広げる
    /// （めぐりメッセージと同じページング）。
    @State private var visibleMessageCount = TradeDetailContent.messagePageSize
    static let messagePageSize = 20

    /// 表示ウィンドウ（最新 visibleMessageCount 件）。
    private var windowedMessages: [TradeMessage] {
        Array(messages.suffix(visibleMessageCount))
    }

    var body: some View {
        VStack(spacing: 0) {
            TradeChatPartnerStrip(
                presentation: heroPresentation,
                onOpenProfile: onOpenPartnerProfile
            )
                .padding(.horizontal, 16)
                .padding(.top, 7)
                .padding(.bottom, 8)

            Divider()
                .overlay(MegrumTheme.ink.opacity(0.08))

            TradeDetailPinnedSummaryArea(
                proposal: proposal,
                viewerID: viewerID,
                latestDisputeSummary: latestDisputeSummary,
                tradeSummaryLine: tradeSummaryLine,
                requestedGoods: requestedGoods,
                offeredGoods: offeredGoods,
                requestedGoodsCount: requestedGoodsCount,
                offeredGoodsCount: offeredGoodsCount,
                partnerPaymentMethods: partnerPaymentMethods,
                partnerPaymentNote: partnerPaymentNote,
                viewerPaymentMethods: viewerPaymentMethods,
                viewerPaymentNote: viewerPaymentNote,
                viewerHasCounterProposal: viewerHasCounterProposal,
                isMessageComposerFocused: isMessageComposerFocused,
                isResponding: isResponding,
                onOpenDispute: onOpenDispute,
                onOpenMailingInfo: {
                    agreementDisclosureRoute = .mailingAddress
                },
                onOpenPaymentInfo: {
                    agreementDisclosureRoute = .paymentInfo
                },
                onAgree: onAgree,
                onReject: onReject,
                onCounterProposal: onCounterProposal
            )

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        TradeDetailMessagesSection(
                            proposal: proposal,
                            messages: windowedMessages,
                            hasOlderMessages: messages.count > windowedMessages.count,
                            onLoadOlder: {
                                // iter1226.463：上端到達→1ページ分広げ、直前の先頭位置へ無アニメ復元。
                                guard let anchorID = windowedMessages.first?.id else {
                                    return
                                }
                                visibleMessageCount += TradeDetailContent.messagePageSize
                                DispatchQueue.main.async {
                                    var transaction = Transaction()
                                    transaction.disablesAnimations = true
                                    withTransaction(transaction) {
                                        proxy.scrollTo(anchorID, anchor: .top)
                                    }
                                }
                            },
                            viewerID: viewerID,
                            evaluationState: evaluationState,
                            partnerLastReadAt: partnerLastReadAt,
                            partnerPaymentMethods: partnerPaymentMethods,
                            partnerPaymentNote: partnerPaymentNote,
                            partnerMailingAddress: partnerMailingAddress,
                            partnerPaymentSettings: partnerPaymentSettings,
                            isLoading: isLoadingMessages,
                            isApprovingCancel: isApprovingCancel,
                            onOpenImage: onOpenImage,
                            onReply: onReplyToMessage,
                            onReportMessage: onReportMessage,
                            partnerAvatarURL: heroPresentation.partnerAvatarURL,
                            onJumpToMessage: { messageID in
                                // 引用元がウィンドウ外（古いページ）ならウィンドウを広げてからジャンプ。
                                if !windowedMessages.contains(where: { $0.id == messageID }),
                                   let index = messages.firstIndex(where: { $0.id == messageID }) {
                                    visibleMessageCount = messages.count - index + TradeDetailContent.messagePageSize / 2
                                    DispatchQueue.main.async {
                                        withAnimation(.snappy(duration: 0.3)) {
                                            proxy.scrollTo(messageID, anchor: .center)
                                        }
                                    }
                                    return
                                }
                                withAnimation(.snappy(duration: 0.3)) {
                                    proxy.scrollTo(messageID, anchor: .center)
                                }
                            },
                            onOpenDispute: onOpenDispute,
                            onOpenMailingInfo: {
                                agreementDisclosureRoute = .mailingAddress
                            },
                            onOpenPaymentInfo: {
                                agreementDisclosureRoute = .paymentInfo
                            },
                            onOpenEvidenceList: onOpenEvidenceList,
                            onApproveCancel: onApproveCancel
                        )
                        TradeDetailEvidenceSection(
                            proposal: proposal,
                            viewerID: viewerID,
                            evidencePhotos: evidencePhotos,
                            selectedPhotoItem: $selectedEvidencePhotoItem,
                            evaluationState: evaluationState,
                            isAddingEvidence: isAddingEvidence,
                            isApproving: isApprovingEvidence,
                            canUseCamera: canUseCamera,
                            onOpenCamera: onOpenEvidenceCamera,
                            onOpenEvidenceList: onOpenEvidenceList,
                            onOpenImage: onOpenEvidencePhoto,
                            onApprove: onApproveEvidence,
                            onRate: onRate
                        )
                        Color.clear
                            .frame(height: 1)
                            .id(Self.messageBottomAnchorID)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 12)
                    .padding(.bottom, scrollContentBottomSpacing)
                }
                .onAppear {
                    scrollToLatestMessage(proxy, animated: false)
                }
                .onChange(of: messages.last?.id) { _, _ in
                    scrollToLatestMessage(proxy, animated: true)
                }
                .onChange(of: isLoadingMessages) { _, isLoading in
                    if !isLoading {
                        scrollToLatestMessage(proxy, animated: false)
                    }
                }
                .onChange(of: proposal.id) { _, _ in
                    // iter1226.463：別のやりとりへ切り替わったらウィンドウを最新20件へ戻す。
                    visibleMessageCount = TradeDetailContent.messagePageSize
                }
            }
        }
        .sheet(item: $agreementDisclosureRoute) { route in
            TradeAgreementDisclosureSheet(
                route: route,
                proposal: proposal,
                partnerHandle: heroPresentation.partnerHandle,
                partnerMailingAddress: partnerMailingAddress,
                partnerPaymentMethods: partnerPaymentMethods,
                partnerPaymentNote: partnerPaymentNote,
                partnerPaymentSettings: partnerPaymentSettings
            )
        }
    }

    private static let messageBottomAnchorID = "trade-detail-message-bottom-anchor"

    private var scrollContentBottomSpacing: CGFloat {
        12
    }

    private func scrollToLatestMessage(_ proxy: ScrollViewProxy, animated: Bool) {
        guard !messages.isEmpty else {
            return
        }
        let action = {
            proxy.scrollTo(Self.messageBottomAnchorID, anchor: .bottom)
        }
        if animated {
            withAnimation(.snappy(duration: 0.28)) {
                action()
            }
        } else {
            action()
        }
    }
}
