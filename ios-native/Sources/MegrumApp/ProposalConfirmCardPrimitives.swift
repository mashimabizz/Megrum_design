import Foundation
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

struct ProposalConfirmRowItem: Identifiable {
    var title: String
    var value: String

    var id: String { "\(title):\(value)" }
}

struct ProposalConfirmLocalRows {
    var summaryText: String

    var rows: [ProposalConfirmRowItem] {
        [
            ProposalConfirmRowItem(title: "都道府県", value: prefecture),
            ProposalConfirmRowItem(title: "メモ", value: memo),
            ProposalConfirmRowItem(title: "日程", value: schedule)
        ]
    }

    private var parts: [String] {
        normalizedParts(from: summaryText)
    }

    private var prefecture: String {
        parts.first ?? "未設定"
    }

    private var memo: String {
        guard parts.count >= 3 else {
            return ""
        }
        return parts[1]
    }

    private var schedule: String {
        if parts.count >= 3 {
            return parts[2]
        }
        if parts.count == 2 {
            return parts[1]
        }
        return "未設定"
    }
}

struct ProposalConfirmShippingRows {
    var summaryText: String

    var rows: [ProposalConfirmRowItem] {
        [
            ProposalConfirmRowItem(title: "送料", value: fee),
            ProposalConfirmRowItem(title: "発送目安", value: days)
        ]
    }

    private var parts: [String] {
        normalizedParts(from: summaryText)
    }

    private var fee: String {
        cleanedValue(parts.first, prefixes: ["送料"])
    }

    private var days: String {
        cleanedValue(parts.dropFirst().first, prefixes: ["発送", "発送目安"])
    }
}

private func normalizedParts(from text: String) -> [String] {
    text
        .components(separatedBy: " / ")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty && $0 != "未設定" && $0 != "対象外" }
}

private func cleanedValue(_ value: String?, prefixes: [String]) -> String {
    guard var value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !value.isEmpty
    else {
        return "未設定"
    }
    for prefix in prefixes {
        if value.hasPrefix(prefix) {
            value = String(value.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    return value.isEmpty ? "未設定" : value
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
