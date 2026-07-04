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

    var body: some View {
        GroomThumbnailCircle(url: groom.imageURL, size: 58)
            .overlay(Circle().stroke(megrumPinBorderGradient, lineWidth: 3))
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
            .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 12, y: 8)
            .saturation(isOutOfRange ? 0.25 : 1)
            .opacity(isOutOfRange ? 0.68 : 1)
            .accessibilityLabel(isOutOfRange ? "1km圏外のグルーム" : "グルーム")
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
            GroomMapPin(groom: groom, isOutOfRange: false)
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

