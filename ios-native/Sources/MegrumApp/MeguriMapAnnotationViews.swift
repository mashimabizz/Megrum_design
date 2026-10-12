import MapKit
import MegrumCore
import MegrumDesign
import SwiftUI

/// マップピン枠線用のブランドグラデーション（Megrumアイコンと同系）。
private var megrumPinBorderGradient: LinearGradient {
    LinearGradient(
        colors: [MegrumTheme.sky, MegrumTheme.lavender, MegrumTheme.pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// マーカーを不規則な周期でふわふわ上下＋やわらかく伸び縮みさせる共通
/// ラッパー。周期・振幅・開始タイミングは seed から決めるため、マーカー
/// ごとにズレて有機的に見える。
struct MeguriFloatingMotion<Content: View>: View {
    var seed: Int
    @ViewBuilder var content: Content

    @State private var isFloating = false
    @State private var isStretching = false

    private var amplitude: CGFloat {
        4.2 + CGFloat(abs(seed) % 5) * 0.9
    }

    private var duration: Double {
        1.7 + Double(abs(seed) % 9) * 0.2
    }

    private var delay: Double {
        Double(abs(seed) % 13) * 0.145
    }

    /// 伸び縮みの強さ（縦に伸びる⇄横に伸びる）。
    private var stretch: CGFloat {
        0.045 + CGFloat(abs(seed) % 4) * 0.012
    }

    /// 上下動と周期をずらして、単調に見えないようにする。
    private var stretchDuration: Double {
        1.3 + Double(abs(seed / 7) % 7) * 0.19
    }

    var body: some View {
        content
            .scaleEffect(
                x: isStretching ? 1 - stretch : 1 + stretch,
                y: isStretching ? 1 + stretch : 1 - stretch
            )
            .offset(y: isFloating ? -amplitude : amplitude)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    isFloating = true
                }
                withAnimation(
                    .easeInOut(duration: stretchDuration)
                    .repeatForever(autoreverses: true)
                    .delay(delay * 0.6)
                ) {
                    isStretching = true
                }
            }
    }
}

/// 統合・分解でマーカーが現れる時の、ぽよんと弾むポップイン。
struct MeguriPinPopIn<Content: View>: View {
    @ViewBuilder var content: Content

    @State private var isShown = false

    var body: some View {
        content
            .scaleEffect(isShown ? 1 : 0.28)
            .opacity(isShown ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.58)) {
                    isShown = true
                }
            }
    }
}

struct GroomMapPin: View {
    var groom: GroomPost
    var isOutOfRange: Bool
    /// iter1226.444：既読グルームはレール（ホーム）と同じくグレー枠にする。
    var isRead: Bool = false

    var body: some View {
        GroomThumbnailCircle(url: groom.imageURL, size: 58)
            .overlay {
                if isRead {
                    Circle().stroke(GroomStoryMetrics.seenRing, lineWidth: 3)
                } else {
                    Circle().stroke(megrumPinBorderGradient, lineWidth: 3)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isOutOfRange {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(width: 21, height: 21)
                        .background(.regularMaterial, in: Circle())
                        .offset(x: 3, y: 3)
                }
            }
            .overlay(alignment: .top) {
                // いいねが1件以上ついたグルームは、アイコンから小さなハートが
                // 途切れず湧き上がり続ける。
                if !isOutOfRange, groom.likeCount >= 1 {
                    GroomPinAmbientHearts(
                        seed: groom.id.hashValue,
                        likeCount: groom.likeCount
                    )
                }
            }
            .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 12, y: 8)
            .saturation(isOutOfRange ? 0.25 : 1)
            .opacity(isOutOfRange ? 0.68 : 1)
            .accessibilityLabel(isOutOfRange ? "1km圏外のグルーム" : "グルーム")
    }
}

/// いいね付きグルームのピンから小さなハートが湧き続けるアンビエント演出。
/// いいね数が多いほどハートが少し増える。決定的シードで配置（再描画で揺れない）。
struct GroomPinAmbientHearts: View {
    var seed: Int
    var likeCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var heartCount: Int {
        min(4 + likeCount / 2, 9)
    }

