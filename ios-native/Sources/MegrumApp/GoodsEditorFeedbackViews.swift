import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsEditorHeaderCard: View {
    var entryKind: GoodsEntryKind
    var title: String
    var badgeTitle: String
    var description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: entryKind == .inventory ? "shippingbox" : "heart")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(headerGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(badgeTitle)
                        .font(.caption.weight(.black))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }

            Text(description)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerGradient: LinearGradient {
        LinearGradient(
            colors: [MegrumTheme.lavender, MegrumTheme.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct GoodsEditorReadOnlyNotice: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("過去に譲った履歴")
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
            Text("取引履歴の整合性を保つため、このグッズは詳細確認のみできます。内容の更新や削除はできません。")
                .font(.caption.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MegrumTheme.pink.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MegrumTheme.pink.opacity(0.25), lineWidth: 1)
        }
    }
}

struct GoodsEditorUnsupportedNotice: View {
    var reasons: [GoodsEditorSaveBlocker]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("まだ保存できない変更があります", systemImage: "exclamationmark.triangle.fill")
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)

            ForEach(reasons) { reason in
                VStack(alignment: .leading, spacing: 4) {
                    Text(reason.title)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(reason.message)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MegrumTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(MegrumTheme.pink.opacity(0.14), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(MegrumTheme.pink.opacity(0.32), lineWidth: 1)
        }
    }
}

struct GoodsEditorSaveFailureNotice: View {
    var failure: GoodsEditorSaveFailure
    var onRetry: () -> Void
    var onRemovePhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(failure.title, systemImage: "exclamationmark.triangle.fill")
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)

            Text(failure.message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button(action: onRetry) {
                    Label("再試行", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(MegrumTheme.lavender)

                if failure.includesPhotoUpload {
                    Button(role: .destructive, action: onRemovePhoto) {
                        Label("写真を外す", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
        .background(MegrumTheme.pink.opacity(0.14), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(MegrumTheme.pink.opacity(0.32), lineWidth: 1)
        }
    }
}
