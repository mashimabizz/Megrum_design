import MegrumCore

struct GoodsGridPresentationState: Equatable {
    var detailItem: GoodsItem?
    var actionMessage: String?
    var reportItem: GoodsItem?

    var hasActionMessage: Bool {
        actionMessage != nil
    }

    mutating func showDetail(_ item: GoodsItem) {
        detailItem = item
    }

    mutating func showActionMessage(_ message: String) {
        actionMessage = message
    }

    mutating func clearActionMessage() {
        actionMessage = nil
    }

    mutating func showReport(_ item: GoodsItem) {
        reportItem = item
    }

    mutating func clearReport() {
        reportItem = nil
    }
}
