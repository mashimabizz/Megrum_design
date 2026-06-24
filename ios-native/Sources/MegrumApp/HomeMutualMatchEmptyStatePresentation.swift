import Foundation

struct HomeMutualMatchEmptyStatePresentation: Equatable {
    var listingCount: Int

    init(listingCount: Int) {
        self.listingCount = max(0, listingCount)
    }

    var title: String {
        if listingCount == 0 {
            return "個別募集を作成しましょう"
        }
        return "個別募集を\(listingCount)件作成中"
    }

    var message: String {
        if listingCount == 0 {
            return "個別募集を1件も作っていないので、譲れるものと欲しいものを設定してみましょう。"
        }
        return "今作成中の個別募集は\(listingCount)件です。譲るものや欲しい条件をもっと設定すると、相互マッチが増えやすくなります。"
    }

    var buttonTitle: String {
        listingCount == 0 ? "個別募集を作成" : "個別募集を追加"
    }
}
