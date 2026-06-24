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
            .accessibilityLabel(isOutOfRange ? "1km圏外の掲示板 \(thread.title)" : "掲示板 \(thread.title)")
    }
}

struct GroomMapDetailSheet: View {
    var groom: GroomPost

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("グルーム")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            AsyncImage(url: groom.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.86))
                        .overlay {
                            GroomImageFailureView(message: "画像を読み込めませんでした", foregroundColor: MegrumTheme.ink)
                        }
                default:
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [MegrumTheme.sky, MegrumTheme.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            ProgressView()
                                .tint(.white)
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .padding(20)
        .background(MegrumTheme.canvas)
    }
}

struct GroomThumbnailCircle: View {
    var url: URL
    var size: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                GroomImageFailureView(message: nil, foregroundColor: .white)
            default:
                ProgressView()
                    .tint(.white)
            }
        }
        .frame(width: size, height: size)
        .background(
            LinearGradient(
                colors: [MegrumTheme.sky, MegrumTheme.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Circle())
        .contentShape(Circle())
    }
}

struct GroomImageFailureView: View {
    var message: String?
    var foregroundColor: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo")
                .font(.system(size: message == nil ? 20 : 30, weight: .bold))

            if let message {
                Text(message)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundStyle(foregroundColor.opacity(0.78))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
