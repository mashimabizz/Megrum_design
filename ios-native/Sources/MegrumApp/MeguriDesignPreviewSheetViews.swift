import MegrumDesign
import SwiftUI

#if DEBUG
struct MeguriConversationSheet: View {
    var mode: MeguriHomeSheetMode

    private var topics: [MeguriDesignTopic] {
        switch mode {
        case .normal:
            Array(MeguriDesignTopic.samples.prefix(3))
        case .expanded:
            MeguriDesignTopic.samples
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(MegrumTheme.muted.opacity(0.38))
                .frame(width: 38, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 18)

            HStack(alignment: .top) {
                Text("今この場で話されていること")
                    .font(.system(size: mode == .normal ? 19 : 18, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)

                Spacer()

                HStack(spacing: 20) {
                    MeguriSheetAction(systemName: "camera", title: "グルーム")
                    MeguriSheetAction(systemName: "pencil", title: "話題")
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(Array(topics.enumerated()), id: \.element.id) { index, topic in
                    if index > 0 {
                        Divider()
                            .background(MeguriDesignColors.border)
                            .padding(.leading, mode == .normal ? 20 : 16)
                    }

                    if mode == .normal {
                        MeguriTopicRow(topic: topic)
                            .padding(.horizontal, 20)
                    } else {
                        MeguriExpandedTopicRow(topic: topic)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 16)

            Spacer(minLength: 0)
        }
        .background(
            RoundedRectangle(cornerRadius: MeguriDesignMetrics.sheetCornerRadius, style: .continuous)
                .fill(MeguriDesignColors.panel)
                .shadow(color: MeguriDesignColors.shadow, radius: 22, y: -8)
        )
    }
}

struct MeguriSheetAction: View {
    var systemName: String
    var title: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.96), in: Circle())
                .overlay(Circle().stroke(MegrumTheme.ink.opacity(0.07), lineWidth: 1))
                .shadow(color: MeguriDesignColors.shadow, radius: 10, y: 5)

            Text(title)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
    }
}

struct MeguriTopicRow: View {
    var topic: MeguriDesignTopic

    var body: some View {
        HStack(spacing: 14) {
            MeguriRoundedImage(imageName: topic.imageName, size: MeguriDesignMetrics.listImageSize, radius: 12)

            VStack(alignment: .leading, spacing: 6) {
                Text(topic.title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)

                Text(topic.excerpt)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.76))
                    .lineLimit(2)
                    .lineSpacing(2)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 9) {
                MeguriAvatarStack(imageNames: topic.avatars, size: 21)

                HStack(spacing: 6) {
                    Image(systemName: "bubble")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    Text("\(topic.replyCount)")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(MegrumTheme.ink.opacity(0.65))

                Text(topic.tag)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 10)
                    .frame(height: 23)
                    .background(MeguriDesignColors.lavenderPale, in: Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
        .frame(height: 96)
    }
}

struct MeguriExpandedTopicRow: View {
    var topic: MeguriDesignTopic

    var body: some View {
        HStack(spacing: 14) {
            MeguriRoundedImage(imageName: topic.imageName, size: MeguriDesignMetrics.expandedListImageSize, radius: 12)

            VStack(alignment: .leading, spacing: 7) {
                Text(topic.title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)

                Text(topic.excerpt)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.76))
                    .lineLimit(2)
                    .lineSpacing(2)

                MeguriAvatarStack(imageNames: topic.avatars, size: 20)
            }

            Spacer(minLength: 6)

            HStack(spacing: 7) {
                Image(systemName: "bubble")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                Text("\(topic.replyCount)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(MegrumTheme.ink.opacity(0.68))
            .frame(width: 64, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.84))
        }
        .frame(height: 78)
    }
}
#endif
