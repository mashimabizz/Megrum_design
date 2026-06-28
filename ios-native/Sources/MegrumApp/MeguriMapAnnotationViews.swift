import MapKit
import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomMapPin: View {
    var groom: GroomPost
    var isOutOfRange: Bool

    var body: some View {
        VStack(spacing: 0) {
            GroomThumbnailCircle(url: groom.imageURL, size: 58)
                .overlay(Circle().stroke(.white, lineWidth: 3))
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

            Triangle()
                .fill(.white)
                .frame(width: 14, height: 8)
                .offset(y: -1)
        }
        .accessibilityLabel(isOutOfRange ? "1km圏外のグルーム" : "グルーム")
    }
}

struct BoardMapPin: View {
    var thread: BoardThread
    var isOutOfRange: Bool = false

    var body: some View {
        Text(thread.title)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(isOutOfRange ? MegrumTheme.muted.opacity(0.78) : MegrumTheme.lavender, in: Capsule())
            .overlay(alignment: .bottom) {
                Triangle()
                    .fill(isOutOfRange ? MegrumTheme.muted.opacity(0.78) : MegrumTheme.lavender)
                    .frame(width: 14, height: 8)
                    .offset(y: 6)
            }
            .overlay(alignment: .topTrailing) {
                if isOutOfRange {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(width: 19, height: 19)
                        .background(.regularMaterial, in: Circle())
                        .offset(x: 5, y: -7)
                }
            }
            .shadow(color: MegrumTheme.ink.opacity(0.2), radius: 12, y: 7)
            .saturation(isOutOfRange ? 0.35 : 1)
            .opacity(isOutOfRange ? 0.72 : 1)
            .accessibilityLabel(isOutOfRange ? "1km圏外のチャットルーム \(thread.title)" : "チャットルーム \(thread.title)")
    }
}

struct GroomClusterMapPin: View {
    var count: Int

    var body: some View {
        VStack(spacing: 0) {
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
                    .background(MegrumTheme.pink, in: Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: 8, y: -8)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 12, y: 8)

            Triangle()
                .fill(.white)
                .frame(width: 14, height: 8)
                .offset(y: -1)
        }
        .accessibilityLabel("\(count)件のグルーム")
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

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
