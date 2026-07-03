import MegrumDesign
import SwiftUI

struct HomeExchangeLocalDateDetailSheet: View {
    var dateKeys: [String]
    var initialDetail: HomeExchangeLocalDateDetail
    var isReadOnly: Bool
    var onSave: ([String], HomeExchangeLocalDateDetail) -> Void
    var onRemove: ([String]) -> Void
    var onCancel: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editorState: HomeExchangeLocalDateDetailEditorState

    init(
        dateKeys: [String],
        initialDetail: HomeExchangeLocalDateDetail,
        isReadOnly: Bool,
        onSave: @escaping ([String], HomeExchangeLocalDateDetail) -> Void,
        onRemove: @escaping ([String]) -> Void,
        onCancel: @escaping ([String]) -> Void
    ) {
        self.dateKeys = dateKeys
        self.initialDetail = initialDetail
        self.isReadOnly = isReadOnly
        self.onSave = onSave
        self.onRemove = onRemove
        self.onCancel = onCancel
        _editorState = State(initialValue: HomeExchangeLocalDateDetailEditorState(detail: initialDetail))
    }

    var body: some View {
        NavigationStack {
            Form {
                if isReadOnly {
                    Section {
                        Label {
                            Text("個別募集から反映")
                                .font(.subheadline.weight(.bold))
                        } icon: {
                            Image(systemName: "doc.text.magnifyingglass")
                        }
                        .foregroundStyle(MegrumTheme.lavender)
                    }
                }

                Section("都道府県") {
                    if isReadOnly {
                        Text(editorState.prefecture.nilIfBlank ?? "未設定")
                            .foregroundStyle(MegrumTheme.ink)
                    } else {
                        Picker("都道府県", selection: $editorState.prefecture) {
                            Text("未設定").tag("")
                            ForEach(JapanesePrefectureCatalog.all, id: \.self) { prefecture in
                                Text(prefecture).tag(prefecture)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(.navigationLink)
                        #endif
                    }
                }

                Section("メモ") {
                    if isReadOnly {
                        Text(editorState.memo.nilIfBlank ?? "未設定")
                            .foregroundStyle(MegrumTheme.ink)
                    } else {
                        TextField("例：東京駅付近で相談", text: $editorState.memo, axis: .vertical)
                            .lineLimit(3...)
                    }
                }

                if !isReadOnly {
                    Section {
                        Button(role: .destructive) {
                            editorState.markFinished()
                            onRemove(dateKeys)
                            dismiss()
                        } label: {
                            Text(removeButtonTitle)
                        }
                    }
                }
            }
            .navigationTitle(sheetTitle)
            .homeExchangeDateDetailSheetChrome()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", action: close)
                }
                if !isReadOnly {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存", action: save)
                            .bold()
                    }
                }
            }
        }
        .homeExchangeDateDetailSheetDetents()
        .onDisappear(perform: cancelIfNeeded)
    }

    private var sheetTitle: String {
        if dateKeys.count == 1, let dateKey = dateKeys.first {
            return HomeExchangeDateKey.displayText(for: dateKey)
        }
        return "\(dateKeys.count)日程の設定"
    }

    private var removeButtonTitle: String {
        dateKeys.count == 1 ? "この日程を削除" : "\(dateKeys.count)日程を削除"
    }

    private func close() {
        dismiss()
    }

    private func cancelIfNeeded() {
        guard editorState.shouldCancelOnDisappear(isReadOnly: isReadOnly) else {
            return
        }
        onCancel(dateKeys)
    }

    private func save() {
        editorState.markFinished()
        onSave(dateKeys, editorState.detailForSave)
        dismiss()
    }
}


private extension View {
    @ViewBuilder
    func homeExchangeDateDetailSheetChrome() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func homeExchangeDateDetailSheetDetents() -> some View {
        #if os(iOS)
        presentationDetents([.medium, .large])
        #else
        self
        #endif
    }
}
