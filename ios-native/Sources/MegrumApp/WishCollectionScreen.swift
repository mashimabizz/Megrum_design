import MegrumCore
import MegrumDesign
import SwiftUI

enum WishCollectionSection: String, CaseIterable, Identifiable {
    case wishes = "Wish"
    case listings = "個別募集"

    var id: String { rawValue }

    var navigationTitle: String {
        switch self {
        case .wishes:
            "ウィッシュ"
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
    @State private var selectedSection: WishCollectionSection = .wishes

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
        VStack(alignment: .leading, spacing: CollectionScreenLayoutMetrics.mainStackSpacing) {
            WishCollectionTopChrome(
                title: selectedSection.navigationTitle,
                accessory: sectionPicker
            )
            .padding(.horizontal, CollectionScreenLayoutMetrics.horizontalPadding)
            .padding(.top, CollectionScreenLayoutMetrics.topPadding)

            if WishCollectionPresentationPolicy.usesSwipePaging {
                TabView(selection: $selectedSection) {
                    ForEach(WishCollectionSection.allCases) { section in
                        wishSectionPage(section)
                            .tag(section)
                    }
                }
                .megrumPageTabViewStyle()
            } else {
                wishSectionPage(selectedSection)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .onChange(of: requestedSection, initial: true) { _, requestedSection in
            applyRequestedSection(requestedSection)
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
                adPlacement: .wishListBanner,
                adDisplayContext: adDisplayContext
            )
        case .listings:
            if let appState {
                IndividualListingsScreen(
                    appState: appState,
                    headerTitle: section.navigationTitle,
                    headerAccessory: nil,
                    showsHeader: false
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

    private var sectionPicker: AnyView {
        AnyView(
            Picker("表示", selection: $selectedSection) {
                ForEach(WishCollectionSection.allCases) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Wishの表示切り替え")
            .frame(maxWidth: .infinity)
        )
    }

    private func applyRequestedSection(_ section: WishCollectionSection?) {
        guard let section else {
            return
        }
        selectedSection = section
        requestedSection = nil
    }
}
