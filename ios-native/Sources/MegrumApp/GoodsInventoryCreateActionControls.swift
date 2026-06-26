import MegrumDesign
import SwiftUI

struct GoodsCreatePhotoPickButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.82), in: Circle())
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 132)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct GoodsCreatePrimaryButton: View {
    var title: String
    var isDisabled: Bool = false
    var isCreatingGoodsEntry: Bool
    var showsProgress: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
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
        Button(action: action) {
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
        Button(action: action) {
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
        Button(action: action) {
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
