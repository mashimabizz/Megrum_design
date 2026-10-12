import MegrumCore
import MegrumDesign
import SwiftUI

enum WishCollectionSection: String, CaseIterable, Identifiable {
    case wishes = "ほしいもの"
    case listings = "個別募集"

    var id: String { rawValue }

    var navigationTitle: String {
        switch self {
        case .wishes:
            "ほしいもの"
        case .listings:
            "個別募集"
        }
    }
}

struct WishCollectionScreen: View {
    var items: [WishItem]
    var appState: MegrumAppState?
    var adDisplayContext: AdDisplayContext
    @Binding private var requestedSection: WishCollectionSection?
    @State private var presentationState = WishCollectionPresentationState()
    @State private var wishColumns = GoodsGridLayout.minimumColumns
    @State private var topChromeHeight: CGFloat = CollectionScreenLayoutMetrics.estimatedPinnedChromeBottomEdge
    @State private var isTopChromeCollapsed = false
    @State private var topChromeCollapseTracker = MegrumTopChromeCollapseTracker()
    @State private var sectionScrollResetToken = 0

    init(
        items: [WishItem],
        appState: MegrumAppState?,
        requestedSection: Binding<WishCollectionSection?> = .constant(nil),
        adDisplayContext: AdDisplayContext = AdDisplayContext()
    ) {
        self.items = items
        self.appState = appState
        self.adDisplayContext = adDisplayContext
        _requestedSection = requestedSection
    }

    private var goodsLikeItems: [GoodsItem] {
        items.map {
            GoodsItem(
                id: $0.id,
                ownerID: $0.ownerID,
                kind: .wish,
                status: .active,
                groupID: $0.groupID,
                memberID: $0.memberID,
                goodsTypeID: $0.goodsTypeID,
                title: $0.title,
                imageURL: $0.imageURL,
                tags: $0.tags,
                quantity: $0.quantity
            )
        }
    }

    var body: some View {
        Group {
            if WishCollectionPresentationPolicy.usesSwipePaging {
                TabView(selection: $presentationState.selectedSection) {
                    ForEach(WishCollectionSection.allCases) { section in
                        wishSectionPage(section)
                            .tag(section)
                    }
                }
                .megrumPageTabViewStyle()
                .megrumHiddenBottomScrollEdgeEffect()
                .ignoresSafeArea(.container, edges: .bottom)
            } else {
                wishSectionPage(presentationState.selectedSection)
            }
        }
        .environment(
            \.megrumPinnedTopChromeInset,
            topChromeHeight + CollectionScreenLayoutMetrics.mainStackSpacing
        )
        .megrumPinnedTranslucentTopChrome(bottomEdge: expandedTopChromeBottomEdge) {
            WishCollectionTopChrome(
                title: presentationState.selectedSection.navigationTitle,
                accessory: sectionPicker,
                columns: $wishColumns,
                showsColumnToggle: presentationState.selectedSection == .wishes,
                hidesTitle: isTopChromeCollapsed
            )
            .padding(.horizontal, CollectionScreenLayoutMetrics.horizontalPadding)
            .padding(.top, CollectionScreenLayoutMetrics.topPadding)
            .padding(.bottom, 6)
        }
        .onChange(of: presentationState.selectedSection) { _, _ in
            resetTopChromeCollapse()
            // セクションを行き来した時は必ず先頭まで戻った状態で表示する
            sectionScrollResetToken += 1
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.container, edges: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .onChange(of: requestedSection, initial: true) { _, requestedSection in
            applyRequestedSection(requestedSection)
        }
        .onChange(of: wishColumnPreferenceContext, initial: true) { _, _ in
            loadStoredWishColumns()
        }
        .onChange(of: wishColumns) { _, newValue in
            saveWishColumns(newValue)
        }
    }

    @ViewBuilder
    private func wishSectionPage(_ section: WishCollectionSection) -> some View {
        switch section {
        case .wishes:
            GoodsCollectionScreen(
                title: section.navigationTitle,
                subtitle: "",
                items: goodsLikeItems,
                showsAddButton: true,
                appState: appState,
                entryKind: .wish,
                headerAccessory: nil,
                showsHeader: false,
                showsColumnToggle: false,
                displayColumnsOverride: wishColumns,
                adPlacement: nil,
                adDisplayContext: adDisplayContext,
                onScrollContentTopChange: { contentTop in
                    handleSectionScrollContentTop(contentTop, section: .wishes)
                },
                scrollToTopToken: sectionScrollResetToken
            )
        case .listings:
            if let appState {
                IndividualListingsScreen(
                    appState: appState,
                    headerTitle: section.navigationTitle,
                    headerAccessory: nil,
                    showsHeader: false,
                    onScrollContentTopChange: { contentTop in
                        handleSectionScrollContentTop(contentTop, section: .listings)
                    },
                    onSwipeBackFromFirst: {
                        withAnimation(.smooth(duration: 0.24)) {
                            presentationState.selectedSection = .wishes
                        }
                    }
                )
            } else {
                GoodsCollectionScreen(
                    title: section.navigationTitle,
                    subtitle: "条件を指定した募集",
                    items: [],
                    showsAddButton: false,
                    headerAccessory: nil,
                    showsHeader: false,
                    showsColumnToggle: false
                )
            }
        }
    }

    /// While the chrome is collapsed, keep reporting the expanded height so
    /// scroll content does not jump when the title row hides.
    private var expandedTopChromeBottomEdge: Binding<CGFloat> {
        Binding(
            get: { topChromeHeight },
            set: { newValue in
                if !isTopChromeCollapsed {
                    topChromeHeight = newValue
                }
            }
        )
    }

    private func handleSectionScrollContentTop(_ contentTop: CGFloat, section: WishCollectionSection) {
        guard section == presentationState.selectedSection else {
            return
        }
        let newValue = topChromeCollapseTracker.updatedCollapsedState(
            contentTop: contentTop,
            isCollapsed: isTopChromeCollapsed
        )
        guard newValue != isTopChromeCollapsed else {
            return
        }
        withAnimation(MegrumTopChromeCollapseAnimation.animation) {
            isTopChromeCollapsed = newValue
        }
    }

    private func resetTopChromeCollapse() {
        topChromeCollapseTracker.reset()
        guard isTopChromeCollapsed else {
            return
        }
        withAnimation(MegrumTopChromeCollapseAnimation.animation) {
            isTopChromeCollapsed = false
        }
    }

    private var sectionPicker: AnyView {
        AnyView(
            Picker("表示", selection: $presentationState.selectedSection) {
                ForEach(WishCollectionSection.allCases) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("ほしいものの表示切り替え")
            .frame(maxWidth: .infinity)
            .tutorialAnchor(.wishSectionSegment)
        )
    }

    private func applyRequestedSection(_ section: WishCollectionSection?) {
        if presentationState.applyRequestedSection(section) {
            requestedSection = nil
        }
    }

    private var wishColumnPreferenceContext: GoodsGridColumnPreferenceContext {
        GoodsGridColumnPreferenceContext(
            entryKind: .wish,
            viewerID: appState?.viewer?.id
        )
    }

    private func loadStoredWishColumns() {
        wishColumns = GoodsGridColumnPreferenceStore.load(context: wishColumnPreferenceContext)
    }

    private func saveWishColumns(_ newColumns: Int) {
        let normalizedColumns = GoodsGridLayout(columns: newColumns).columns
        if wishColumns != normalizedColumns {
            wishColumns = normalizedColumns
            return
        }

        GoodsGridColumnPreferenceStore.save(
            columns: normalizedColumns,
            context: wishColumnPreferenceContext
        )
    }
}
