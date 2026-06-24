import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var headerTitle: String = "個別募集"
    var headerAccessory: AnyView?
    var showsHeader = true
    var initialEditorOptionKind: IndividualListingOptionKind? = nil
    var initialEditorStep: IndividualListingEditorStep = .haves
    var initiallyPresentsEditor = false
    @State private var editorRoute: IndividualListingEditorRoute?
    @State private var locallyEditedListings: [UUID: IndividualListing] = [:]
    @State private var didPresentInitialEditor = false
    @State private var pendingDeleteListing: IndividualListing?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            IndividualListingsContent(
                headerTitle: headerTitle,
                headerAccessory: headerAccessory,
                showsHeader: showsHeader,
                isLoading: appState.isLoadingIndividualListings,
                listings: displayedListings,
                inventoryByID: inventoryByID,
                wishByID: wishByID,
                groups: appState.oshiGroups,
                characters: appState.oshiCharacters,
                goodsTypes: appState.goodsTypes,
                viewerID: appState.viewer?.id,
                onEditOffer: { listing in
                    editorRoute = .edit(listing, initialStep: .haves)
                },
                onAddCondition: { listing in
                    editorRoute = .edit(listing, initialStep: .options)
                },
                onEditExchangeCondition: { listing in
                    editorRoute = .edit(listing, initialStep: .exchange)
                },
                onDelete: { listing in
                    pendingDeleteListing = listing
                }
            )
            .refreshable {
                locallyEditedListings.removeAll()
                await appState.loadIndividualListings()
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .megrumHiddenNavigationBar()

            AddIndividualListingButton(title: "募集を追加") {
                editorRoute = .create(optionKind: nil)
            }
            .padding(.trailing, 18)
            .padding(.bottom, FloatingActionLayoutMetrics.bottomGapAboveFooter)
        }
        .task {
            if appState.listings.isEmpty {
                await appState.loadIndividualListings()
            }
            await loadChoicesIfNeeded()
            presentInitialEditorIfNeeded()
        }
        .onAppear {
            presentInitialEditorIfNeeded()
        }
        .onChange(of: initialEditorOptionKind?.rawValue, initial: true) { _, _ in
            presentInitialEditorIfNeeded()
        }
        .individualListingEditorPresentation(item: $editorRoute) { route in
            NavigationStack {
                switch route {
                case .create(let optionKind):
                    IndividualListingEditorSheet(
                        appState: appState,
                        initialOptionKind: optionKind,
                        initialStep: initialEditorStep,
                        onSaved: { editorRoute = nil }
                    )
                case .edit(let listing, let initialStep):
                    IndividualListingEditorSheet(
                        appState: appState,
                        editing: listing,
                        initialStep: initialStep,
                        onSaved: { editorRoute = nil }
                    ) { updated in
                        locallyEditedListings[updated.id] = updated
                    }
                }
            }
        }
        .confirmationDialog("この交換条件を削除しますか？", isPresented: Binding(
            get: { pendingDeleteListing != nil },
            set: { if !$0 { pendingDeleteListing = nil } }
        ), titleVisibility: .visible) {
            Button("削除する", role: .destructive) {
                if let listing = pendingDeleteListing {
                    archiveListing(listing)
                }
                pendingDeleteListing = nil
            }
            Button("キャンセル", role: .cancel) {
                pendingDeleteListing = nil
            }
        } message: {
            Text("削除すると個別募集の一覧には表示されなくなります。")
        }
    }

    private var displayedListings: [IndividualListing] {
        appState.listings.map { listing in
            locallyEditedListings[listing.id] ?? listing
        }
    }

    private var inventoryByID: [UUID: GoodsItem] {
        Dictionary(uniqueKeysWithValues: appState.inventory.map { ($0.id, $0) })
    }

    private var wishByID: [UUID: WishItem] {
        Dictionary(uniqueKeysWithValues: appState.wishes.map { ($0.id, $0) })
    }

    private func loadChoicesIfNeeded() async {
        if appState.oshiGroups.isEmpty || appState.oshiGenres.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
    }

    private func presentInitialEditorIfNeeded() {
        guard !didPresentInitialEditor, initiallyPresentsEditor || initialEditorOptionKind != nil || initialEditorStep != .haves else {
            return
        }
        didPresentInitialEditor = true
        editorRoute = .create(optionKind: initialEditorOptionKind)
    }

    private func archiveListing(_ listing: IndividualListing) {
        Task {
            let deleted = await appState.archiveIndividualListing(listing.id)
            if deleted {
                locallyEditedListings.removeValue(forKey: listing.id)
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func individualListingEditorPresentation<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }
}

private enum IndividualListingEditorRoute: Identifiable {
    case create(optionKind: IndividualListingOptionKind?)
    case edit(IndividualListing, initialStep: IndividualListingEditorStep)

    var id: String {
        switch self {
        case .create(let optionKind):
            "create-\(optionKind?.rawValue ?? "default")"
        case .edit(let listing, let initialStep):
            "edit-\(listing.id.uuidString)-\(initialStep.rawValue)"
        }
    }
}
