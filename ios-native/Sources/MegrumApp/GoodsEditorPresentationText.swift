import MegrumCore

enum GoodsEditorPresentationText {
    static func navigationTitle(mode: GoodsEditorMode, entryKind: GoodsEntryKind) -> String {
        if mode == .edit {
            return entryKind == .inventory ? "マイグッズを編集" : "ほしいものを編集"
        }
        return entryKind == .inventory ? "マイグッズに追加" : "ほしいものを追加"
    }

    static func headerDescription(usesInventoryCreateFlow: Bool, entryKind: GoodsEntryKind) -> String {
        if usesInventoryCreateFlow {
            return "推し・種別、写真、写真ごとの詳細の順に登録できます。"
        }
        if entryKind == .inventory {
            return "写真、推し、数量、シリーズを編集できます。"
        }
        return "推し、数量、画像、シリーズを編集できます。"
    }

    static func saveButtonTitle(
        mode: GoodsEditorMode,
        entryKind: GoodsEntryKind,
        isMutatingCurrentItem: Bool,
        isCreatingGoodsEntry: Bool
    ) -> String {
        if mode == .edit {
            if isMutatingCurrentItem {
                return "更新しています"
            }
            return entryKind == .wish ? "ほしいものを更新" : "変更を保存"
        }
        if isCreatingGoodsEntry {
            return "保存しています"
        }
        return entryKind == .inventory ? "マイグッズを登録" : "ほしいものを登録"
    }

    static func photoActionTitle(entryKind: GoodsEntryKind, hasDisplayPhoto: Bool) -> String {
        if entryKind == .wish {
            return hasDisplayPhoto ? "差し替え" : "+ 画像を選択"
        }
        return hasDisplayPhoto ? "撮り直す / 差し替え" : "写真を追加"
    }

    static func wishImageHint(hasDisplayPhoto: Bool) -> String {
        hasDisplayPhoto ? "1枚登録済" : "任意"
    }
}
