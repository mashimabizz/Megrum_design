import MegrumCore
import MegrumDesign
import SwiftUI

extension TradeDetailScreen {
    var bodyBeforeDialogs: some View {
        TradeDetailContent(
            proposal: currentProposal,
            messages: messages,
            viewerID: viewerID,
            heroPresentation: heroPresentation,
            latestDisputeSummary: latestDisputeSummary,
            tradeSummaryLine: tradeSummaryLine,
            requestedGoods: requestedGoods,
            offeredGoods: offeredGoods,
            requestedGoodsCount: requestedGoodsIDs.count,
            offeredGoodsCount: offeredGoodsIDs.count,
            paymentSummaryText: paymentSummaryText,
            evidencePhotos: appState.evidencePhotos(for: currentProposal),
            selectedEvidencePhotoItem: $selectedEvidencePhotoItem,
            partnerLastReadAt: appState.partnerLastReadAt(for: currentProposal.id),
            evaluationState: evaluationPromptState,
            isResponding: appState.respondingProposalID == currentProposal.id,
            isLoadingMessages: appState.loadingMessagesProposalID == proposal.id,
            isApprovingCancel: appState.respondingProposalID == currentProposal.id,
            isAddingEvidence: appState.addingEvidenceProposalID == currentProposal.id,
            isApprovingEvidence: appState.approvingEvidenceProposalID == currentProposal.id,
            canUseCamera: canUseCamera,
            onOpenDispute: openDisputeDetail,
            onOpenPartnerProfile: openPartnerProfile,
            onAgree: { acceptedExchangeMethod in
                Task {
                    await appState.agreeProposal(
                        proposalID: currentProposal.id,
                        acceptedExchangeMethod: acceptedExchangeMethod
                    )
                }
            },
            onReject: {
                isShowingRejectConfirmation = true
            },
            onCounterProposal: {
                isShowingCounterProposalPage = true
            },
            onOpenEvidenceCamera: {
                isShowingEvidenceCamera = true
            },
            onOpenEvidenceList: {
                isShowingEvidenceList = true
            },
            onOpenImage: { url in
                selectedRemoteImage = RemoteImageSelection(url: url)
            },
            onApproveEvidence: {
                Task {
                    await appState.approveTradeEvidence(proposalID: currentProposal.id)
                }
            },
            onRate: {
                isShowingEvaluationPage = true
            },
            onApproveCancel: {
                Task {
                    await appState.approveTradeCancel(proposalID: currentProposal.id)
                }
            }
        )
        .scrollDismissesKeyboard(.interactively)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            TradeDetailMessageInputBar(
                text: $draftMessage,
                selectedChatPhotoItem: $selectedChatPhotoItem,
                selectedOutfitPhotoItem: $selectedOutfitPhotoItem,
                isVisible: isChatInputVisible,
                context: messageInputContext,
                onOpenSchedule: {
                    isShowingSchedulePage = true
                },
                onSendArrivalStatus: { action in
                    sendArrivalQuickAction(action)
                },
                onOpenLocationPlaceholder: {
                    shareCurrentLocation()
                },
                onOpenChatCamera: {
                    isShowingChatCamera = true
                },
                onOpenOutfitCamera: {
                    isShowingOutfitCamera = true
                },
                onCounterProposal: {
                    isShowingCounterProposalPage = true
                },
                onRequestLate: {
                    assistanceRequestKind = .late
                },
                onRequestCancel: {
                    assistanceRequestKind = .cancel
                },
                onReport: {
                    isShowingDisputePage = true
                },
                onSendMessage: sendDraftMessage
            )
        }
        .navigationTitle("@\(heroPresentation.partnerHandle)")
        .megrumInlineNavigationTitle()
#if os(iOS)
        .toolbar(.hidden, for: .tabBar)
#endif
        .task {
            await appState.loadMessages(proposalID: proposal.id)
            await appState.loadTradeEvidencePhotos(proposal: currentProposal, reportsFailure: false)
            if let partnerID, appState.publicProfilesByUserID[partnerID] == nil {
                await appState.loadPublicUserProfile(userID: partnerID, reportsFailure: false)
            }
        }
        .onChange(of: selectedEvidencePhotoItem) { _, item in
            handleSelectedEvidencePhoto(item)
        }
        .onChange(of: selectedChatPhotoItem) { _, item in
            handleSelectedChatPhoto(item)
        }
        .onChange(of: selectedOutfitPhotoItem) { _, item in
            handleSelectedOutfitPhoto(item)
        }
        .navigationDestination(isPresented: $isShowingEvaluationPage) {
            TradeEvaluationSheet(
                isSubmitting: appState.submittingEvaluationProposalID == currentProposal.id
            ) { stars, comment in
                let sent = await appState.submitTradeEvaluation(
                    proposalID: currentProposal.id,
                    stars: stars,
                    comment: comment
                )
                if sent {
                    didSubmitEvaluation = true
                    await appState.loadMessages(proposalID: currentProposal.id)
                    isShowingEvaluationPage = false
                }
            }
        }
        .navigationDestination(isPresented: $isShowingDisputePage) {
            TradeDisputeSheet(
                isSubmitting: appState.filingDisputeProposalID == currentProposal.id
            ) { category, factMemo in
                let sent = await appState.fileTradeDispute(
                    proposalID: currentProposal.id,
                    category: category,
                    factMemo: factMemo
                )
                if sent {
                    isShowingDisputePage = false
                }
            }
        }
        .navigationDestination(isPresented: $isShowingCounterProposalPage) {
            CounterProposalSheet(
                appState: appState,
                proposal: currentProposal
            )
        }
        .navigationDestination(isPresented: $isShowingSchedulePage) {
            TradeScheduleSheet(appState: appState, proposal: currentProposal)
        }
        .navigationDestination(item: $unavailableChatAction) { action in
            TradeUnavailableChatActionSheet(action: action)
        }
        .navigationDestination(item: $assistanceRequestKind) { kind in
            TradeAssistanceRequestSheet(
                kind: kind,
                isSubmitting: appState.sendingMessageProposalID == currentProposal.id
            ) { intent in
                let sent: Bool
                switch intent.action {
                case .lateNotice:
                    sent = await appState.sendLateNoticeMessage(
                        proposalID: currentProposal.id,
                        lateMinutes: intent.lateMinutes ?? TradeLateDelayBucket.ten.rawValue,
                        reason: intent.reason,
                        note: intent.note
                    )
                case .cancelRequested:
                    sent = await appState.sendCancelRequestMessage(
                        proposalID: currentProposal.id,
                        reason: intent.reason,
                        note: intent.note
                    )
                }
                if sent {
                    assistanceRequestKind = nil
                }
            }
        }
        .navigationDestination(item: $disputeDetailRoute) { route in
            DisputeDetailScreen(model: route.model)
        }
        .navigationDestination(item: $partnerProfileRoute) { route in
            PublicUserProfileScreen(
                appState: appState,
                userID: route.userID,
                presentationContext: .tradeChat
            )
        }
        .onChange(of: locationState.coordinate) { _, coordinate in
            handleLocationCoordinateChange(coordinate)
        }
        .onChange(of: locationState.locationErrorMessage) { _, errorMessage in
            handleLocationErrorChange(errorMessage)
        }
    }
}
