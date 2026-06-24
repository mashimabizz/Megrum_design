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

struct MeguriHomeHeader: View {
    var body: some View {
        ZStack {
            Text("めぐり")
                .font(.system(size: 23, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
    }
}

struct MeguriMapOverlay: View {
    var mode: MeguriHomeSheetMode

    var body: some View {
        ZStack {
            MeguriPinBubble(title: "物販列")
                .position(x: 238, y: mode == .normal ? 170 : 0)
                .opacity(mode == .normal ? 1 : 0)

            MeguriPinBubble(title: "会場横")
                .position(x: 96, y: mode == .normal ? 260 : 0)
                .opacity(mode == .normal ? 1 : 0)

            MeguriPinBubble(title: "駅前広場")
                .position(x: 186, y: mode == .normal ? 372 : 0)
                .opacity(mode == .normal ? 1 : 0)

            MeguriImagePin(imageName: "twice_penlight", size: mode == .normal ? 62 : 56)
                .position(x: mode == .normal ? 58 : 74, y: mode == .normal ? 345 : 148)

            MeguriImagePin(imageName: "twice_momo_1", size: 66)
                .position(x: mode == .normal ? 118 : 178, y: mode == .normal ? 158 : 86)

            MeguriImagePin(imageName: "twice_sana_1", size: mode == .normal ? 60 : 58)
                .position(x: mode == .normal ? 198 : 304, y: mode == .normal ? 292 : 134)

            MeguriImagePin(imageName: "svt_mingyu", size: 62)
                .position(x: mode == .normal ? 322 : 292, y: mode == .normal ? 215 : 108)

            if mode == .normal {
                MeguriStackedPin()
                    .position(x: 290, y: 320)
            } else {
                MeguriChatPin()
                    .position(x: 260, y: 76)
                MeguriChatPin()
                    .position(x: 330, y: 52)
            }
        }
    }
}

struct MeguriPinBubble: View {
    var title: String

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(MegrumTheme.lavender, in: Circle())
                .shadow(color: MegrumTheme.lavender.opacity(0.30), radius: 12, y: 7)

            Circle()
                .fill(MegrumTheme.lavender)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .offset(y: -1)
        }
    }
}

struct MeguriChatPin: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "ellipsis.message.fill")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(MegrumTheme.lavender, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.90), lineWidth: 3))
                .shadow(color: MegrumTheme.lavender.opacity(0.30), radius: 10, y: 7)

            Circle()
                .fill(MegrumTheme.lavender)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .offset(y: -1)
        }
    }
}

struct MeguriImagePin: View {
    var imageName: String
    var size: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            MeguriImageCircle(imageName: imageName, size: size)
                .overlay(Circle().stroke(.white, lineWidth: 4))
                .shadow(color: MeguriDesignColors.shadow, radius: 12, y: 7)

            Circle()
                .fill(MegrumTheme.lavender)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .offset(y: -1)
        }
    }
}

struct MeguriStackedPin: View {
    var body: some View {
        ZStack {
            MeguriImageCircle(imageName: "bts_v", size: 54)
                .offset(x: -12, y: -3)
            MeguriImageCircle(imageName: "aespa_ningning", size: 54)
                .offset(x: 8, y: -8)
            Text("+7")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.88), in: Circle())
                .offset(x: 10, y: 8)
        }
        .frame(width: 66, height: 66)
        .background(.white.opacity(0.62), in: Circle())
        .shadow(color: MeguriDesignColors.shadow, radius: 13, y: 7)
    }
}

struct MeguriMapControls: View {
    var body: some View {
        VStack(spacing: 12) {
            MeguriFloatingIcon(systemName: "scope")
            MeguriFloatingIcon(systemName: "location.fill")
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

struct MeguriFloatingIcon: View {
    var systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .frame(width: 50, height: 50)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: MeguriDesignColors.shadow, radius: 12, y: 7)
            .accessibilityHidden(true)
    }
}

struct MeguriConversationSheet: View {
    var mode: MeguriHomeSheetMode

