import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    @State private var editorRoute: IndividualListingEditorRoute?
    @State private var locallyEditedListings: [UUID: IndividualListing] = [:]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ScreenTitle(title: "個別募集", subtitle: "条件を指定して募集する")

                    if appState.isLoadingIndividualListings {
                        listingSkeletons
                    } else if displayedListings.isEmpty {
                        EmptyListingView()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(displayedListings) { listing in
                                IndividualListingCard(
                                    listing: listing,
                                    inventoryByID: inventoryByID,
                                    wishByID: wishByID,
                                    canEdit: listing.ownerID == appState.viewer?.id
                                ) {
                                    editorRoute = .edit(listing)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 118)
            }
            .refreshable {
                locallyEditedListings.removeAll()
                await appState.loadIndividualListings()
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .megrumHiddenNavigationBar()

            AddIndividualListingButton {
                editorRoute = .create
            }
            .padding(.leading, 24)
            .padding(.bottom, 22)
        }
        .task {
            if appState.listings.isEmpty {
                await appState.loadIndividualListings()
            }
            await loadChoicesIfNeeded()
        }
        .sheet(item: $editorRoute) { route in
            NavigationStack {
                switch route {
                case .create:
                    IndividualListingEditorSheet(appState: appState)
                case .edit(let listing):
                    IndividualListingEditorSheet(appState: appState, editing: listing) { updated in
                        locallyEditedListings[updated.id] = updated
                    }
                }
            }
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

    private var listingSkeletons: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(MegrumTheme.lavender.opacity(0.12))
                    .frame(height: 156)
                    .redacted(reason: .placeholder)
            }
        }
    }

    private func loadChoicesIfNeeded() async {
        if appState.oshiGroups.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
    }
}

private enum IndividualListingEditorRoute: Identifiable {
    case create
    case edit(IndividualListing)

    var id: String {
        switch self {
        case .create:
            "create"
        case .edit(let listing):
            "edit-\(listing.id.uuidString)"
        }
    }
}

private struct IndividualListingCard: View {
    var listing: IndividualListing
    var inventoryByID: [UUID: GoodsItem]
    var wishByID: [UUID: WishItem]
    var canEdit: Bool = false
    var onEdit: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(listing.status.displayName)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(statusColor, in: Capsule())

                Spacer()

                if canEdit {
                    Menu {
                        Button(action: onEdit) {
                            Label("編集", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(width: 34, height: 34)
                    }
                    .accessibilityLabel("個別募集を編集")
                }

                Text(listing.haveLogic == .all ? "譲るもの全部" : "どれか譲る")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            HStack(alignment: .top, spacing: 12) {
                ListingItemGroup(
                    title: "譲る",
                    items: listing.haves.map { quantity in
                        ListedItemLabel(
                            title: inventoryByID[quantity.itemID]?.title ?? "グッズ",
                            quantity: quantity.quantity
                        )
                    }
                )

                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 30, height: 58)

                ListingItemGroup(
                    title: "求める",
                    items: optionItems
                )
            }

            if let note = listing.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
                Text(note)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.58), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 18, y: 10)
    }

    private var optionItems: [ListedItemLabel] {
        let options = listing.options.sorted(by: { $0.position < $1.position })
        guard !options.isEmpty else {
            return [ListedItemLabel(title: "未設定", quantity: 1)]
        }
        return options.enumerated().flatMap { index, option -> [ListedItemLabel] in
            let prefix = options.count > 1 ? "選択肢\(index + 1) " : ""
            if option.isCashOffer, let amount = option.cashAmount {
                return [ListedItemLabel(title: "\(prefix)定価 \(amount)円", quantity: 1)]
            }
            return option.wishes.map { quantity in
                ListedItemLabel(
                    title: "\(prefix)\(wishByID[quantity.itemID]?.title ?? "Wish")",
                    quantity: quantity.quantity
                )
            }
        }
    }

    private var statusColor: Color {
        switch listing.status {
        case .active:
            MegrumTheme.lavender
        case .paused:
            MegrumTheme.muted
        case .matched:
            MegrumTheme.sky
        case .closed:
            MegrumTheme.ink.opacity(0.55)
        }
    }
}

private struct ListingItemGroup: View {
    var title: String
    var items: [ListedItemLabel]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items) { item in
                    HStack(spacing: 7) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                        if item.quantity > 1 {
                            Text("×\(item.quantity)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(MegrumTheme.lavender)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ListedItemLabel: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var quantity: Int
}

private struct EmptyListingView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(MegrumTheme.lavender)
            Text("個別募集はまだありません")
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
            Text("在庫とWishを選んで、ピンポイントの交換条件を作れます。")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.55), lineWidth: 1)
        }
    }
}

