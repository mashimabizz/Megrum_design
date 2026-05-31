import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsCollectionScreen: View {
    var title: String
    var subtitle: String
    var items: [GoodsItem]
    var showsAddButton: Bool = false
    var appState: MegrumAppState?
    var entryKind: GoodsEntryKind = .inventory
    @State private var columns = GoodsGridLayout.minimumColumns
    @State private var editorRoute: GoodsEditorRoute?
    @State private var isShowingUnavailableAlert = false
    @State private var listingSeedWish: GoodsItem?
    @State private var selectedGroupID: UUID?
    @State private var selectedGoodsTypeID: UUID?

    private var filteredItems: [GoodsItem] {
        items.filter { item in
            let matchesGroup = selectedGroupID == nil || item.groupID == selectedGroupID
            let matchesGoodsType = selectedGoodsTypeID == nil || item.goodsTypeID == selectedGoodsTypeID
            return matchesGroup && matchesGoodsType
        }
    }

    private var hasActiveFilters: Bool {
        selectedGroupID != nil || selectedGoodsTypeID != nil
    }

    private var isShowingLoadingState: Bool {
        appState?.isLoading == true && items.isEmpty
    }

    private var emptyMessageTitle: String {
        if hasActiveFilters {
            return "条件に合うグッズがありません"
        }
        if title == "個別募集" {
            return "個別募集はまだありません"
        }
        switch entryKind {
        case .inventory:
            return "在庫はまだありません"
        case .wish:
            return "Wishはまだありません"
        }
    }

    private var addButtonLabel: String {
        entryKind == .inventory ? "在庫に追加" : "Wishに追加"
    }

    private var addButtonHint: String {
        entryKind == .inventory ? "新しい在庫の登録シートを開きます" : "新しいWishの登録シートを開きます"
    }

    private var emptyMessageSystemImage: String {
        if hasActiveFilters {
            return "line.3.horizontal.decrease.circle"
        }
        if title == "個別募集" {
            return "rectangle.stack.badge.plus"
        }
        switch entryKind {
        case .inventory:
            return "shippingbox"
        case .wish:
            return "heart"
        }
    }

    private var emptyMessageDetail: String {
        if hasActiveFilters {
            return "フィルターを変えると表示されることがあります。"
        }
        if title == "個別募集" {
            return "条件を指定した募集は、Wishから作成できます。"
        }
        switch entryKind {
        case .inventory:
            return "譲る候補を登録すると、検索や打診に使えるようになります。"
        case .wish:
            return "探したいグッズを登録すると、候補探しに使えるようになります。"
        }
    }

    private var emptyMessageActionTitle: String? {
        showsAddButton && !hasActiveFilters ? addButtonLabel : nil
    }

    private var emptyMessageAction: (() -> Void)? {
        guard emptyMessageActionTitle != nil else {
            return nil
        }
        return { openAddForm() }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    CollectionHeader(title: title, subtitle: subtitle, columns: $columns)
                    if let appState {
                        CollectionFilterBar(
                            appState: appState,
                            selectedGroupID: $selectedGroupID,
                            selectedGoodsTypeID: $selectedGoodsTypeID
                        )
                    }
                    if isShowingLoadingState {
                        CollectionGridSkeleton(columns: columns)
                    } else if filteredItems.isEmpty {
                        EmptyCollectionMessage(
                            title: emptyMessageTitle,
                            systemImage: emptyMessageSystemImage,
                            message: emptyMessageDetail,
                            actionTitle: emptyMessageActionTitle,
                            action: emptyMessageAction
                        )
                    } else {
                        GoodsGrid(
                            items: filteredItems,
                            columns: columns,
                            viewerID: appState?.viewer?.id,
                            onCreateIndividualListing: canCreateListingFromItems ? { listingSeedWish = $0 } : nil,
                            onEditItem: appState == nil ? nil : { editorRoute = .edit($0, entryKind) },
                            onHideItem: appState == nil ? nil : { hideItem($0) },
                            onDeleteItem: appState == nil ? nil : { deleteItem($0) },
                            busyItemID: appState?.mutatingGoodsItemID
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, showsAddButton ? 118 : 92)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .megrumHiddenNavigationBar()

            if showsAddButton {
                AddGoodsButton(accessibilityLabel: addButtonLabel, accessibilityHint: addButtonHint, action: openAddForm)
                .padding(.leading, 24)
                .padding(.bottom, 22)
            }
        }
        .sheet(item: $editorRoute) { route in
            if let appState {
                NavigationStack {
                    GoodsEditorSheet(
                        appState: appState,
                        route: route
                    )
                }
            }
        }
        .sheet(item: $listingSeedWish) { item in
            if let appState {
                NavigationStack {
                    IndividualListingEditorSheet(
                        appState: appState,
                        preselectedWishID: item.id
                    )
                }
            }
        }
        .alert("追加できません", isPresented: $isShowingUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("データ保存の準備がまだ整っていません。")
        }
        .task {
            await loadFilterChoicesIfNeeded()
        }
    }

    private func loadFilterChoicesIfNeeded() async {
        guard let appState else {
            return
        }
        if appState.oshiGroups.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
    }

    private func hideItem(_ item: GoodsItem) {
        guard let appState else {
            return
        }
        Task {
            _ = await appState.archiveGoodsItem(item.id)
        }
    }

    private func deleteItem(_ item: GoodsItem) {
        guard let appState else {
            return
        }
        Task {
            _ = await appState.deleteGoodsItem(item.id)
        }
    }

    private var canCreateListingFromItems: Bool {
        appState != nil && entryKind == .wish
    }

    private func openAddForm() {
        if appState == nil {
            isShowingUnavailableAlert = true
        } else {
            editorRoute = .create(entryKind)
        }
    }
}

