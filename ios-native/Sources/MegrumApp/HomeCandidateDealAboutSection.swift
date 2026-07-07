import Foundation
import MegrumDesign
import SwiftUI

/// 候補シート再設計（notes/19）の「この取引について」折りたたみ。
/// 現地/日程・支払いの判定（別セッションの HomeConditionVerdictBlock）をヘッダーから降格し、
/// 既定は閉じた iOS 標準 DisclosureGroup にまとめる。メモ・更新日は最小表示。iter1226.374。
struct HomeCandidateDealAboutSection: View {
    var verdict: HomeConditionVerdict?
    var exchangeSummary: HomeDiscoveryOwnerExchangeSummary?
    var paymentSummaryText: String
    var exchangeCalendarContext: HomePartnerExchangeCalendarContext?
    var listingNote: String?
    var listingUpdatedAt: Date?
    var goodsUpdatedAt: Date?
    @State private var expanded = false
    @State private var presentedCalendar: HomePartnerExchangeCalendarContext?

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 12) {
                if let verdict, !verdict.isEmpty {
                    ForEach(verdict.lines) { line in
                        HomeConditionVerdictRow(
                            line: line,
                            onOpenCalendar: line.showsCalendarButton ? calendarAction : nil
                        )
                    }
                } else {
                    if let exchangeSummary {
                        HomeExchangeMethodBlock(summary: exchangeSummary, onOpenCalendar: calendarAction)
                    }
                    HomePaymentBox(summaryText: paymentSummaryText)
                }

                if let note = listingNote?.nilIfBlank {
                    HomeCandidateAboutNoteRow(note: note)
                }

                if let timestampText {
                    Text(timestampText)
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .bold))
                Text("交換の方法について")
                    .font(.system(size: 13.5, weight: .black, design: .rounded))
            }
            .foregroundStyle(MegrumTheme.ink.opacity(0.82))
        }
        .tint(MegrumTheme.lavender)
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .background(MegrumTheme.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .sheet(item: $presentedCalendar) { context in
            HomePartnerExchangeCalendarSheet(context: context)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var calendarAction: (() -> Void)? {
        guard let exchangeCalendarContext else {
            return nil
        }
        return { presentedCalendar = exchangeCalendarContext }
    }

    private var timestampText: String? {
        if let listingUpdatedAt {
            return "更新日 " + Self.timestampFormatter.string(from: listingUpdatedAt)
        }
        if let goodsUpdatedAt {
            return "登録日 " + Self.timestampFormatter.string(from: goodsUpdatedAt)
        }
        return nil
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/M/d"
        return formatter
    }()
}

private struct HomeCandidateAboutNoteRow: View {
    var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: "text.alignleft")
                Text("メモ")
            }
            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)

            Text(note)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