private struct AddIndividualListingButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 68, height: 68)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.sky],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.65), lineWidth: 1)
                }
                .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("個別募集を作成")
    }
}

enum IndividualListingEditorMode: Equatable {
    case create(preselectedWishID: UUID?)
    case edit(IndividualListing)

    var isEditing: Bool {
        if case .edit = self {
            return true
        }
        return false
    }
}

struct IndividualListingDraft: Equatable {
    var mode: IndividualListingEditorMode
    var selectedHaveIDs: Set<UUID>
    var haveQuantities: [UUID: Int]
    var selectedWishIDs: Set<UUID>
    var wishQuantities: [UUID: Int]
    var haveLogic: ListingLogic
    var wishLogic: ListingLogic
    var exchangeType: IndividualListingExchangeType
    var status: IndividualListingStatus
    var note: String

    init(mode: IndividualListingEditorMode) {
        self.mode = mode
        switch mode {
        case .create(let preselectedWishID):
            self.selectedHaveIDs = []
            self.haveQuantities = [:]
            self.selectedWishIDs = preselectedWishID.map { Set([$0]) } ?? []
            self.wishQuantities = preselectedWishID.map { [$0: 1] } ?? [:]
            self.haveLogic = .all
            self.wishLogic = .one
            self.exchangeType = .any
            self.status = .active
            self.note = ""
        case .edit(let listing):
            let primaryOption = listing.options.sorted { $0.position < $1.position }.first
            self.selectedHaveIDs = Set(listing.haves.map(\.itemID))
            self.haveQuantities = Dictionary(uniqueKeysWithValues: listing.haves.map { ($0.itemID, boundedQuantity($0.quantity)) })
            self.selectedWishIDs = Set(primaryOption?.wishes.map(\.itemID) ?? [])
            self.wishQuantities = Dictionary(uniqueKeysWithValues: (primaryOption?.wishes ?? []).map { ($0.itemID, boundedQuantity($0.quantity)) })
            self.haveLogic = listing.haveLogic
            self.wishLogic = primaryOption?.logic ?? .one
            self.exchangeType = primaryOption?.exchangeType ?? .any
            self.status = listing.status
            self.note = listing.note ?? ""
        }
    }

    var navigationTitle: String {
        mode.isEditing ? "個別募集を編集" : "個別募集を作成"
    }

    var confirmationTitle: String {
        mode.isEditing ? "反映" : "保存"
    }

    mutating func toggleHave(_ id: UUID, maxQuantity: Int = 99) {
        if selectedHaveIDs.contains(id) {
            selectedHaveIDs.remove(id)
            haveQuantities.removeValue(forKey: id)
        } else {
            selectedHaveIDs.insert(id)
            haveQuantities[id] = boundedQuantity(haveQuantities[id] ?? 1, maxQuantity: maxQuantity)
        }
    }

    mutating func toggleWish(_ id: UUID) {
        if selectedWishIDs.contains(id) {
            selectedWishIDs.remove(id)
            wishQuantities.removeValue(forKey: id)
        } else {
            selectedWishIDs.insert(id)
            wishQuantities[id] = boundedQuantity(wishQuantities[id] ?? 1)
        }
    }

    mutating func setHaveQuantity(_ id: UUID, quantity: Int, maxQuantity: Int = 99) {
        guard selectedHaveIDs.contains(id) else {
            return
        }
        haveQuantities[id] = boundedQuantity(quantity, maxQuantity: maxQuantity)
    }

    mutating func setWishQuantity(_ id: UUID, quantity: Int) {
        guard selectedWishIDs.contains(id) else {
            return
        }
        wishQuantities[id] = boundedQuantity(quantity)
    }

    func haveQuantity(for id: UUID) -> Int {
        boundedQuantity(haveQuantities[id] ?? 1)
    }

    func wishQuantity(for id: UUID) -> Int {
        boundedQuantity(wishQuantities[id] ?? 1)
    }

