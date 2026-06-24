import MegrumCore
import MegrumDesign
import SwiftUI

enum MeguriBoardSheetDetent: Equatable {
    case compact
    case regular
    case expanded

    var isCompact: Bool {
        self == .compact
    }

    var usesExpandedRows: Bool {
        self == .expanded
    }

    func height(in viewportHeight: CGFloat) -> CGFloat {
        MeguriBoardSheetLayout.visibleHeight(for: self, in: viewportHeight)
    }

    func moved(up: Bool) -> Self {
        switch (self, up) {
        case (.compact, true):
            .regular
        case (.regular, true):
            .expanded
        case (.expanded, true):
            .expanded
        case (.expanded, false):
            .regular
        case (.regular, false):
            .compact
        case (.compact, false):
            .compact
        }
    }
}

enum MeguriBoardSheetLayout {
    static func expandedHeight(in viewportHeight: CGFloat) -> CGFloat {
        max(viewportHeight - 8, 1)
    }

    static func visibleHeight(for detent: MeguriBoardSheetDetent, in viewportHeight: CGFloat) -> CGFloat {
        let expanded = expandedHeight(in: viewportHeight)
        switch detent {
        case .compact:
            return min(max(viewportHeight * 0.20, 154), 166)
        case .regular:
            return min(max(viewportHeight * 0.48, 330), expanded)
        case .expanded:
            return expanded
        }
    }

    static func restingOffset(for detent: MeguriBoardSheetDetent, in viewportHeight: CGFloat) -> CGFloat {
        expandedHeight(in: viewportHeight) - visibleHeight(for: detent, in: viewportHeight)
    }

    static func interactiveOffset(
        for detent: MeguriBoardSheetDetent,
        in viewportHeight: CGFloat,
        dragTranslation: CGFloat
    ) -> CGFloat {
        let compactOffset = restingOffset(for: .compact, in: viewportHeight)
        let proposed = restingOffset(for: detent, in: viewportHeight) + dragTranslation
        return min(max(proposed, 0), compactOffset)
    }

    static func targetDetent(
        from detent: MeguriBoardSheetDetent,
        translation: CGFloat,
        predictedTranslation: CGFloat
    ) -> MeguriBoardSheetDetent {
        let movement = abs(predictedTranslation) > abs(translation) ? predictedTranslation : translation
        if movement < -36 {
            return .expanded
        }
        if movement > 36 {
            return .compact
        }
        return detent
    }
}

struct MeguriBoardBottomSheet: View {
    @Binding var detent: MeguriBoardSheetDetent
    var viewportHeight: CGFloat
    var threads: [BoardThread]
    var grooms: [GroomPost]
    var replyCounts: [UUID: Int]
    var isLoading: Bool
    var selectedScope: BoardThread.Audience
    var selectedPrefecture: String
    var onChangeScope: (BoardThread.Audience) -> Void
    var onOpenPrefecture: () -> Void
    var onOpenGroomComposer: () -> Void
    var onOpenThreadComposer: () -> Void
    var onOpenThread: (BoardThread) -> Void

    @GestureState private var dragTranslation: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MeguriBoardSheetGrabber()
                .gesture(sheetDragGesture)

            MeguriBoardSheetTopSurface(
                groomCount: grooms.count,
                threadCount: threads.count,
                onOpenGroomComposer: onOpenGroomComposer,
                onOpenThreadComposer: onOpenThreadComposer
            )

            VStack(alignment: .leading, spacing: 16) {
                MeguriBoardThreadListState(
                    threads: threads,
                    grooms: grooms,
                    replyCounts: replyCounts,
                    isLoading: isLoading,
                    onOpenThread: onOpenThread
                )
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
        .frame(height: MeguriBoardSheetLayout.expandedHeight(in: viewportHeight), alignment: .top)
        .background(.regularMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .stroke(MegrumTheme.lavender.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.10), radius: 18, y: -8)
        .offset(y: MeguriBoardSheetLayout.interactiveOffset(
            for: detent,
            in: viewportHeight,
            dragTranslation: dragTranslation
        ))
        .animation(.interactiveSpring(response: 0.32, dampingFraction: 0.88), value: detent)
        .ignoresSafeArea(edges: .bottom)
    }

    private var sheetDragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($dragTranslation) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                detent = MeguriBoardSheetLayout.targetDetent(
                    from: detent,
                    translation: value.translation.height,
                    predictedTranslation: value.predictedEndTranslation.height
                )
            }
    }
}

private struct MeguriBoardSheetGrabber: View {
    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .overlay(alignment: .top) {
                Capsule()
                    .fill(MegrumTheme.muted.opacity(0.38))
                    .frame(width: 38, height: 5)
                    .padding(.top, 12)
            }
            .contentShape(Rectangle())
            .accessibilityHidden(true)
    }
}

private struct MeguriBoardSheetTopSurface: View {
    var groomCount: Int
    var threadCount: Int
    var onOpenGroomComposer: () -> Void
    var onOpenThreadComposer: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            MeguriBoardQuickActionRow(
                title: "グルーム",
                subtitle: "\(groomCount)件の近くの投稿",
                systemImage: "camera",
                actionTitle: "投稿",
                action: onOpenGroomComposer
            )

            MeguriBoardQuickActionRow(
                title: "掲示板",
                subtitle: "\(threadCount)件の現地トピック",
                systemImage: "pencil",
                actionTitle: "作成",
                action: onOpenThreadComposer
            )
        }
    }
}

