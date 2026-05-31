import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    @State private var isShowingEditor = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ScreenTitle(title: "個別募集", subtitle: "条件を指定して募集する")

                    if appState.isLoadingIndividualListings {
                        listingSkeletons
                    } else if appState.listings.isEmpty {
                        EmptyListingView()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(appState.listings) { listing in
                                IndividualListingCard(
                                    listing: listing,
                                    inventoryByID: inventoryByID,
                                    wishByID: wishByID
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 118)
            }
            .refreshable {
                await appState.loadIndividualListings()
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .megrumHiddenNavigationBar()

            AddIndividualListingButton {
                isShowingEditor = true
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
        .sheet(isPresented: $isShowingEditor) {
            NavigationStack {
                IndividualListingEditorSheet(appState: appState)
            }
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

private struct IndividualListingCard: View {
    var listing: IndividualListing
    var inventoryByID: [UUID: GoodsItem]
    var wishByID: [UUID: WishItem]

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
                    items: primaryOptionItems
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

    private var primaryOptionItems: [ListedItemLabel] {
        guard let option = listing.options.sorted(by: { $0.position < $1.position }).first else {
            return [ListedItemLabel(title: "未設定", quantity: 1)]
        }
        if option.isCashOffer, let amount = option.cashAmount {
            return [ListedItemLabel(title: "定価 \(amount)円", quantity: 1)]
        }
        return option.wishes.map { quantity in
            ListedItemLabel(
                title: wishByID[quantity.itemID]?.title ?? "Wish",
                quantity: quantity.quantity
            )
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

struct IndividualListingEditorSheet: View {
    @ObservedObject var appState: MegrumAppState
    var preselectedWishID: UUID?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedHaveIDs: Set<UUID> = []
    @State private var selectedWishIDs: Set<UUID> = []
    @State private var haveLogic: ListingLogic = .all
    @State private var wishLogic: ListingLogic = .one
    @State private var exchangeType: IndividualListingExchangeType = .any
    @State private var note = ""
    @State private var didApplyPreset = false

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
                            isSelected: selectedHaveIDs.contains(item.id)
                        ) {
                            toggleHave(item.id)
                        }
                    }
                    Picker("譲る条件", selection: $haveLogic) {
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
                            isSelected: selectedWishIDs.contains(item.id)
                        ) {
                            toggleWish(item.id)
                        }
                    }
                    Picker("求める条件", selection: $wishLogic) {
                        ForEach(ListingLogic.allCases) { logic in
                            Text(logic.displayName).tag(logic)
                        }
                    }
                }
            }

            Section("交換条件") {
                Picker("種類", selection: $exchangeType) {
                    ForEach(IndividualListingExchangeType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                TextField("メモ（任意）", text: $note, axis: .vertical)
                    .lineLimit(2...4)
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
        .navigationTitle("個別募集を作成")
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
                        Text("保存")
                    }
                }
                .disabled(validationMessage != nil || appState.isCreatingIndividualListing)
            }
        }
        .onAppear {
            applyPresetIfNeeded()
        }
    }

    private var selectedHaveItems: [GoodsItem] {
        appState.inventory.filter { selectedHaveIDs.contains($0.id) }
    }

    private var selectedWishItems: [WishItem] {
        appState.wishes.filter { selectedWishIDs.contains($0.id) }
    }

    private var validationMessage: String? {
        if selectedHaveIDs.isEmpty {
            return "譲るものを選択してください"
        }
        if selectedWishIDs.isEmpty {
            return "求めるものを選択してください"
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

    private func toggleHave(_ id: UUID) {
        if selectedHaveIDs.contains(id) {
            selectedHaveIDs.remove(id)
        } else {
            selectedHaveIDs.insert(id)
        }
    }

    private func toggleWish(_ id: UUID) {
        if selectedWishIDs.contains(id) {
            selectedWishIDs.remove(id)
        } else {
            selectedWishIDs.insert(id)
        }
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

    private func save() async {
        guard validationMessage == nil else {
            return
        }
        let saved = await appState.createIndividualListing(
            IndividualListingCreateInput(
                haveItems: selectedHaveItems.map { ListingItemQuantity(itemID: $0.id, quantity: 1) },
                haveLogic: haveLogic,
                wishItems: selectedWishItems.map { ListingItemQuantity(itemID: $0.id, quantity: 1) },
                wishLogic: wishLogic,
                exchangeType: exchangeType,
                note: note
            )
        )
        if saved {
            dismiss()
        }
    }

    private func applyPresetIfNeeded() {
        guard !didApplyPreset else {
            return
        }
        didApplyPreset = true
        if let preselectedWishID {
            selectedWishIDs.insert(preselectedWishID)
        }
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
