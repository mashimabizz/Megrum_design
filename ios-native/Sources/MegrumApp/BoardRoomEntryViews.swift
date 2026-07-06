import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

/// 他の人のチャットルームに入る時のフェーズ。
/// 紹介 → ルーム用プロフィール設定（既存シート） → 注意事項の確認 → 入室。
enum BoardRoomEntryPhase: Equatable {
    case undetermined
    case intro
    case notice
    case entered
}

/// 入室前の紹介画面（LINEオープンチャットの参加画面に相当・Megrumトーン）。
/// ルーム画像・名前・参加人数・説明を見せて「新しいプロフィールで参加」へ誘導する。
struct BoardRoomEntryIntroView: View {
    var thread: BoardThread
    var participantCount: Int
    var onJoin: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    MegrumHaptics.performButtonTap(onClose)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.9), in: Circle())
                        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("閉じる")

                Spacer()

                Text("チャットルーム")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Spacer()

                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            ScrollView {
                VStack(spacing: 18) {
                    roomImage
                        .padding(.top, 18)

                    VStack(spacing: 8) {
                        Text(thread.title)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .multilineTextAlignment(.center)

                        Text("参加者 \(max(participantCount, 1))人")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    if !thread.body.isBlank {
                        Text(thread.body)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 30)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24)
            }

            VStack(spacing: 12) {
                Button {
                    MegrumHaptics.performButtonTap(onJoin)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 15, weight: .heavy))
                        Text("新しいプロフィールで参加")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [MegrumTheme.sky, MegrumTheme.lavender],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                .buttonStyle(.plain)

                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(MegrumTheme.conditionPossible)
                    Text("チャットを悪用した詐欺・勧誘にご注意ください。")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    @ViewBuilder
    private var roomImage: some View {
        Group {
            if let url = thread.thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(width: 168, height: 168)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [MegrumTheme.sky, MegrumTheme.lavender, MegrumTheme.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        }
        .shadow(color: MegrumTheme.lavender.opacity(0.3), radius: 18, y: 10)
    }

    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [MegrumTheme.sky.opacity(0.4), MegrumTheme.lavender.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 44, weight: .heavy))
                .foregroundStyle(.white)
        }
    }
}

/// 入室直後に1回だけ出す注意事項ポップアップ（確認して入室）。
struct BoardRoomEntryNoticeOverlay: View {
    var onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text("チャットルーム利用に関する注意事項")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)

                noticeItem(
                    title: "1. 投稿は運営が確認することがあります",
                    body: "公開範囲にかかわらず、すべての投稿はMegrum利用規約にもとづき、Megrum運営によって確認・対応されることがあります。"
                )
                noticeItem(
                    title: "2. 秘匿性の高い情報は投稿しないでください",
                    body: "投稿は参加中のメンバーに表示され、外部へ転載されるおそれがあります。住所や連絡先などの個人情報は投稿しないでください。"
                )
                noticeItem(
                    title: "3. 禁止事項を守って利用してください",
                    body: "出会い目的の行為、個人情報の投稿、誹謗中傷、わいせつな投稿などは、Megrumの利用規約・ガイドラインで禁止されています。"
                )

                Button {
                    MegrumHaptics.performButtonTap(onConfirm)
                } label: {
                    Text("確認しました")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 26)
            .shadow(color: .black.opacity(0.2), radius: 24, y: 12)
        }
        .transition(.opacity)
    }

    private func noticeItem(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text(body)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
