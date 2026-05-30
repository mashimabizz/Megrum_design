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
    @State private var columns = 3
    @State private var isShowingAddForm = false
    @State private var isShowingUnavailableAlert = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    CollectionHeader(title: title, subtitle: subtitle, columns: $columns)
                    GoodsGrid(items: items, columns: columns)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, showsAddButton ? 118 : 92)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .megrumHiddenNavigationBar()

            if showsAddButton {
                AddGoodsButton {
                    if appState == nil {
                        isShowingUnavailableAlert = true
                    } else {
                        isShowingAddForm = true
                    }
                }
                .padding(.leading, 24)
                .padding(.bottom, 22)
            }
        }
        .sheet(isPresented: $isShowingAddForm) {
            if let appState {
                NavigationStack {
                    GoodsEntryEditorSheet(
                        appState: appState,
                        kind: entryKind,
                        title: title
                    )
                }
            }
        }
        .alert("追加できません", isPresented: $isShowingUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("データ保存の準備がまだ整っていません。")
        }
    }
}

struct WishCollectionScreen: View {
    var items: [WishItem]
    var appState: MegrumAppState?

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
        GoodsCollectionScreen(
            title: "Wish",
            subtitle: "ほしいグッズ",
            items: goodsLikeItems,
            showsAddButton: true,
            appState: appState,
            entryKind: .wish
        )
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

    var body: some View {
        Button {
            columns = columns >= 5 ? 3 : columns + 1
        } label: {
            HStack(spacing: 3) {
                ForEach(0..<columns, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(MegrumTheme.ink, lineWidth: 2)
                        .frame(width: 9, height: 14)
                }
            }
            .frame(width: 54, height: 44)
            .background(.regularMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.58), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("表示列数を変更")
        .accessibilityValue("\(columns)列")
    }
}

private struct AddGoodsButton: View {
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
        .accessibilityLabel("追加")
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
