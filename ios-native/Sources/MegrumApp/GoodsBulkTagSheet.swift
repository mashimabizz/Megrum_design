import MegrumDesign
import Foundation
import SwiftUI

struct GoodsBulkTagRoute: Identifiable, Equatable {
    var itemIDs: Set<UUID>

    var id: String {
        itemIDs.map(\.uuidString).sorted().joined(separator: "-")
    }
}

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

    var body: some View {
        NavigationStack {
            Form {
                if !candidateNames.isEmpty {
                    Section {
                        TagCandidatePreviewSelector(
                            candidateNames: candidateNames,
                            previewItemsByTag: previewItemsByTag,
                            selectedNames: $sheetState.selectedCandidateNames,
                            maxSelection: 1,
                            emptyMessage: "このグループに紐づくシリーズ候補はまだありません",
                            onToggle: toggleCandidateTag
                        )
                    } header: {
                        Text("候補")
                    } footer: {
                        Text("候補はもう一度タップすると入力欄に入ります。")
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
                                .foregroundStyle(.red)
                        }
                    } footer: {
                        if googleLensItems.isEmpty {
                            Text("画像を選択すると、Google Lensで検索できます。")
                        } else {
                            Text("選択中のグッズから、画像検索に使う画像を選べます。")
                        }
                    }
                }

                Section {
                    TextField(textFieldPlaceholder, text: $sheetState.tagDraft)
                } header: {
                    Text("追加するシリーズ")
                } footer: {
                    Text(footerText ?? "\(selectedCount)件のグッズに同じシリーズを追加します。")
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
                        MegrumHaptics.performSelectionChanged {
                            onApply(sheetState.trimmedTag)
                            dismiss()
                        }
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

    private func toggleCandidateTag(_ name: String) {
        sheetState.toggleCandidateTag(name)
    }
}