struct WishCollectionScreen: View {
    var items: [WishItem]
    var appState: MegrumAppState?
    @State private var selectedSection: WishSection = .wishes

    private enum WishSection: String, CaseIterable, Identifiable {
        case wishes = "Wish"
        case listings = "個別募集"

        var id: String { rawValue }
    }

    private var goodsLikeItems: [GoodsItem] {
        items.map {
            GoodsItem(
                id: $0.id,
                ownerID: $0.ownerID,
                groupID: $0.groupID,
                memberID: $0.memberID,
                goodsTypeID: $0.goodsTypeID,
                title: $0.title,
                tags: $0.tags
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("表示", selection: $selectedSection) {
                ForEach(WishSection.allCases) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 6)
            .background(MegrumTheme.canvas)

            Group {
                switch selectedSection {
                case .wishes:
                    GoodsCollectionScreen(
                        title: "Wish",
                        subtitle: "ほしいグッズ",
                        items: goodsLikeItems,
                        showsAddButton: true,
                        appState: appState,
                        entryKind: .wish
                    )
                case .listings:
                    if let appState {
                        IndividualListingsScreen(appState: appState)
                    } else {
                        GoodsCollectionScreen(
                            title: "個別募集",
                            subtitle: "条件を指定した募集",
                            items: [],
                            showsAddButton: false
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }
}

private struct CollectionHeader: View {
    var title: String
    var subtitle: String
    @Binding var columns: Int

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Text(subtitle)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            Spacer()

            ColumnToggleButton(columns: $columns)
                .padding(.top, 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ColumnToggleButton: View {
    @Binding var columns: Int

    private var layout: GoodsGridLayout {
        GoodsGridLayout(columns: columns)
    }

    var body: some View {
        Button {
            columns = layout.nextColumns
        } label: {
            HStack(spacing: 8) {
                GridColumnGlyph(columns: layout.columns)

                Text("\(layout.columns)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MegrumTheme.ink)
            }
            .frame(width: 64, height: 44)
            .background(.regularMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.58), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("表示列数を変更")
        .accessibilityValue("\(layout.columns)列")
        .accessibilityHint("タップすると\(layout.nextColumns)列に切り替えます")
    }
}

private struct GridColumnGlyph: View {
    var columns: Int

    private var layout: GoodsGridLayout {
        GoodsGridLayout(columns: columns)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<GoodsGridLayout.maximumColumns, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index < layout.columns ? MegrumTheme.ink : MegrumTheme.ink.opacity(0.18))
                    .frame(width: 4, height: index < layout.columns ? 18 : 12)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct AddGoodsButton: View {
    var accessibilityLabel: String
    var accessibilityHint: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 68, height: 68)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.pink],
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
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}

private struct CollectionFilterBar: View {
    @ObservedObject var appState: MegrumAppState
    @Binding var selectedGroupID: UUID?
    @Binding var selectedGoodsTypeID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterChoiceRow(title: "グループ", isLoading: appState.isLoadingOshiGroups) {
                ChoiceChip(title: "すべて", isSelected: selectedGroupID == nil) {
                    selectedGroupID = nil
                }
                ForEach(appState.oshiGroups) { group in
                    ChoiceChip(title: group.name, isSelected: selectedGroupID == group.id) {
                        selectedGroupID = group.id
                    }
                }
            }

            FilterChoiceRow(title: "グッズ種別", isLoading: appState.isLoadingGoodsTypes) {
                ChoiceChip(title: "すべて", isSelected: selectedGoodsTypeID == nil) {
                    selectedGoodsTypeID = nil
                }
                ForEach(appState.goodsTypes) { goodsType in
                    ChoiceChip(title: goodsType.name, isSelected: selectedGoodsTypeID == goodsType.id) {
                        selectedGoodsTypeID = goodsType.id
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

private struct FilterChoiceRow<Content: View>: View {
    var title: String
    var isLoading: Bool
    var content: Content

    init(title: String, isLoading: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isLoading = isLoading
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    content
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct EmptyCollectionMessage: View {
    var title: String
    var systemImage: String
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
        } description: {
            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
        } actions: {
            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(MegrumTheme.lavender)
            }
        }
        .foregroundStyle(MegrumTheme.muted)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.55), lineWidth: 1)
        }
    }
}

private struct CollectionGridSkeleton: View {
    var columns: Int

    private var layout: GoodsGridLayout {
        GoodsGridLayout(columns: columns)
    }

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: GoodsGridLayout.columnSpacing), count: layout.columns)
    }

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: GoodsGridLayout.rowSpacing) {
            ForEach(0..<layout.skeletonTileCount, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: GoodsGridLayout.tileCornerRadius, style: .continuous)
                        .fill(MegrumTheme.lavender.opacity(0.12))
                        .aspectRatio(GoodsGridLayout.tileAspectRatio, contentMode: .fit)
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(MegrumTheme.lavender.opacity(0.12))
                        .frame(height: 13)
                }
                .redacted(reason: .placeholder)
            }
        }
        .accessibilityLabel("グッズを読み込み中")
    }
}

private struct GoodsEntryEditorSheet: View {
    @ObservedObject var appState: MegrumAppState
    var kind: GoodsEntryKind
    var title: String

    @Environment(\.dismiss) private var dismiss
    @State private var goodsTitle = ""
    @State private var selectedGroupID: UUID?
    @State private var selectedGoodsTypeID: UUID?
    @State private var quantity = 1
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                titleField
                choiceSection(
                    title: "グループ",
                    isLoading: appState.isLoadingOshiGroups,
                    emptyText: "グループを読み込めませんでした"
                ) {
                    groupChips
                }
                choiceSection(
                    title: "グッズ種別",
                    isLoading: appState.isLoadingGoodsTypes,
                    emptyText: "グッズ種別を読み込めませんでした"
                ) {
                    goodsTypeChips
                }
                quantityStepper
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle(title)
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .task {
            await loadChoices()
        }
        .onChange(of: appState.oshiGroups) { _, _ in
            assignDefaultSelections()
        }
        .onChange(of: appState.goodsTypes) { _, _ in
            assignDefaultSelections()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(kind == .inventory ? "在庫に追加" : "Wishに追加")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("必須項目だけで登録できます。写真やタグは詳細画面で追加します。")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("グッズ名")
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
            #if os(iOS)
            TextField("例：ランダムトレカ A", text: $goodsTitle)
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .title)
                .submitLabel(.done)
                .megrumTextFieldStyle()
            #else
            TextField("例：ランダムトレカ A", text: $goodsTitle)
                .focused($focusedField, equals: Field.title)
                .megrumTextFieldStyle()
            #endif
        }
    }

