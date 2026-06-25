import Foundation
import MegrumDesign
import SwiftUI

#if DEBUG
enum MeguriDesignMetrics {
    static let previewWidth: CGFloat = 390
    static let previewHeight: CGFloat = 844
    static let edgePadding: CGFloat = 18
    static let headerTop: CGFloat = 28
    static let mapTop: CGFloat = 78
    static let tabBarHeight: CGFloat = 74
    static let sheetCornerRadius: CGFloat = 28
    static let listImageSize: CGFloat = 58
    static let expandedListImageSize: CGFloat = 60
}

extension View {
    @ViewBuilder
    func meguriDesignPreviewChromeHidden() -> some View {
        #if os(iOS)
        self
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
        #else
        self
        #endif
    }
}

enum MeguriDesignColors {
    static let canvas = Color(red: 0.986, green: 0.980, blue: 0.990)
    static let panel = Color.white.opacity(0.95)
    static let border = MegrumTheme.ink.opacity(0.09)
    static let shadow = MegrumTheme.ink.opacity(0.10)
    static let lavenderSoft = MegrumTheme.lavender.opacity(0.14)
    static let lavenderPale = MegrumTheme.lavender.opacity(0.09)
}

struct MeguriDesignTopic: Identifiable {
    let id = UUID()
    var title: String
    var excerpt: String
    var imageName: String
    var tag: String
    var replyCount: Int
    var avatars: [String]
}

extension MeguriDesignTopic {
    static let samples = [
        MeguriDesignTopic(
            title: "物販列どのくらい？",
            excerpt: "いま並んでる方いますか？だいたいどのあたりまでか...",
            imageName: "twice_sana_1",
            tag: "物販エリア",
            replyCount: 28,
            avatars: ["twice_momo_1", "aespa_ningning", "bts_jimin"]
        ),
        MeguriDesignTopic(
            title: "終演後どこで待つ？",
            excerpt: "終わったあと、みんなどこに集まる予定ですか？",
            imageName: "twice_momo_2",
            tag: "会場横",
            replyCount: 17,
            avatars: ["bts_v", "twice_momo_2", "svt_joshua"]
        ),
        MeguriDesignTopic(
            title: "開封した人いる？",
            excerpt: "トレーディング開封した人いますか？推し出た方見せ...",
            imageName: "twice_dahyun_1",
            tag: "めぐり広場",
            replyCount: 12,
            avatars: ["twice_momo_1", "aespa_ningning_2", "bts_jungkook"]
        ),
        MeguriDesignTopic(
            title: "銀テ交換したい人いる？",
            excerpt: "余っている色があるので、探している人がいれば...",
            imageName: "twice_penlight",
            tag: "同じ現場",
            replyCount: 9,
            avatars: ["aespa_ningning", "svt_scoups", "bts_v"]
        ),
        MeguriDesignTopic(
            title: "同行の人とはぐれた",
            excerpt: "同じ公演の方、少しだけ状況教えてください",
            imageName: "bts_jungkook",
            tag: "案内",
            replyCount: 6,
            avatars: ["svt_joshua", "twice_momo_2", "aespa_ningning_2"]
        ),
        MeguriDesignTopic(
            title: "グルーム見ました",
            excerpt: "この写真のグッズがかわいい、どこで撮りましたか？",
            imageName: "aespa_ningning_2",
            tag: "グルーム",
            replyCount: 5,
            avatars: ["twice_sana_1", "bts_jimin", "svt_mingyu"]
        )
    ]
}
#endif