    var body: some View {
        if reduceMotion {
            EmptyView()
        } else {
            ZStack {
                ForEach(0..<heartCount, id: \.self) { index in
                    GroomPinAmbientHeart(seed: seed &+ index &* 7919)
                }
            }
            .frame(width: 58, height: 10)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

private struct GroomPinAmbientHeart: View {
    var seed: Int

    @State private var isRising = false

    private var unit: (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat) {
        // seed から 0..<1 の擬似乱数を複数取り出す（決定的）。
        func value(_ salt: UInt64) -> CGFloat {
            var state = UInt64(bitPattern: Int64(seed)) &+ salt &* 0x9E3779B97F4A7C15
            state ^= state >> 30
            state = state &* 0xBF58476D1CE4E5B9
            state ^= state >> 27
            return CGFloat(state % 1000) / 1000
        }
        return (value(1), value(2), value(3), value(4), value(5))
    }

    var body: some View {
        let (u1, u2, u3, u4, u5) = unit
        let startX = -20 + u1 * 40
        let drift = -8 + u2 * 16
        let size = 9 + u3 * 4
        let duration = 1.8 + Double(u4) * 1.2
        let delay = Double(u5) * 1.6

        Image(systemName: "heart.fill")
            .font(.system(size: size, weight: .bold))
            // グルーム内のいいね（赤）と同じ色に揃える
            .foregroundStyle(Color.red.opacity(0.88))
            .shadow(color: .white.opacity(0.8), radius: 1)
            .scaleEffect(isRising ? 1.15 : 0.5)
            // easeIn：ピンの近くでゆっくり漂ってから昇るので、
            // 濃い状態が長く続き視認しやすい。
            .opacity(isRising ? 0 : 1)
            .offset(
                x: startX + (isRising ? drift : 0),
                y: isRising ? -48 : -4
            )
            .onAppear {
                withAnimation(
                    .easeIn(duration: duration)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    isRising = true
                }
            }
    }
}

/// チャットルームのピン。グルーム（丸）との差別化として四角のアイコン。
/// 名前は Annotation のラベル（マーカー下）で表示する。
struct BoardMapPin: View {
    var thread: BoardThread
    var isOutOfRange: Bool = false

    var body: some View {
        BoardMapPinThumbnail(url: thread.thumbnailURL, isOutOfRange: isOutOfRange)
            .overlay(alignment: .bottomTrailing) {
                if isOutOfRange {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(width: 21, height: 21)
                        .background(.regularMaterial, in: Circle())
                        .offset(x: 4, y: 4)
                }
            }
            .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 12, y: 8)
            .saturation(isOutOfRange ? 0.35 : 1)
            .opacity(isOutOfRange ? 0.72 : 1)
            .accessibilityLabel(isOutOfRange ? "1km圏外のチャットルーム \(thread.title)" : "チャットルーム \(thread.title)")
    }
}

struct BoardMapPinWithTitle: View {
    var thread: BoardThread
    var isOutOfRange: Bool = false

    var body: some View {
        VStack(spacing: 3) {
            BoardMapPin(thread: thread, isOutOfRange: isOutOfRange)

            // 吹き出しと見た目が紛れないよう、名称は背景枠なしの文字のみ。
            // 地図上でも読めるように白の細いふちどり（影）だけ付ける。
            Text(thread.title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .shadow(color: .white.opacity(0.9), radius: 1.5)
                .shadow(color: .white.opacity(0.9), radius: 1.5)
                .frame(maxWidth: 118)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isOutOfRange ? "1km圏外のチャットルーム \(thread.title)" : "チャットルーム \(thread.title)")
    }
}

private struct BoardMapPinThumbnail: View {
    var url: URL?
    var isOutOfRange: Bool

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url, transaction: Transaction(animation: .smooth(duration: 0.18))) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        placeholder
                            .redacted(reason: .placeholder)
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 54, height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(megrumPinBorderGradient, lineWidth: 3)
        }
        .saturation(isOutOfRange ? 0.35 : 1)
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [MegrumTheme.sky, MegrumTheme.lavender, MegrumTheme.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 3, y: 1)
        }
    }
}

/// 統合クラスタのピン：統合前の任意のマーカー（先頭の代表）をそのまま
/// アイコンに採用し、右上に青バッジで合計数を出す。
struct MeguriClusterPin: View {
    var cluster: MeguriMapClusterBuilder.Cluster
    /// iter1226.444：既読判定（クラスタ内の全グルームが既読なら代表ピンをグレー枠に）。
    var viewedGroomIDs: Set<UUID> = []

