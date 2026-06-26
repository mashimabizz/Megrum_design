import MegrumDesign
import SwiftUI

struct GoodsCreateHintCard: View {
    var title: String
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1)
        }
    }
}

struct GoodsCreateErrorNotice: View {
    var message: String

    var body: some View {
        Text(message)
            .font(.caption.weight(.bold))
            .foregroundStyle(.red)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MegrumTheme.pink.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct GoodsTradingCardBulkProcessingCard: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(MegrumTheme.lavender)
            VStack(alignment: .leading, spacing: 4) {
                Text("AIでカード枠を検出中")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
                Text("検出後、黄色い枠と切り取りプレビューを確認できます。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MegrumTheme.sky.opacity(0.16), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
        }
    }
}

struct GoodsTradingCardBulkStatusCard: View {
    var message: String

    var body: some View {
        Label {
            Text(message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "sparkles")
                .foregroundStyle(MegrumTheme.lavender)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
        }
    }
}
