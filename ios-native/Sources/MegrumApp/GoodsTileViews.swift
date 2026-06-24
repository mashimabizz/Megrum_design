import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsTile: View {
    var item: GoodsItem
    var context: GoodsGridContext = .tradeCandidate
    var actions: [GoodsTileAction] = GoodsTileAction.visibleActions
    var onOpenDetail: () -> Void
    var onAction: (GoodsTileAction) -> Void
    var isBusy = false
    var isSelectionMode = false
    var isSelected = false
    var usesSystemContextMenu = true
    var onLongPress: (() -> Void)?

    private var presentation: GoodsTilePresentation {
        GoodsTilePresentation(item: item, context: context, isBusy: isBusy)
    }

    private var usesImageOnlyCard: Bool {
        GoodsTileCardPolicy.usesImageOnlyCard(for: context)
    }

    var body: some View {
        Group {
            if onLongPress != nil {
                tileContent
                    .contentShape(Rectangle())
                    .modifier(GoodsTileExclusivePressModifier(
                        onTap: {
                            guard !isBusy else {
                                return
                            }
                            onOpenDetail()
                        },
                        onLongPress: onLongPress
                    ))
                    .accessibilityAddTraits(.isButton)
            } else {
                Button(action: onOpenDetail) {
                    tileContent
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
                .modifier(GoodsTileContextMenuModifier(
                    isEnabled: usesSystemContextMenu,
                    primaryActions: primaryActions,
                    destructiveActions: destructiveActions,
                    onAction: onAction
                ))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.title)
        .accessibilityValue(Text(presentation.accessibilityValue))
        .accessibilityHint(Text(accessibilityHint))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var primaryActions: [GoodsTileAction] {
        actions.filter { !$0.isDestructive }
    }

    private var destructiveActions: [GoodsTileAction] {
        actions.filter(\.isDestructive)
    }

    private var accessibilityHint: String {
        if isBusy {
            return "処理が終わるまで操作できません。"
        }
        if isSelectionMode {
            return "タップで選択を切り替えます。"
        }
        if onLongPress != nil {
            return "タップで操作メニューを開きます。長押しで複数選択できます。"
        }
        if actions.count > 1 {
            return "ダブルタップで詳細を開きます。長押しで操作メニューを開けます。"
        }
        return "ダブルタップで詳細を開きます。"
    }

    private var tileContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            tileImage

            if !usesImageOnlyCard {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)

                    Text(presentation.tileMetadataText)
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
            }
        }
    }

    private var tileImage: some View {
        RoundedRectangle(cornerRadius: GoodsGridLayout.tileCornerRadius, style: .continuous)
            .fill(usesImageOnlyCard ? AnyShapeStyle(GoodsTileCollectionCardStyle.hue(for: item)) : AnyShapeStyle(tileGradient))
            .aspectRatio(GoodsGridLayout.tileAspectRatio, contentMode: .fit)
            .overlay {
                if let imageURL = item.imageURL {
                    GoodsRemoteImage(
                        url: imageURL,
                        cornerRadius: GoodsGridLayout.tileCornerRadius,
                        placeholderIconSize: 28
                    )
                } else if usesImageOnlyCard {
                    GoodsCollectionFallback(item: item)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.74))
                }
            }
            .overlay(alignment: .topTrailing) {
                if usesImageOnlyCard {
                    GoodsCollectionTagPlate(text: GoodsTileCollectionCardStyle.tagLine(for: item))
                } else if let tag = item.tags.first {
                    GoodsTagPill(name: tag.name, fontSize: 11, horizontalPadding: 9)
                        .padding(8)
                }
            }
            .overlay(alignment: .topLeading) {
                if isSelectionMode {
                    GoodsSelectionBadge(isSelected: isSelected)
                        .padding(6)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if item.quantity > 1 {
                    GoodsQuantityBadge(quantity: item.quantity)
                        .padding(8)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: GoodsGridLayout.tileCornerRadius, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(GoodsTileCollectionCardMetrics.borderOpacity), lineWidth: 1)
                    .accessibilityHidden(true)
            }
            .overlay {
                if isBusy {
                    RoundedRectangle(cornerRadius: GoodsGridLayout.tileCornerRadius, style: .continuous)
                        .fill(.black.opacity(0.18))
                    ProgressView()
                        .tint(.white)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: GoodsGridLayout.tileCornerRadius, style: .continuous))
            .shadow(
                color: MegrumTheme.ink.opacity(usesImageOnlyCard ? GoodsTileCollectionCardMetrics.shadowOpacity : 0.08),
                radius: usesImageOnlyCard ? GoodsTileCollectionCardMetrics.shadowRadius : 10,
                x: usesImageOnlyCard ? GoodsTileCollectionCardMetrics.shadowX : 0,
                y: usesImageOnlyCard ? GoodsTileCollectionCardMetrics.shadowY : 5
            )
    }

    private var tileGradient: LinearGradient {
        LinearGradient(
            colors: [
                MegrumTheme.sky.opacity(0.62),
                MegrumTheme.lavender.opacity(0.72),
                MegrumTheme.pink.opacity(0.54)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct GoodsTileContextMenuModifier: ViewModifier {
    var isEnabled: Bool
    var primaryActions: [GoodsTileAction]
    var destructiveActions: [GoodsTileAction]
    var onAction: (GoodsTileAction) -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.contextMenu {
                ForEach(primaryActions) { action in
                    Button(role: action.role) {
                        onAction(action)
                    } label: {
                        Label(action.title, systemImage: action.symbolName)
                    }
                }
                if !destructiveActions.isEmpty {
                    Divider()
                    ForEach(destructiveActions) { action in
                        Button(role: action.role) {
                            onAction(action)
                        } label: {
                            Label(action.title, systemImage: action.symbolName)
                        }
                    }
                }
            }
        } else {
            content
        }
    }
}

private struct GoodsTileExclusivePressModifier: ViewModifier {
    var onTap: () -> Void
    var onLongPress: (() -> Void)?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let onLongPress {
            content.gesture(
                ExclusiveGesture(
                    LongPressGesture(minimumDuration: 0.45, maximumDistance: 18),
                    TapGesture()
                )
                .onEnded { value in
                    switch value {
                    case .first(true):
                        MegrumHaptics.longPress()
                        onLongPress()
                    case .second:
                        onTap()
                    case .first(false):
                        break
                    }
                }
            )
        } else {
            content.onTapGesture(perform: onTap)
        }
    }
}

