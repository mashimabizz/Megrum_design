import MegrumCore
import MegrumDesign
import SwiftUI

extension TradeDetailScreen {
    var bodyBeforeDialogs: some View {
        let evidencePhotos = appState.evidencePhotos(for: currentProposal)

        return TradeDetailContent(
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
            partnerPaymentMethods: partnerPaymentMethods,
            partnerPaymentNote: partnerPaymentNote,
            partnerMailingAddress: partnerMailingAddress,
            partnerPaymentSettings: partnerPaymentSettings,
            viewerPaymentMethods: viewerPaymentMethods,
            viewerPaymentNote: viewerPaymentNote,
            viewerHasCounterProposal: viewerHasCounterProposal,
            isMessageComposerFocused: isMessageComposerFocused,
            evidencePhotos: evidencePhotos,
            selectedEvidencePhotoItem: evidencePhotoPickerSelection,
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
            onOpenEvidenceList: openEvidenceList,
            onOpenImage: { url in
                selectedRemoteImage = RemoteImageSelection(url: url)
            },
            onOpenEvidencePhoto: openEvidencePhoto,
            onApproveEvidence: { photo in
                Task {
                    await appState.approveTradeEvidence(proposalID: currentProposal.id, photoID: photo.id)
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
            VStack(spacing: 0) {
                if TradeAgreementNextStepFooterPolicy.showsEvidenceCaptureFooter(
                    status: currentProposal.status,
                    evidencePhotos: evidencePhotos
                ) {
                    TradeAgreementNextStepFooter(
                        isAddingEvidence: appState.addingEvidenceProposalID == currentProposal.id,
                        action: {
                            isShowingEvidenceSourceDialog = true
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
                    .background(.regularMaterial)
                } else if TradeEvaluationAttentionPolicy.needsViewerEvaluation(
                    proposal: currentProposal,
                    viewerID: appState.viewer?.id,
                    messages: messages,
                    localSubmission: didSubmitEvaluation
                ) {
                    TradeEvaluationNextStepFooter(
                        isSubmitting: appState.submittingEvaluationProposalID == currentProposal.id,
                        action: {
                            isShowingEvaluationPage = true
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
                    .background(.regularMaterial)
                }

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
                    onOpenChatLibrary: {
                        isShowingChatPhotoLibraryPicker = true
                    },
                    onOpenOutfitCamera: {
                        isShowingOutfitCamera = true
                    },
                    onOpenOutfitLibrary: {
                        isShowingOutfitPhotoLibraryPicker = true
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
                    onSendMessage: sendDraftMessage,
                    onFocusChange: { focused in
                        withAnimation(.snappy(duration: 0.18)) {
                            isMessageComposerFocused = focused
                        }
                    }
                )
            }
        }
        .navigationTitle("@\(heroPresentation.partnerHandle)")
        .megrumInlineNavigationTitle()
#if os(iOS)
        .toolbar(.hidden, for: .tabBar)
#endif
        .task(id: proposal.id) {
            await loadInitialDataAfterPresentationSettles()
            if let partnerID, appState.publicProfilesByUserID[partnerID] == nil {
                await appState.loadPublicUserProfile(userID: partnerID, reportsFailure: false)
            }
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
            if let counterProposalTargetItem {
                ProposalCreateFlow(
                    appState: appState,
                    targetItem: counterProposalTargetItem,
                    listingID: currentProposal.listingID,
                    receiverGoodsIDs: requestedGoodsIDs,
                    initialSenderGoodsIDs: offeredGoodsIDs,
                    initialExchangeMethod: currentProposal.exchangeMethod,
                    initialStep: .give,
                    submissionStatusOverride: .negotiating,
                    showsCompletionAfterCreate: false,
                    onCreateSuccess: {
                        _ = await appState.sendSystemMessage(
                            proposalID: currentProposal.id,
                            body: TradeCounterProposalSystemMessage.body(
                                actorDisplayName: appState.viewer?.displayName,
                                actorHandle: appState.viewer?.handle
                            )
                        )
                    }
                )
            } else {
                CounterProposalUnavailableView()
            }
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

    func loadInitialDataAfterPresentationSettles() async {
        do {
            try await Task.sleep(nanoseconds: TradeDetailSlidePresentationMetrics.presentationSettledDelayNanoseconds)
        } catch {
            return
        }
        guard !Task.isCancelled else {
            return
        }
        await appState.loadMessages(proposalID: proposal.id)
        guard !Task.isCancelled else {
            return
        }
        await appState.loadTradeEvidencePhotos(proposal: currentProposal, reportsFailure: false)
    }
}
