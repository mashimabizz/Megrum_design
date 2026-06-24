import MegrumCore

enum GoodsCollectionDeleteConfirmationPresentation {
    static let title = "本当に削除しますか？"
    static let destructiveTitle = "削除する"

    static func message(for item: GoodsItem) -> String {
        "「\(item.title)」を削除します。"
    }

    static func message(selectedCount: Int) -> String {
        "\(max(0, selectedCount))件のグッズを削除します。"
    }
}
