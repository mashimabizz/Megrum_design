import MegrumCore
import MegrumDesign
import SwiftUI

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
