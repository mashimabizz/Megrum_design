import MapKit
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if DEBUG
struct MeguriHomeDesignPreview: View {
    var sheetMode: MeguriHomeSheetMode = .normal

    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.7056, longitude: 139.7519),
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.014)
        )
    )

    var body: some View {
        ZStack(alignment: .top) {
            MeguriDesignColors.canvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Color.white.opacity(0.98)
                    .frame(height: MeguriDesignMetrics.mapTop)

                Map(position: $cameraPosition, interactionModes: []) {}
                    .overlay(Color.white.opacity(0.24))
                    .frame(height: sheetMode.mapHeight - MeguriDesignMetrics.mapTop)
                    .allowsHitTesting(false)
            }
            .frame(height: sheetMode.mapHeight)
            .ignoresSafeArea(edges: .top)

            MeguriMapOverlay(mode: sheetMode)
                .padding(.top, MeguriDesignMetrics.mapTop)
                .frame(height: sheetMode.mapHeight)

            MeguriHomeHeader()
                .padding(.horizontal, MeguriDesignMetrics.edgePadding)
                .padding(.top, MeguriDesignMetrics.headerTop)

            if sheetMode == .normal {
                MeguriMapControls()
                    .padding(.trailing, 18)
                    .padding(.top, 352)
            }

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: sheetMode.sheetTop)

                MeguriConversationSheet(mode: sheetMode)
                    .frame(height: MeguriDesignMetrics.previewHeight - sheetMode.sheetTop - MeguriDesignMetrics.tabBarHeight + 10)
            }

            VStack {
                Spacer()
                MeguriTabBar(mode: sheetMode)
            }
        }
        .frame(
            width: MeguriDesignMetrics.previewWidth,
            height: MeguriDesignMetrics.previewHeight
        )
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .meguriDesignPreviewChromeHidden()
    }
}

struct MeguriBoardDetailDesignPreview: View {
    var body: some View {
        ZStack {
            MeguriDesignColors.canvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                MeguriBoardDetailHeader()
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                MeguriBoardDetailCard()
                    .padding(.horizontal, 12)
                    .padding(.top, 14)

                Spacer(minLength: 0)
            }

            VStack {
                Spacer()
                MeguriReplyInputBar()
            }
        }
        .frame(
            width: MeguriDesignMetrics.previewWidth,
            height: MeguriDesignMetrics.previewHeight
        )
        .meguriDesignPreviewChromeHidden()
    }
}

enum MeguriHomeSheetMode {
    case normal
    case expanded

    var mapHeight: CGFloat {
        switch self {
        case .normal:
            520
        case .expanded:
            190
        }
    }

    var sheetTop: CGFloat {
        switch self {
        case .normal:
            430
        case .expanded:
            168
        }
    }
}

