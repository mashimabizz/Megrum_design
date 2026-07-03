struct GoodsInventoryCreateMetaFooterPresentationState: Equatable {
    var isShowingMemberDialog = false

    mutating func showMemberDialog() {
        isShowingMemberDialog = true
    }

    func saveTitle(selectedCount: Int, totalCount: Int) -> String {
        if selectedCount == 0, totalCount > 0 {
            return "画像を選択してください"
        }
        return "\(totalCount)件まとめて登録"
    }
}
