import MegrumDesign
import SwiftUI

struct GoodsCreateAddPhotoHeroTile: View {
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(action)
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text("写真を追加")
                    .font(.headline.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
                Text("タップして カメラ / ライブラリ から選ぶ")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MegrumTheme.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(MegrumTheme.lavender.opacity(0.07), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        MegrumTheme.lavender.opacity(0.5),
                        style: StrokeStyle(lineWidth: 1.6, dash: [7, 5])
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("写真を追加")
        .accessibilityHint("カメラかライブラリを選びます")
    }
}

struct GoodsTradingCardBulkStartButton: View {
    var isProcessing: Bool
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(action)
        } label: {
            HStack(spacing: 12) {
                GoodsTradingCardBulkStartIcon(isProcessing: isProcessing)
                GoodsTradingCardBulkStartCopy()
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MegrumTheme.lavender)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [MegrumTheme.sky.opacity(0.20), MegrumTheme.lavender.opacity(0.10)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(MegrumTheme.sky.opacity(0.55), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }
}

private struct GoodsTradingCardBulkStartIcon: View {
    var isProcessing: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(MegrumTheme.sky)
                .frame(width: 36, height: 36)
            if isProcessing {
                ProgressView()
                    .tint(MegrumTheme.ink)
                    .controlSize(.small)
            } else {
                Text("AI")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
            }
        }
    }
}

private struct GoodsTradingCardBulkStartCopy: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("まとめて登録")
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
            Text("トレカを並べて1枚で撮ると、AIが枠を自動で配置します。")
                .font(.caption.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct GoodsCreatePrimaryButton: View {
    var title: String
    var isDisabled: Bool = false
    var isCreatingGoodsEntry: Bool
    var showsProgress: Bool = false
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(action)
        } label: {
            HStack(spacing: 10) {
                if showsProgress && isCreatingGoodsEntry {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(.headline.weight(.black))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isCreatingGoodsEntry)
        .opacity(isDisabled || isCreatingGoodsEntry ? 0.46 : 1)
    }
}

struct GoodsCreateSecondaryButton: View {
    var title: String
    var isCreatingGoodsEntry: Bool
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(action)
        } label: {
            Text(title)
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(isCreatingGoodsEntry)
    }
}

struct GoodsEditorSelectionChip: View {
    var title: String
    var isSelected: Bool
    var isDisabled: Bool = false
    var isCompact: Bool = false
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performSelectionChanged(action)
        } label: {
            Text(title)
                .font(.system(size: isCompact ? 12 : 13, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, isCompact ? 10 : 13)
                .padding(.vertical, isCompact ? 7 : 10)
                .frame(maxWidth: isCompact ? nil : .infinity)
                .background(
                    isSelected ? MegrumTheme.lavender : Color.white.opacity(0.82),
                    in: RoundedRectangle(cornerRadius: isCompact ? 11 : 13, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: isCompact ? 11 : 13, style: .continuous)
                        .strokeBorder(
                            isSelected ? MegrumTheme.lavender.opacity(0.25) : MegrumTheme.lavender.opacity(0.18),
                            lineWidth: 1
                        )
                }
                .opacity(isDisabled ? 0.48 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

struct GoodsEditorQuantityButton: View {
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(action)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 46, height: 46)
                .background(.white.opacity(0.88), in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