    func validationMessage(inventory: [GoodsItem], wishes: [WishItem]) -> String? {
        if selectedHaveIDs.isEmpty {
            return "譲るものを選択してください"
        }
        if selectedWishIDs.isEmpty {
            return "求めるものを選択してください"
        }
        let selectedHaveItems = selectedInventoryItems(from: inventory)
        let selectedWishItems = selectedWishItems(from: wishes)
        if selectedHaveItems.count != selectedHaveIDs.count {
            return "選択した在庫を読み込めませんでした"
        }
        if selectedWishItems.count != selectedWishIDs.count {
            return "選択したWishを読み込めませんでした"
        }
        if !hasSameGroupAndType(selectedHaveItems) {
            return "譲るものは同じグループ・同じ種別で選んでください"
        }
        if !hasSameGroupAndType(selectedWishItems) {
            return "求めるものは同じグループ・同じ種別で選んでください"
        }
        if haveLogic == .one, wishLogic == .one, selectedHaveIDs.count > 1, selectedWishIDs.count > 1 {
            return "両方を「どれか1つだけ」にする場合は、片方を1件にしてください"
        }
        return nil
    }

    func createInput(inventory: [GoodsItem], wishes: [WishItem]) -> IndividualListingCreateInput? {
        guard validationMessage(inventory: inventory, wishes: wishes) == nil else {
            return nil
        }
        return IndividualListingCreateInput(
            haveItems: selectedInventoryItems(from: inventory).map { item in
                ListingItemQuantity(itemID: item.id, quantity: haveQuantity(for: item.id))
            },
            haveLogic: haveLogic,
            wishItems: selectedWishItems(from: wishes).map { item in
                ListingItemQuantity(itemID: item.id, quantity: wishQuantity(for: item.id))
            },
            wishLogic: wishLogic,
            exchangeType: exchangeType,
            note: trimmedNote
        )
    }

    func updatedListing(from original: IndividualListing, inventory: [GoodsItem], wishes: [WishItem]) -> IndividualListing? {
        guard let input = createInput(inventory: inventory, wishes: wishes) else {
            return nil
        }
        let selectedHaveItems = selectedInventoryItems(from: inventory)
        let selectedWishItems = selectedWishItems(from: wishes)
        var options = original.options.sorted { $0.position < $1.position }
        let existingOption = options.first
        let updatedOption = IndividualListingWishOption(
            id: existingOption?.id ?? UUID(),
            listingID: original.id,
            position: existingOption?.position ?? 1,
            wishes: input.wishItems,
            logic: input.wishLogic,
            exchangeType: input.exchangeType,
            isCashOffer: false,
            cashAmount: nil,
            wishGroupID: selectedWishItems.first?.groupID,
            wishGoodsTypeID: selectedWishItems.first?.goodsTypeID,
            createdAt: existingOption?.createdAt,
            updatedAt: Date()
        )
        if options.isEmpty {
            options = [updatedOption]
        } else {
            options[0] = updatedOption
        }
        return IndividualListing(
            id: original.id,
            ownerID: original.ownerID,
            haves: input.haveItems,
            haveLogic: input.haveLogic,
            haveGroupID: selectedHaveItems.first?.groupID,
            haveGoodsTypeID: selectedHaveItems.first?.goodsTypeID,
            status: status,
            note: input.note,
            options: options,
            createdAt: original.createdAt,
            updatedAt: Date()
        )
    }