    private var allGroomsRead: Bool {
        let groomIDs = cluster.items.compactMap { item -> UUID? in
            if case .groom(let groom) = item {
                return groom.id
            }
            return nil
        }
        guard !groomIDs.isEmpty else {
            return false
        }
        return groomIDs.allSatisfy { viewedGroomIDs.contains($0) }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            representativeIcon

            Text("\(cluster.count)")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 22, minHeight: 22)
                .background(Color.blue, in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .offset(x: 8, y: -8)
        }
        .accessibilityLabel("\(cluster.count)件のグルーム・チャットルーム")
    }

    @ViewBuilder
    private var representativeIcon: some View {
        switch cluster.representative {
        case .groom(let groom):
            GroomMapPin(groom: groom, isOutOfRange: false, isRead: allGroomsRead)
        case .thread(let thread):
            BoardMapPin(thread: thread)
        case nil:
            GroomClusterMapPin(count: cluster.count)
        }
    }
}

struct GroomClusterMapPin: View {
    var count: Int
    var accessibilityText: String?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text("Mg")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 58, height: 48)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white, lineWidth: 3)
                }

            Text("\(count)")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 22, minHeight: 22)
                .background(Color.blue, in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .offset(x: 8, y: -8)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 12, y: 8)
        .accessibilityLabel(accessibilityText ?? "\(count)件のグルーム")
    }
}

struct BoardMapAnnotation: Identifiable {
    var thread: BoardThread
    var coordinate: CLLocationCoordinate2D

    var id: UUID { thread.id }

    init?(thread: BoardThread) {
        guard let latitude = thread.latitude, let longitude = thread.longitude else {
            return nil
        }
        self.thread = thread
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct GroomMapCluster: Identifiable {
    var id: String
    var posts: [GroomPost]
    var coordinate: CLLocationCoordinate2D

    var title: String {
        posts.count > 1 ? "\(posts.count)件のグルーム" : ""
    }

    static func clusters(from posts: [GroomPost], cellDegrees: Double = 0.0024) -> [GroomMapCluster] {
        let grouped = Dictionary(grouping: posts) { post in
            let lat = Int((post.latitude / cellDegrees).rounded())
            let lng = Int((post.longitude / cellDegrees).rounded())
            return "\(lat):\(lng)"
        }
        return grouped.map { key, groupedPosts in
            let latitude = groupedPosts.map(\.latitude).reduce(0, +) / Double(groupedPosts.count)
            let longitude = groupedPosts.map(\.longitude).reduce(0, +) / Double(groupedPosts.count)
            let id = groupedPosts.count == 1 ? groupedPosts[0].id.uuidString : key
            return GroomMapCluster(
                id: id,
                posts: groupedPosts.sorted { $0.createdAt > $1.createdAt },
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            )
        }
        .sorted { lhs, rhs in
            if lhs.posts.count == rhs.posts.count {
                return lhs.id < rhs.id
            }
            return lhs.posts.count > rhs.posts.count
        }
    }
}

/// ズームアウト時の「おおよその件数」バブル（iter1226.434）。
/// 実データを読み込む前に、この付近にどれくらいあるかだけを伝える。
struct MeguriDensityBubble: View {
    var cell: MeguriMapDensityCell

    var body: some View {
        HStack(spacing: 8) {
            if cell.groomCount > 0 {
                MeguriDensityCountLabel(
                    systemImage: "camera.fill",
                    count: cell.groomCount,
                    tint: MegrumTheme.lavender
                )
            }
            if cell.threadCount > 0 {
                MeguriDensityCountLabel(
                    systemImage: "text.bubble.fill",
                    count: cell.threadCount,
                    tint: MegrumTheme.sky
                )
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(MegrumTheme.lavender.opacity(0.45), lineWidth: 1.2)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.18), radius: 9, y: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("この付近にグルーム\(cell.groomCount)件、チャットルーム\(cell.threadCount)件。タップで拡大")
    }
}

private struct MeguriDensityCountLabel: View {
    var systemImage: String
    var count: Int
    var tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(tint)
            Text("\(count)")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(MegrumTheme.ink)
        }
    }
}