private enum MeguriDesignMetrics {
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

private extension View {
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

private enum MeguriDesignColors {
    static let canvas = Color(red: 0.986, green: 0.980, blue: 0.990)
    static let panel = Color.white.opacity(0.95)
    static let border = MegrumTheme.ink.opacity(0.09)
    static let shadow = MegrumTheme.ink.opacity(0.10)
    static let lavenderSoft = MegrumTheme.lavender.opacity(0.14)
    static let lavenderPale = MegrumTheme.lavender.opacity(0.09)
}

private struct MeguriDesignTopic: Identifiable {
    let id = UUID()
    var title: String
    var excerpt: String
    var imageName: String
    var tag: String
    var replyCount: Int
    var avatars: [String]
}

private extension MeguriDesignTopic {
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

private struct MeguriHomeHeader: View {
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

private struct MeguriMapOverlay: View {
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

private struct MeguriPinBubble: View {
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

private struct MeguriChatPin: View {
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

private struct MeguriImagePin: View {
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

private struct MeguriStackedPin: View {
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

private struct MeguriMapControls: View {
    var body: some View {
        VStack(spacing: 12) {
            MeguriFloatingIcon(systemName: "scope")
            MeguriFloatingIcon(systemName: "location.fill")
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private struct MeguriFloatingIcon: View {
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

private struct MeguriConversationSheet: View {
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

            MeguriTopicFilters(mode: mode)
                .padding(.top, 18)
                .padding(.horizontal, mode == .normal ? 20 : 16)

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

private struct MeguriSheetAction: View {
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

private struct MeguriTopicFilters: View {
    var mode: MeguriHomeSheetMode

    private var titles: [String] {
        switch mode {
        case .normal:
            ["同じ現場", "同じ推し", "新着", "盛り上がり"]
        case .expanded:
            ["LE SSERAFIM", "Stray Kids", "ブルーロック", "呪術廻戦"]
        }
    }

    var body: some View {
        HStack(spacing: mode == .normal ? 10 : 8) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                Text(title)
                    .font(.system(size: mode == .normal ? 13 : 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(index == 0 ? .white : MegrumTheme.ink.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                    .padding(.horizontal, mode == .normal ? 15 : 13)
                    .frame(height: mode == .normal ? 34 : 30)
                    .frame(maxWidth: .infinity)
                    .background(index == 0 ? MegrumTheme.lavender : .white.opacity(0.88), in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(index == 0 ? MegrumTheme.lavender.opacity(0.0) : MeguriDesignColors.border, lineWidth: 1)
                    }
            }
        }
    }
}

private struct MeguriTopicRow: View {
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

private struct MeguriExpandedTopicRow: View {
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

private struct MeguriTabBar: View {
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

private struct MeguriTabItem: View {
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

private struct MeguriBoardDetailHeader: View {
    var body: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 44, height: 44, alignment: .leading)

            Spacer()

            Text("話題")
                .font(.system(size: 23, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer()

            Image(systemName: "ellipsis")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 44, height: 44, alignment: .trailing)
        }
    }
}

private struct MeguriBoardDetailCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LE SSERAFIM")
                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 13)
                .frame(height: 23)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.lavender.opacity(0.20), MegrumTheme.lavender.opacity(0.07)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )

            Text("物販列どのくらい？")
                .font(.system(size: 23, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            HStack(alignment: .top, spacing: 12) {
                MeguriImageCircle(imageName: "twice_sana_1", size: 42)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 12) {
                        Text("miki")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                        Text("たった今")
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    Text("いま並んでる方いますか？\nだいたいどのあたりまでか知りたいです。")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(alignment: .center) {
                MeguriAvatarStack(imageNames: ["bts_jungkook", "svt_mingyu", "twice_momo_2", "twice_penlight", "aespa_ningning"], size: 28, overlap: -7)

                Text("+23")
                    .font(.system(size: 13.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 38, height: 38)
                    .background(MeguriDesignColors.lavenderPale, in: Circle())

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                        Text("28")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(MegrumTheme.lavender)

                    Text("話題への返信数")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }

            Divider()
                .background(MeguriDesignColors.border)

            HStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(MegrumTheme.muted)
                Text("この話題に参加している人")
                    .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }

            VStack(spacing: 7) {
                MeguriReplyRow(
                    avatar: "bts_jungkook",
                    name: "yuna",
                    time: "2分前",
                    bodyText: "30分くらいで進みました。\nまだ余裕ありそうです",
                    likes: 3
                )
                MeguriReplyRow(
                    avatar: "twice_penlight",
                    name: "haru",
                    time: "6分前",
                    bodyText: "整理券の確認だけ\n先に見られました",
                    likes: 2
                )
                MeguriReplyRow(
                    avatar: "twice_dahyun_1",
                    name: "saku",
                    time: "8分前",
                    bodyText: "いま動き早いです。\n飲み物あると安心かも",
                    likes: 4
                )
                MeguriMineReply()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxHeight: 684, alignment: .top)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(MeguriDesignColors.border, lineWidth: 1)
        }
    }
}

private struct MeguriReplyRow: View {
    var avatar: String
    var name: String
    var time: String
    var bodyText: String
    var likes: Int

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MeguriImageCircle(imageName: avatar, size: 36)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(name)
                        .font(.system(size: 13.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(time)
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Text(bodyText)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(MeguriDesignColors.border, lineWidth: 1)
                    }

                HStack(spacing: 5) {
                    Image(systemName: "heart")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                    Text("\(likes)")
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 10)
                .frame(height: 20)
                .background(.white.opacity(0.92), in: Capsule())
                .overlay(Capsule().strokeBorder(MeguriDesignColors.border, lineWidth: 1))
            }
        }
    }
}

private struct MeguriMineReply: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("あなた")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                    Text("たった今")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Text("ありがとうございます、向かいます！")
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(.white.opacity(0.76), in: Capsule())
                    .overlay(Capsule().strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1))
            }
            .padding(9)
            .frame(width: 268)
            .background(MeguriDesignColors.lavenderPale, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle")
                Text("たった今")
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private struct MeguriReplyInputBar: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "photo")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
            Image(systemName: "camera")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            Text("この話題に返信する")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 40)
                .background(.white.opacity(0.94), in: Capsule())
                .overlay(Capsule().strokeBorder(MeguriDesignColors.border, lineWidth: 1))

            Image(systemName: "paperplane.fill")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(MegrumTheme.lavender, in: Circle())
                .shadow(color: MegrumTheme.lavender.opacity(0.34), radius: 12, y: 6)
        }
        .foregroundStyle(MegrumTheme.lavender)
        .padding(.horizontal, 20)
        .frame(height: 68)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .shadow(color: MeguriDesignColors.shadow, radius: 18, y: -5)
    }
}

private struct MeguriAvatarStack: View {
    var imageNames: [String]
    var size: CGFloat
    var overlap: CGFloat = -6

    var body: some View {
        HStack(spacing: overlap) {
            ForEach(imageNames.prefix(5), id: \.self) { imageName in
                MeguriImageCircle(imageName: imageName, size: size)
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
            }
        }
    }
}

private struct MeguriImageCircle: View {
    var imageName: String
    var size: CGFloat

    var body: some View {
        MeguriDesignImage(imageName: imageName)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .background(MeguriDesignColors.lavenderSoft, in: Circle())
    }
}

private struct MeguriRoundedImage: View {
    var imageName: String
    var size: CGFloat
    var radius: CGFloat

    var body: some View {
        MeguriDesignImage(imageName: imageName)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .background(MeguriDesignColors.lavenderSoft, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

private struct MeguriDesignImage: View {
    var imageName: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MegrumTheme.lavender.opacity(0.24), MegrumTheme.sky.opacity(0.22), MegrumTheme.pink.opacity(0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            imageLayer
        }
        .clipped()
    }

    private var imageURL: URL? {
        Bundle.module.url(forResource: imageName, withExtension: "png", subdirectory: "TestGoodsImages")
            ?? Bundle.module.url(forResource: imageName, withExtension: "jpg", subdirectory: "TestGoodsImages")
            ?? URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/TestGoodsImages/\(imageName).png")
    }

    @ViewBuilder
    private var imageLayer: some View {
        #if canImport(UIKit)
        if let imageURL,
           let data = try? Data(contentsOf: imageURL),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        }
        #endif
    }
}

#Preview("めぐりホーム") {
    MeguriHomeDesignPreview(sheetMode: .normal)
}

#Preview("めぐりホーム 下タブ引き上げ") {
    MeguriHomeDesignPreview(sheetMode: .expanded)
}

#Preview("めぐり 掲示板詳細") {
    MeguriBoardDetailDesignPreview()
}
#endif
