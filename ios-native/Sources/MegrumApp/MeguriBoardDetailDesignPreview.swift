import MegrumDesign
import SwiftUI

#if DEBUG
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

#Preview("めぐり チャットルーム詳細") {
    MeguriBoardDetailDesignPreview()
}
#endif