    private var groupChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(appState.oshiGroups) { group in
                    ChoiceChip(
                        title: group.name,
                        isSelected: selectedGroupID == group.id
                    ) {
                        selectedGroupID = group.id
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var goodsTypeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(appState.goodsTypes) { goodsType in
                    ChoiceChip(
                        title: goodsType.name,
                        isSelected: selectedGoodsTypeID == goodsType.id
                    ) {
                        selectedGoodsTypeID = goodsType.id
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var quantityStepper: some View {
        Stepper(value: $quantity, in: 1...999) {
            VStack(alignment: .leading, spacing: 4) {
                Text("個数")
                    .font(.headline.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
                Text("\(quantity)")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.58), lineWidth: 1)
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                await save()
            }
        } label: {
            HStack(spacing: 10) {
                if appState.isCreatingGoodsEntry {
                    ProgressView()
                        .tint(.white)
                }
                Text(appState.isCreatingGoodsEntry ? "保存しています" : "保存する")
                    .font(.headline.weight(.black))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.borderedProminent)
        .tint(MegrumTheme.lavender)
        .disabled(!canSave || appState.isCreatingGoodsEntry)
    }

    private func choiceSection<Content: View>(
        title: String,
        isLoading: Bool,
        emptyText: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if isLoading {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MegrumTheme.lavender.opacity(0.12))
                    .frame(height: 44)
                    .redacted(reason: .placeholder)
            } else if (title == "グループ" && appState.oshiGroups.isEmpty)
                || (title == "グッズ種別" && appState.goodsTypes.isEmpty) {
                Text(emptyText)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MegrumTheme.muted)
                    .padding(.vertical, 4)
            } else {
                content()
            }
        }
    }

    private var canSave: Bool {
        !goodsTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedGroupID != nil
            && selectedGoodsTypeID != nil
    }

    private func loadChoices() async {
        if appState.oshiGroups.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
        assignDefaultSelections()
        focusedField = .title
    }

    private func assignDefaultSelections() {
        if selectedGroupID == nil {
            selectedGroupID = appState.oshiGroups.first?.id
        }
        if selectedGoodsTypeID == nil {
            selectedGoodsTypeID = appState.goodsTypes.first?.id
        }
    }

    private func save() async {
        guard let selectedGroupID, let selectedGoodsTypeID else {
            return
        }
        let saved = await appState.createGoodsEntry(
            GoodsEntryInput(
                kind: kind,
                title: goodsTitle,
                groupID: selectedGroupID,
                goodsTypeID: selectedGoodsTypeID,
                quantity: quantity
            )
        )
        if saved {
            dismiss()
        }
    }
}

private struct ChoiceChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(backgroundStyle, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(isSelected ? 0.7 : 0.45), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var backgroundStyle: some ShapeStyle {
        isSelected
            ? AnyShapeStyle(MegrumTheme.lavender)
            : AnyShapeStyle(.regularMaterial)
    }
}

struct ScreenTitle: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(subtitle)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
