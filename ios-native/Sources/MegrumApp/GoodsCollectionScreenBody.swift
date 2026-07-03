import MegrumCore
import MegrumDesign
import SwiftUI

extension GoodsCollectionScreen {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            collectionContent

            GoodsCollectionFloatingControls(
                showsAddButton: showsAddButton,
                addButtonLabel: addButtonLabel,
                addButtonHint: addButtonHint,
                isSelectionMode: isSelectionMode,
                quickActionItem: quickActionItem,
                quickActionHeader: quickActionItem.map { quickActionHeaderPresentation(for: $0) },
                quickActions: GoodsQuickActionKind.actions(for: entryKind),
                selectedCount: selectedItemIDs.count,
                onAdd: openAddForm,
                onDismissQuickAction: {
                    quickActionItem = nil
                },
                onQuickAction: performQuickAction,
                onBulkTag: {
                    bulkTagGoogleLensErrorMessage = nil
                    bulkTagRoute = GoodsBulkTagRoute(itemIDs: selectedItemIDs)
                },
                onBulkShare: presentSelectedSharePrompt,
                onBulkDelete: requestBulkDelete,
                onCancelSelection: {
                    selectedItemIDs = []
                    dismissDeleteConfirmation()
                }
            )

            if hasPendingDeleteConfirmation {
                deleteConfirmationPopover
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.horizontal, 22)
                    .padding(.bottom, deleteConfirmationBottomPadding)
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottomTrailing)))
                    .zIndex(4)
            }

            if let sharePromptContext {
                GoodsSharePromptOverlay(
                    context: sharePromptContext,
                    isPreparing: isPreparingSharePost,
                    errorMessage: sharePostErrorMessage,
                    onDismiss: dismissSharePrompt,
                    onShare: startGoodsSharePost
                )
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                .zIndex(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(
            .spring(
                response: GoodsQuickActionPresentationMetrics.panelAnimationResponse,
                dampingFraction: GoodsQuickActionPresentationMetrics.panelAnimationDampingFraction
            ),
            value: quickActionItem?.id
        )
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: selectedItemIDs)
        .sheet(item: $editorRoute) { route in
            if let appState {
                NavigationStack {
                    GoodsEditorSheet(
                        appState: appState,
                        route: route,
                        onCreatedInventoryItems: presentSharePrompt
                    )
                }
            }
        }
        .sheet(item: $listingSeedWish) { item in
            if let appState {
                NavigationStack {
                    IndividualListingEditorSheet(
                        appState: appState,
                        preselectedWishID: item.id,
                        onCreatedListing: presentListingSharePrompt
                    )
                }
            }
        }
        .sheet(item: $bulkTagRoute) { route in
            GoodsBulkTagSheet(
                selectedCount: route.itemIDs.count,
                candidateNames: bulkTagCandidateNames(for: route.itemIDs),
                previewItemsByTag: bulkTagPreviewItemsByTag(for: route.itemIDs),
                googleLensItems: bulkTagGoogleLensItems(for: route.itemIDs),
                googleLensErrorMessage: bulkTagGoogleLensErrorMessage,
                onOpenGoogleLens: { itemID in
                    openBulkTagGoogleLensSearch(itemID: itemID, for: route.itemIDs)
                }
            ) { tagName in
                applyBulkTag(tagName, to: route.itemIDs)
            }
            #if os(iOS)
            .sheet(item: $bulkTagLensBrowserRoute) { browserRoute in
                MegrumInAppSafariView(url: browserRoute.url)
                    .ignoresSafeArea()
            }
            #endif
        }
        .alert("追加できません", isPresented: $isShowingUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("データ保存の準備がまだ整っていません。")
        }
        #if os(iOS)
        .sheet(item: $shareActivityPayload, content: GoodsShareActivitySheet.init)
        #endif
        .animation(.snappy(duration: 0.18), value: hasPendingDeleteConfirmation)
        .animation(.spring(response: 0.30, dampingFraction: 0.86), value: sharePromptContext?.id)
        .task {
            await loadFilterChoicesIfNeeded()
        }
        .onChange(of: columnPreferenceContext, initial: true) { _, _ in
            loadStoredColumnsIfNeeded()
        }
        .onChange(of: columns) { _, newValue in
            saveColumnsIfNeeded(newValue)
        }
        .onChange(of: collectionMemberLookupGroupIDs) { _, _ in
            Task {
                await loadCollectionCharactersIfNeeded()
            }
        }
        .onChange(of: selectedGroupID) { _, _ in
            reconcileSelectedTags()
        }
        .onChange(of: selectedGoodsTypeID) { _, _ in
            reconcileSelectedTags()
        }
        .onChange(of: selectedInventoryStatus) { _, _ in
            quickActionItem = nil
            selectedItemIDs = []
            reconcileSelectedFilters()
        }
        .onChange(of: items.map(\.id)) { _, _ in
            reconcileSelectedFilters()
        }
        .onChange(of: filteredItems.map(\.id)) { _, visibleIDs in
            selectedItemIDs.formIntersection(Set(visibleIDs))
            if selectedItemIDs.isEmpty, isConfirmingBulkDelete {
                dismissDeleteConfirmation()
            }
        }
    }
}
