import Foundation
import MegrumDesign
import SwiftUI

struct ListingGoodsImage: View {
    var url: URL?
    var title: String
    var cornerRadius: CGFloat = 24

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.16))
            .overlay {
                if let url {
                    AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
                        switch phase {
                        case let .success(image):
                            GeometryReader { proxy in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: proxy.size.width, height: proxy.size.height)
                                    .clipped()
                            }
                        case .failure:
                            ListingGoodsFallback(title: title)
                        default:
                            ProgressView()
                                .tint(MegrumTheme.lavender)
                        }
                    }
                } else {
                    ListingGoodsFallback(title: title)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.82), lineWidth: 2)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.14), radius: 18, y: 10)
    }
}

private struct ListingGoodsFallback: View {
    var title: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MegrumTheme.lavender.opacity(0.75), MegrumTheme.sky.opacity(0.66), MegrumTheme.pink.opacity(0.58)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(title.first.map(String.init) ?? "M")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}