private struct GoodsSelectionBadge: View {
    var isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? MegrumTheme.lavender : Color.white.opacity(0.82))
                .frame(width: 25, height: 25)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.92), lineWidth: 1.5)
                )
                .shadow(color: MegrumTheme.ink.opacity(0.14), radius: 5, y: 2)

            Image(systemName: isSelected ? "checkmark" : "circle")
                .font(.system(size: isSelected ? 12 : 10, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? .white : MegrumTheme.lavender)
        }
        .accessibilityHidden(true)
    }
}

struct GoodsCollectionFallback: View {
    var item: GoodsItem

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                GoodsTileCollectionCardStyle.hue(for: item)

                Circle()
                    .fill(.white.opacity(GoodsTileCollectionCardMetrics.shineOpacity))
                    .frame(
                        width: GoodsTileCollectionCardMetrics.shineSize,
                        height: GoodsTileCollectionCardMetrics.shineSize
                    )
                    .position(
                        x: proxy.size.width + GoodsTileCollectionCardMetrics.shineCenterXOffset,
                        y: GoodsTileCollectionCardMetrics.shineCenterY
                    )

                Text(GoodsTileCollectionCardStyle.glyph(for: item))
                    .font(.system(
                        size: GoodsTileCollectionCardMetrics.glyphFontSize,
                        weight: .black,
                        design: .rounded
                    ))
                    .foregroundStyle(.white)
                    .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 5, y: 2)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct GoodsCollectionTagPlate: View {
    var text: String

    var body: some View {
        GeometryReader { proxy in
            GoodsTagTextPill(
                text: text,
                fontSize: GoodsTileCollectionCardMetrics.tagFontSize,
                horizontalPadding: GoodsTileCollectionCardMetrics.tagHorizontalPadding,
                verticalPadding: GoodsTileCollectionCardMetrics.tagVerticalPadding
            )
            .frame(maxWidth: proxy.size.width * GoodsTileCollectionCardMetrics.tagMaxWidthRatio, alignment: .trailing)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(GoodsTileCollectionCardMetrics.tagInset)
        }
        .accessibilityHidden(true)
    }
}