    private var trimmedNote: String? {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func selectedInventoryItems(from inventory: [GoodsItem]) -> [GoodsItem] {
        inventory.filter { selectedHaveIDs.contains($0.id) }
    }

    private func selectedWishItems(from wishes: [WishItem]) -> [WishItem] {
        wishes.filter { selectedWishIDs.contains($0.id) }
    }

    private func hasSameGroupAndType(_ items: [GoodsItem]) -> Bool {
        guard let first = items.first else {
            return true
        }
        return items.allSatisfy { $0.groupID == first.groupID && $0.goodsTypeID == first.goodsTypeID }
    }

    private func hasSameGroupAndType(_ items: [WishItem]) -> Bool {
        guard let first = items.first else {
            return true
        }
        return items.allSatisfy { $0.groupID == first.groupID && $0.goodsTypeID == first.goodsTypeID }
    }
}

private func boundedQuantity(_ quantity: Int, maxQuantity: Int = 99) -> Int {
    max(1, min(quantity, max(1, maxQuantity), 99))
}

struct IndividualListingEditorSheet: View {
    @ObservedObject var appState: MegrumAppState
    var onLocalEditSaved: ((IndividualListing) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var draft: IndividualListingDraft

    init(appState: MegrumAppState, preselectedWishID: UUID? = nil) {
        self.appState = appState
        self.onLocalEditSaved = nil
        self._draft = State(initialValue: IndividualListingDraft(mode: .create(preselectedWishID: preselectedWishID)))
    }

    init(appState: MegrumAppState, editing listing: IndividualListing, onLocalEditSaved: @escaping (IndividualListing) -> Void) {
        self.appState = appState
        self.onLocalEditSaved = onLocalEditSaved
        self._draft = State(initialValue: IndividualListingDraft(mode: .edit(listing)))
    }

    var body: some View {
        Form {
            Section("譲るもの") {
                if appState.inventory.isEmpty {
                    Text("在庫を登録してから作成できます。")
                        .foregroundStyle(MegrumTheme.muted)
                } else {
                    ForEach(appState.inventory) { item in
                        SelectionRow(
                            title: item.title,
                            subtitle: item.quantity > 1 ? "\(item.quantity)個あります" : nil,
                            isSelected: draft.selectedHaveIDs.contains(item.id)
                        ) {
                            draft.toggleHave(item.id, maxQuantity: item.quantity)
                        }
                        if draft.selectedHaveIDs.contains(item.id) {
                            Stepper(
                                "数量 \(draft.haveQuantity(for: item.id))",
                                value: haveQuantityBinding(for: item),
                                in: 1...max(1, item.quantity)
                            )
                        }
                    }
                    Picker("譲る条件", selection: $draft.haveLogic) {
                        ForEach(ListingLogic.allCases) { logic in
                            Text(logic == .all ? "全部出す" : "どれか1つ出す").tag(logic)
                        }
                    }
                }
            }

            Section("求めるもの") {
                if appState.wishes.isEmpty {
                    Text("Wishを登録してから作成できます。")
                        .foregroundStyle(MegrumTheme.muted)
                } else {
                    ForEach(appState.wishes) { item in
                        SelectionRow(
                            title: item.title,
                            subtitle: nil,
                            isSelected: draft.selectedWishIDs.contains(item.id)
                        ) {
                            draft.toggleWish(item.id)
                        }
                        if draft.selectedWishIDs.contains(item.id) {
                            Stepper(
                                "数量 \(draft.wishQuantity(for: item.id))",
                                value: wishQuantityBinding(for: item),
                                in: 1...99
                            )
                        }
                    }
                    Picker("求める条件", selection: $draft.wishLogic) {
                        ForEach(ListingLogic.allCases) { logic in
                            Text(logic.displayName).tag(logic)
                        }
                    }
                }
            }

            Section("交換タイプ") {
                Picker("同種・異種", selection: $draft.exchangeType) {
                    ForEach(IndividualListingExchangeType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                TextField("メモ（任意）", text: $draft.note, axis: .vertical)
                    .lineLimit(2...4)
            }

            if draft.mode.isEditing {
                Section("公開状態") {
                    Picker("状態", selection: $draft.status) {
                        ForEach([IndividualListingStatus.active, .paused, .closed]) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    Text("保存すると個別募集の公開状態にも反映されます。")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.red)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(draft.navigationTitle)
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await save()
                    }
                } label: {
                    if appState.isCreatingIndividualListing {
                        ProgressView()
                    } else {
                        Text(draft.confirmationTitle)
                    }
                }
                .disabled(validationMessage != nil || isSaving)
            }
        }
    }

    private var validationMessage: String? {
        draft.validationMessage(inventory: appState.inventory, wishes: appState.wishes)
    }

    private var isSaving: Bool {
        switch draft.mode {
        case .create:
            return appState.isCreatingIndividualListing
        case .edit(let listing):
            return appState.updatingIndividualListingID == listing.id
        }
    }

    private func save() async {
        guard let input = draft.createInput(inventory: appState.inventory, wishes: appState.wishes) else {
            return
        }
        if case .edit(let listing) = draft.mode {
            let primaryOptionID = listing.options.sorted { $0.position < $1.position }.first?.id
            if let updated = await appState.updateIndividualListing(
                listingID: listing.id,
                primaryOptionID: primaryOptionID,
                input: input,
                status: draft.status
            ) {
                onLocalEditSaved?(updated)
                dismiss()
            }
            return
        }
        let saved = await appState.createIndividualListing(
            input
        )
        if saved {
            dismiss()
        }
    }

    private func haveQuantityBinding(for item: GoodsItem) -> Binding<Int> {
        Binding(
            get: { draft.haveQuantity(for: item.id) },
            set: { draft.setHaveQuantity(item.id, quantity: $0, maxQuantity: item.quantity) }
        )
    }

    private func wishQuantityBinding(for item: WishItem) -> Binding<Int> {
        Binding(
            get: { draft.wishQuantity(for: item.id) },
            set: { draft.setWishQuantity(item.id, quantity: $0) }
        )
    }
}

private struct SelectionRow: View {
    var title: String
    var subtitle: String?
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.muted)
                    .font(.title3.weight(.semibold))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(MegrumTheme.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
