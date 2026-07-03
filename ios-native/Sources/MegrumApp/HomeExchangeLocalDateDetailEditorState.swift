import Foundation

struct HomeExchangeLocalDateDetailEditorState: Equatable {
    var prefecture: String
    var memo: String
    private(set) var didFinish = false

    init(detail: HomeExchangeLocalDateDetail) {
        prefecture = detail.prefecture
        memo = detail.memo
    }

    var detailForSave: HomeExchangeLocalDateDetail {
        HomeExchangeLocalDateDetail(
            prefecture: prefecture.trimmingCharacters(in: .whitespacesAndNewlines),
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    mutating func markFinished() {
        didFinish = true
    }

    func shouldCancelOnDisappear(isReadOnly: Bool) -> Bool {
        !isReadOnly && !didFinish
    }
}