    private var topics: [MeguriDesignTopic] {
        switch mode {
        case .normal:
            Array(MeguriDesignTopic.samples.prefix(3))
        case .expanded:
            MeguriDesignTopic.samples
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(MegrumTheme.muted.opacity(0.38))
                .frame(width: 38, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 18)

            HStack(alignment: .top) {
                Text("今この場で話されていること")
                    .font(.system(size: mode == .normal ? 19 : 18, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)

                Spacer()

                HStack(spacing: 20) {
                    MeguriSheetAction(systemName: "camera", title: "グルーム")
                    MeguriSheetAction(systemName: "pencil", title: "話題")
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(Array(topics.enumerated()), id: \.element.id) { index, topic in
                    if index > 0 {
                        Divider()
                            .background(MeguriDesignColors.border)
                            .padding(.leading, mode == .normal ? 20 : 16)
                    }

                    if mode == .normal {
                        MeguriTopicRow(topic: topic)
                            .padding(.horizontal, 20)
                    } else {
                        MeguriExpandedTopicRow(topic: topic)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 16)

            Spacer(minLength: 0)
        }
        .background(
            RoundedRectangle(cornerRadius: MeguriDesignMetrics.sheetCornerRadius, style: .continuous)
                .fill(MeguriDesignColors.panel)
                .shadow(color: MeguriDesignColors.shadow, radius: 22, y: -8)
        )
    }
}

struct MeguriSheetAction: View {
    var systemName: String
    var title: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.96), in: Circle())
                .overlay(Circle().stroke(MegrumTheme.ink.opacity(0.07), lineWidth: 1))
                .shadow(color: MeguriDesignColors.shadow, radius: 10, y: 5)

            Text(title)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
    }
}

struct MeguriTopicRow: View {
    var topic: MeguriDesignTopic

    var body: some View {
        HStack(spacing: 14) {
            MeguriRoundedImage(imageName: topic.imageName, size: MeguriDesignMetrics.listImageSize, radius: 12)

            VStack(alignment: .leading, spacing: 6) {
                Text(topic.title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)

                Text(topic.excerpt)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.76))
                    .lineLimit(2)
                    .lineSpacing(2)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 9) {
                MeguriAvatarStack(imageNames: topic.avatars, size: 21)

                HStack(spacing: 6) {
                    Image(systemName: "bubble")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    Text("\(topic.replyCount)")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(MegrumTheme.ink.opacity(0.65))

                Text(topic.tag)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 10)
                    .frame(height: 23)
                    .background(MeguriDesignColors.lavenderPale, in: Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
        .frame(height: 96)
    }
}

struct MeguriExpandedTopicRow: View {
    var topic: MeguriDesignTopic

    var body: some View {
        HStack(spacing: 14) {
            MeguriRoundedImage(imageName: topic.imageName, size: MeguriDesignMetrics.expandedListImageSize, radius: 12)

            VStack(alignment: .leading, spacing: 7) {
                Text(topic.title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)

                Text(topic.excerpt)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.76))
                    .lineLimit(2)
                    .lineSpacing(2)

                MeguriAvatarStack(imageNames: topic.avatars, size: 20)
            }

            Spacer(minLength: 6)

            HStack(spacing: 7) {
                Image(systemName: "bubble")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                Text("\(topic.replyCount)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(MegrumTheme.ink.opacity(0.68))
            .frame(width: 64, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.84))
        }
        .frame(height: 78)
    }
}

struct MeguriTabBar: View {
    var mode: MeguriHomeSheetMode

    private var items: [(String, String, Bool)] {
        switch mode {
        case .normal:
            [
                ("house", "ホーム", false),
                ("magnifyingglass", "さがす", false),
                ("plus", "出品", false),
                ("mappin.and.ellipse", "めぐり", true),
                ("person", "マイページ", false)
            ]
        case .expanded:
            [
                ("house", "ホーム", false),
                ("magnifyingglass", "さがす", false),
                ("person.3.fill", "めぐり", true),
                ("bell", "お知らせ", false),
                ("person", "マイページ", false)
            ]
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                MeguriTabItem(systemName: item.0, title: item.1, isSelected: item.2, isCenterAdd: item.0 == "plus")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .frame(height: MeguriDesignMetrics.tabBarHeight)
        .background(.white.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MeguriDesignColors.border)
                .frame(height: 1)
        }
    }
}

struct MeguriTabItem: View {
    var systemName: String
    var title: String
    var isSelected: Bool
    var isCenterAdd: Bool

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemName)
                .font(.system(size: isCenterAdd ? 22 : 20, weight: .medium, design: .rounded))
                .foregroundStyle(isCenterAdd ? .white : (isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.72)))
                .frame(width: isCenterAdd ? 40 : 32, height: isCenterAdd ? 40 : 28)
                .background {
                    if isCenterAdd {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(MegrumTheme.lavender)
                    } else if isSelected {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(MegrumTheme.lavender.opacity(0.10))
                            .frame(width: 64, height: 52)
                    }
                }

            Text(title)
                .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.70))
        }
    }
}
#endif
