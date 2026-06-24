import Foundation
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if DEBUG
struct MeguriReplyRow: View {
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

struct MeguriMineReply: View {
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

struct MeguriReplyInputBar: View {
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

struct MeguriAvatarStack: View {
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

struct MeguriImageCircle: View {
    var imageName: String
    var size: CGFloat

    var body: some View {
        MeguriDesignImage(imageName: imageName)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .background(MeguriDesignColors.lavenderSoft, in: Circle())
    }
}

struct MeguriRoundedImage: View {
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

struct MeguriDesignImage: View {
    var imageName: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    MegrumTheme.lavender.opacity(0.24),
                    MegrumTheme.sky.opacity(0.22),
                    MegrumTheme.pink.opacity(0.20)
                ],
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
#endif