private struct MeguriBoardQuickActionRow: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .labelStyle(.titleAndIcon)

                Spacer(minLength: 8)

                Text(subtitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(actionTitle)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 12)
                    .frame(height: 28)
                    .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MeguriBoardThreadListState: View {
    var threads: [BoardThread]
    var grooms: [GroomPost]
    var replyCounts: [UUID: Int]
    var isLoading: Bool
    var onOpenThread: (BoardThread) -> Void

    var body: some View {
        if isLoading {
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
        } else if threads.isEmpty {
            MeguriInlineEmptyState(
                systemImage: "bubble.left.and.bubble.right",
                title: "近くの話題はまだありません",
                message: "会場の状況や聞きたいことを投稿できます。"
            )
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    ForEach(Array(threads.enumerated()), id: \.element.id) { index, thread in
                        Button {
                            onOpenThread(thread)
                        } label: {
                            MeguriThreadListRow(
                                thread: thread,
                                grooms: grooms,
                                replyCount: replyCounts[thread.id, default: 0],
                                index: index
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct MeguriThreadListRow: View {
    var thread: BoardThread
    var grooms: [GroomPost]
    var replyCount: Int
    var index: Int

    var body: some View {
        normalBody
    }

    private var normalBody: some View {
        HStack(spacing: 14) {
            MeguriThreadThumbnail(
                thread: thread,
                imageURL: thread.thumbnailURL ?? primaryGroom?.imageURL,
                size: 58
            )

            VStack(alignment: .leading, spacing: 7) {
                Text(thread.title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                Text(thread.body)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.72))
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                MeguriBoardAvatarStack(grooms: avatarGrooms, size: 20)

                HStack(spacing: 6) {
                    Image(systemName: "bubble")
                        .font(.system(size: 16, weight: .medium))
                    Text("\(replyCount)")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(MegrumTheme.ink.opacity(0.64))

                Text(thread.listTagTitle)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 12)
                    .frame(height: 23)
                    .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
            }

            Image(systemName: "chevron.forward")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(MegrumTheme.ink.opacity(0.72))
        }
        .frame(height: 96)
    }

    private var expandedBody: some View {
        HStack(spacing: 14) {
            MeguriThreadThumbnail(
                thread: thread,
                imageURL: thread.thumbnailURL ?? primaryGroom?.imageURL,
                size: 60
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(thread.title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                Text(thread.body)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.72))
                    .lineLimit(2)
                MeguriBoardAvatarStack(grooms: avatarGrooms, size: 20)
            }

            Spacer()

            HStack(spacing: 7) {
                Image(systemName: "bubble")
                    .font(.system(size: 18, weight: .medium))
                Text("\(replyCount)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .lineLimit(1)
            }
            .frame(width: 64, alignment: .leading)
            .foregroundStyle(MegrumTheme.ink.opacity(0.64))

            Image(systemName: "chevron.forward")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MegrumTheme.ink.opacity(0.72))
        }
        .frame(height: 78)
    }

    private var primaryGroom: GroomPost? {
        guard !grooms.isEmpty else { return nil }
        return grooms[index % grooms.count]
    }

    private var avatarGrooms: [GroomPost] {
        guard !grooms.isEmpty else { return [] }
        return (0..<min(3, grooms.count)).map { offset in
            grooms[(index + offset) % grooms.count]
        }
    }
}

private struct MeguriThreadThumbnail: View {
    var thread: BoardThread
    var imageURL: URL?
    var size: CGFloat

    var body: some View {
        if let imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    fallback
                default:
                    ProgressView()
                        .tint(MegrumTheme.lavender)
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            fallback
        }
    }

    private var fallback: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.14))
            .frame(width: size, height: size)
            .overlay {
                Text(thread.title.first.map(String.init) ?? "話")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
    }
}

private struct MeguriBoardAvatarStack: View {
    var grooms: [GroomPost]
    var size: CGFloat

    var body: some View {
        HStack(spacing: -5) {
            ForEach(grooms) { groom in
                GroomThumbnailCircle(url: groom.imageURL, size: size)
                    .overlay(Circle().stroke(.white, lineWidth: 1.4))
            }
            if grooms.isEmpty {
                Circle()
                    .fill(MegrumTheme.lavender.opacity(0.12))
                    .frame(width: size, height: size)
            }
        }
    }
}

private struct BoardScopeSelector: View {
    var selectedScope: BoardThread.Audience
    var prefectureTitle: String
    var onNearbyTap: () -> Void
    var onPrefectureTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onNearbyTap) {
                scopeChip(
                    title: "1km圏内",
                    systemImage: "location.fill",
                    isSelected: selectedScope == .nearby3km
                )
            }
            .buttonStyle(.plain)

            Button(action: onPrefectureTap) {
                scopeChip(
                    title: prefectureTitle,
                    systemImage: "map.fill",
                    isSelected: selectedScope == .samePrefecture
                )
            }
            .buttonStyle(.plain)
        }
        .accessibilityElement(children: .contain)
    }

    private func scopeChip(title: String, systemImage: String, isSelected: Bool) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
            .padding(.horizontal, 14)
            .frame(height: 42)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(isSelected ? .white.opacity(0.28) : MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: isSelected ? MegrumTheme.lavender.opacity(0.22) : MegrumTheme.ink.opacity(0.05), radius: 10, y: 5)
    }
}

private struct MeguriInlineEmptyState: View {
    var systemImage: String
    var title: String
    var message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)

            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(0.12), lineWidth: 1)
        }
    }
}

private extension BoardThread {
    var listTagTitle: String {
        if title.contains("物販") {
            return "物販エリア"
        }
        if title.contains("終演") || title.contains("会場") {
            return "会場横"
        }
        if title.contains("開封") {
            return "めぐり広場"
        }
        if audience == .samePrefecture, let prefecture {
            return prefecture
        }
        return "同じ現場"
    }
}
