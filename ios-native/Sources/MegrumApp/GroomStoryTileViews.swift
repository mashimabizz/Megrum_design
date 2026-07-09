import MegrumCore
import MegrumDesign
import SwiftUI

/// FB(iter1226.389)：ホーム上部のグルーム列は Instagram のストーリー列と同寸・同色に合わせる。
/// グラデーションの色だけは Megrum の水色→紫のまま（オーナー指定）。
enum GroomStoryMetrics {
    /// 外枠（リング）直径。IG ストーリーは約64pt。
    static let ringDiameter: CGFloat = 64
    /// リングの線幅。IG は細い（約2pt）。
    static let ringLineWidth: CGFloat = 2
    /// 内側アバター直径。リングとの間に約2ptの余白ができる。
    static let avatarDiameter: CGFloat = 56
    /// ラベル幅（1行・省略）。
    static let labelWidth: CGFloat = 66
    /// タイル間の余白。
    static let itemSpacing: CGFloat = 12
    /// アバターとラベルの縦間隔。
    static let labelSpacing: CGFloat = 6

    /// 既読／自分のストーリーの薄いグレー枠（IG の #C7C7C7）。
    static let seenRing = Color(red: 0.78, green: 0.78, blue: 0.78)
    /// 追加バッジの青（IG のアクションブルー #0095F6）。
    static let addBadgeBlue = Color(red: 0.0, green: 0.584, blue: 0.965)
    /// 未読ラベル色（IG の #262626）。
    static let labelUnseen = Color(red: 0.149, green: 0.149, blue: 0.149)
    /// 既読ラベル色（IG の #8E8E8E）。
    static let labelSeen = Color(red: 0.557, green: 0.557, blue: 0.557)

    /// 未読リングのグラデ（色は現状どおり 水色→紫）。
    static let unseenGradient = LinearGradient(
        colors: [MegrumTheme.sky, MegrumTheme.lavender],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct GroomMyStoryTile: View {
    var viewer: UserProfile?
    var isLoading: Bool
    var onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            VStack(spacing: GroomStoryMetrics.labelSpacing) {
                GroomMyStoryAvatar(viewer: viewer, isLoading: isLoading)
                    .frame(width: GroomStoryMetrics.ringDiameter, height: GroomStoryMetrics.ringDiameter)

                Text("グルーム")
                    .font(.system(size: 11))
                    .foregroundStyle(GroomStoryMetrics.labelUnseen)
                    .lineLimit(1)
                    .frame(width: GroomStoryMetrics.labelWidth)
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel("グルームを追加")
    }
}

private enum GroomMyStoryRingPhase {
    case idle
    case uploading
    case celebrating
}

private struct GroomMyStoryAvatar: View {
    var viewer: UserProfile?
    var isLoading: Bool

    @State private var phase: GroomMyStoryRingPhase = .idle
    @State private var spin: Double = 0
    @State private var sweep: CGFloat = 0
    @State private var pop: CGFloat = 1

    private var fallbackText: String {
        viewer?.displayName.nilIfBlank ?? viewer?.handle.nilIfBlank ?? "Me"
    }

    var body: some View {
        ZStack {
            ring
                .scaleEffect(pop)

            GroomAvatarCircle(
                avatarURL: viewer?.avatarURL,
                fallbackText: fallbackText,
                size: GroomStoryMetrics.avatarDiameter,
                backgroundOpacity: 0.92
            )
            .scaleEffect(pop)
        }
        .frame(width: GroomStoryMetrics.ringDiameter, height: GroomStoryMetrics.ringDiameter)
        // ＋バッジだけ右下に重ねる（リングとアバターは中央合わせのままにする）。
        .overlay(alignment: .bottomTrailing) {
            if phase == .idle {
                addBadge
            }
        }
        .onAppear {
            if isLoading { startUploading() }
        }
        .onChange(of: isLoading) { wasLoading, nowLoading in
            if nowLoading {
                startUploading()
            } else if wasLoading {
                celebrate()
            }
        }
    }

    @ViewBuilder
    private var ring: some View {
        switch phase {
        case .idle:
            Circle()
                .strokeBorder(GroomStoryMetrics.seenRing, lineWidth: GroomStoryMetrics.ringLineWidth)
                .frame(width: GroomStoryMetrics.ringDiameter, height: GroomStoryMetrics.ringDiameter)
        case .uploading:
            // アップロード中：色を控えめにした短い弧が時計回りに回り続ける（IG のスピナー相当）。
            Circle()
                .trim(from: 0, to: 0.28)
                .stroke(
                    GroomStoryMetrics.unseenGradient,
                    style: StrokeStyle(lineWidth: GroomStoryMetrics.ringLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(spin - 90))
                .frame(width: GroomStoryMetrics.ringDiameter - 2, height: GroomStoryMetrics.ringDiameter - 2)
                .opacity(0.6)
        case .celebrating:
            // 完成の瞬間：上（12時）から時計回りにグラデが一周描かれ「色づく」。
            Circle()
                .trim(from: 0, to: sweep)
                .stroke(
                    GroomStoryMetrics.unseenGradient,
                    style: StrokeStyle(lineWidth: GroomStoryMetrics.ringLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: GroomStoryMetrics.ringDiameter - 2, height: GroomStoryMetrics.ringDiameter - 2)
        }
    }

    private var addBadge: some View {
        Image(systemName: "plus")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(GroomStoryMetrics.addBadgeBlue, in: Circle())
            .overlay {
                Circle().stroke(MegrumTheme.canvas, lineWidth: 2)
            }
            .offset(x: 2, y: 2)
    }

    private func startUploading() {
        pop = 1
        sweep = 0
        spin = 0
        phase = .uploading
        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
            spin = 360
        }
    }

    private func celebrate() {
        phase = .celebrating
        sweep = 0
        pop = 1
        withAnimation(.easeOut(duration: 0.42)) {
            sweep = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            pop = 1.06
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 520_000_000)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                pop = 1
            }
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation(.easeInOut(duration: 0.5)) {
                phase = .idle
                sweep = 0
            }
        }
    }
}

struct GroomStoryTile: View {
    var groom: GroomPost
    var profile: UserProfile?
    var isRead: Bool
    /// FB(iter1226.392)：無料会員で圏外の遭遇済みグルーム＝いま開けない。うすい鍵アイコンを右下に付ける。
    var isLocked: Bool = false

