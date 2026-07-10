import MegrumDesign
import Foundation
import SwiftUI

struct GoodsBulkTagRoute: Identifiable, Equatable {
    var itemIDs: Set<UUID>

    var id: String {
        itemIDs.map(\.uuidString).sorted().joined(separator: "-")
    }
}

/// シリーズ登録シート（iter1226.412 刷新）：
/// 検索ファースト構成。入力欄を最上部に置き、**ペーストボタン**（Google Lens等でコピーした
/// シリーズ名を1タップ投入）と**入力中のインクリメンタル絞り込み**、
/// 既存候補に無い場合の**「新しいシリーズとして追加」行**を備える。
/// 候補チップは従来どおり1タップ目で紐づくグッズ画像をプレビュー、2タップ目で確定。
struct GoodsBulkTagSheet: View {
    var selectedCount: Int
    var candidateNames: [String] = []
    var previewItemsByTag: [String: [TagPreviewItem]] = [:]
    var navigationTitle = "シリーズを設定"
    var textFieldPlaceholder = "例：会場限定"
    var footerText: String?
    var confirmationTitle = "追加"
    var googleLensItems: [GoodsGoogleLensSearchItem] = []
    var isOpeningGoogleLens = false
    var googleLensErrorMessage: String?
    var onOpenGoogleLens: ((GoodsGoogleLensSearchItem.ID) -> Void)?
    var onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var sheetState = GoodsBulkTagSheetState()
    @State private var isShowingGoogleLensPicker = false
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    searchInputRow
                } header: {
                    Text("シリーズ名")
                } footer: {
                    Text(footerText ?? "\(selectedCount)件のグッズに同じシリーズを追加します。")
                }

                if sheetState.showsNewSeriesRow(in: candidateNames) {
                    Section {
                        newSeriesRow
                    }
                }

                if !candidateNames.isEmpty {
                    Section {
                        TagCandidatePreviewSelector(
                            candidateNames: sheetState.filteredCandidates(from: candidateNames),
                            previewItemsByTag: previewItemsByTag,
                            selectedNames: $sheetState.selectedCandidateNames,
                            maxSelection: 1,
                            emptyMessage: "このグループに紐づくシリーズ候補はまだありません",
                            onToggle: toggleCandidateTag
                        )
                    } header: {
                        Text("候補")
                    } footer: {
                        Text("候補は1タップで紐づく画像をプレビュー、もう一度タップで入力欄に入ります。")
                    }
                }

                if onOpenGoogleLens != nil {
                    Section {
                        Button {
                            MegrumHaptics.performSelectionChanged {
                                isShowingGoogleLensPicker = true
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if isOpeningGoogleLens {
                                    ProgressView()
                                } else {
                                    Image(systemName: "camera.viewfinder")
                                }
                                Text("GoogleLensで探す")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .disabled(isOpeningGoogleLens || googleLensItems.isEmpty)

                        if let googleLensErrorMessage, !googleLensErrorMessage.isEmpty {
                            Text(googleLensErrorMessage)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(MegrumTheme.conditionExact)
                        }
                    } footer: {
                        if googleLensItems.isEmpty {
                            Text("画像を選択すると、Google Lensで検索できます。")
                        } else {
                            Text("Google Lensで調べた名前をコピーしたら、上の「ペースト」で貼り付けられます。")
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmationTitle) {
                        applyDraft()
                    }
                    .disabled(!sheetState.canApply)
                }
            }
            .sheet(isPresented: $isShowingGoogleLensPicker) {
                GoodsGoogleLensPickerSheet(items: googleLensItems) { itemID in
                    isShowingGoogleLensPicker = false
                    MegrumHaptics.performSelectionChanged {
                        onOpenGoogleLens?(itemID)
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - 検索入力行（虫眼鏡＋TextField＋ペースト/クリア）

    private var searchInputRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MegrumTheme.muted)

            TextField(textFieldPlaceholder, text: $sheetState.tagDraft)
                .focused($isSearchFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    if sheetState.canApply {
                        applyDraft()
                    }
                }

            if !sheetState.tagDraft.isEmpty {
                Button {
                    sheetState.tagDraft = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(MegrumTheme.muted.opacity(0.6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("入力をクリア")
            }

            #if os(iOS)
            Button {
                pasteFromClipboard()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 12, weight: .semibold))
                    Text("ペースト")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("クリップボードから貼り付け")
            #endif
        }
    }

    /// 既存候補に無い名前を入力中：新規シリーズとして即追加できる行。
    private var newSeriesRow: some View {
        Button {
            applyDraft()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(MegrumTheme.lavender)
                Text("「\(sheetState.trimmedTag)」を新しいシリーズとして追加")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func applyDraft() {
        MegrumHaptics.performSelectionChanged {
            onApply(sheetState.trimmedTag)
            dismiss()
        }
    }

    private func pasteFromClipboard() {
        #if os(iOS)
        guard let text = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty
        else {
            return
        }
        MegrumHaptics.selectionChanged()
        sheetState.tagDraft = text
        isSearchFieldFocused = true
        #endif
    }

    private func toggleCandidateTag(_ name: String) {
        sheetState.toggleCandidateTag(name)
    }
}
