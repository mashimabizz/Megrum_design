import MegrumDesign
import SwiftUI

struct ProposalConfirmPlainCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(14)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.09), lineWidth: 1)
        }
    }
}

struct ProposalConfirmRoundIcon: View {
    var systemName: String
    var color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .black))
            .foregroundStyle(color)
            .frame(width: 34, height: 34)
            .background(color.opacity(0.14), in: Circle())
    }
}

struct ProposalConfirmDetailCard<Content: View>: View {
    var iconSystemName: String
    var iconColor: Color
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                ProposalConfirmRoundIcon(systemName: iconSystemName, color: iconColor)
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
            }
            .padding(.bottom, 12)

            content
        }
        .padding(14)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.09), lineWidth: 1)
        }
    }
}

struct ProposalConfirmDetailRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.82))
                .frame(width: 78, alignment: .leading)
            Spacer(minLength: 8)
            Text(value.isEmpty ? "未設定" : value)
                .font(.system(size: 13.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MegrumTheme.ink.opacity(0.08))
                .frame(height: 1)
        }
    }
}

struct ProposalConfirmPill: View {
    var title: String
    var tint: Color

    var body: some View {
        Text(title)
            .font(.system(size: 11.5, weight: .black, design: .rounded))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .allowsTightening(true)
            .padding(.horizontal, 7)
            .frame(height: 30)
            .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ProposalSummaryRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .frame(width: 92, alignment: .leading)
            Text(value.isEmpty ? "未選択" : value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }
}