    private var displayName: String {
        profile?.handle.nilIfBlank ?? profile?.displayName.nilIfBlank ?? "めぐり"
    }

    private var fallbackText: String {
        profile?.displayName.nilIfBlank ?? profile?.handle.nilIfBlank ?? "?"
    }

    var body: some View {
        VStack(spacing: GroomStoryMetrics.labelSpacing) {
            ZStack {
                GroomStoryRing(isRead: isRead)
                GroomAvatarCircle(
                    avatarURL: profile?.avatarURL,
                    fallbackText: fallbackText,
                    size: GroomStoryMetrics.avatarDiameter,
                    backgroundOpacity: 0.94
                )
                .opacity(isLocked ? 0.82 : 1)
            }
            .frame(width: GroomStoryMetrics.ringDiameter, height: GroomStoryMetrics.ringDiameter)
            .overlay(alignment: .bottomTrailing) {
                if isLocked {
                    lockBadge
                }
            }

            Text(displayName)
                .font(.system(size: 11))
                .foregroundStyle(isRead ? GroomStoryMetrics.labelSeen : GroomStoryMetrics.labelUnseen)
                .lineLimit(1)
                .frame(width: GroomStoryMetrics.labelWidth)
        }
    }

    /// うすい鍵アイコン（右下）。プレミアム限定で開けることを示す。
    private var lockBadge: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(MegrumTheme.ink.opacity(0.55), in: Circle())
            .overlay {
                Circle().stroke(MegrumTheme.canvas, lineWidth: 1.5)
            }
            .offset(x: 2, y: 2)
    }
}

private struct GroomStoryRing: View {
    var isRead: Bool

    var body: some View {
        Group {
            if isRead {
                Circle()
                    .strokeBorder(GroomStoryMetrics.seenRing, lineWidth: GroomStoryMetrics.ringLineWidth)
            } else {
                // 未読は水色→紫のブランドグラデ（色は現状どおり／IGと同寸の細枠）。
                Circle()
                    .strokeBorder(GroomStoryMetrics.unseenGradient, lineWidth: GroomStoryMetrics.ringLineWidth)
            }
        }
        .frame(width: GroomStoryMetrics.ringDiameter, height: GroomStoryMetrics.ringDiameter)
    }
}

private struct GroomAvatarCircle: View {
    var avatarURL: URL?
    var fallbackText: String
    var size: CGFloat
    var backgroundOpacity: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            MegrumTheme.lavender.opacity(backgroundOpacity),
                            MegrumTheme.sky.opacity(backgroundOpacity)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        fallbackAvatar
                    }
                }
            } else {
                fallbackAvatar
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .contentShape(Circle())
    }

    private var fallbackAvatar: some View {
        Text(String(fallbackText.prefix(1)).uppercased())
            .font(.system(size: size * 0.36, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .white.opacity(0.4), radius: 6)
    }
}

struct GroomEmptyStoryHint: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("近くのグルームはまだありません")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(2)

            Text("追加すると、近くの人にだけ届きます。")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .frame(width: 178, height: GroomStoryMetrics.ringDiameter, alignment: .leading)
        .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(0.12), lineWidth: 1)
        }
    }
}
