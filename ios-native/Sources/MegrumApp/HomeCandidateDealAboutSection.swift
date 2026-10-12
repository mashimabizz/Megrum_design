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
    /// iter1226.468：メモを「条件のグッズを確認！」の直上へ昇格表示する画面では、
    /// この折りたたみ内の重複表示を抑止する（false でメモ行を出さない）。
    var showsListingNoteRow: Bool = true
    var listingUpdatedAt: Date?
    var goodsUpdatedAt: Date?
    /// 「交換内容を確認する」が有効になったか。true になった瞬間に自動展開する（iter1226.384 / FB7-3）。
    var isReadyToConfirm: Bool = false
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

                if showsListingNoteRow, let note = listingNote?.nilIfBlank {
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
                    .foregroundStyle(MegrumTheme.ink.opacity(0.82))
                Text("交換の方法について")
                    .font(.system(size: 13.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.82))

                Spacer(minLength: 8)

                // 畳んだままでも「現地/郵送/支払」の成立状況が一目で分かるステータスチップ。
                // 緑=そのままOK・オレンジ=要相談・赤=要確認・グレー=対象外（iter1226.409 / FB項目2）。
                if let verdict, !verdict.isEmpty {
                    HomeAboutStatusChipRow(verdict: verdict)
                }
            }
        }
        .tint(MegrumTheme.lavender)
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .background(MegrumTheme.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            // 開いた時点で既に成立可能なら（先頭候補が自動選択済み等）最初から展開しておく。
            if isReadyToConfirm {
                expanded = true
            }
        }
        .onChange(of: isReadyToConfirm) { _, ready in
            // 成立可能になった瞬間に自動展開（ユーザーが後から畳むのは自由）。iter1226.384 / FB7-3。
            if ready {
                withAnimation(.snappy(duration: 0.28)) {
                    expanded = true
                }
            }
        }
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

/// 折りたたみヘッダー右側のステータスチップ列。現地/郵送/支払の3チャンネルを
/// 「アイコン＋短ラベル」＋状態色で要約する（文字文字した判定文を開かずに把握できる）。
struct HomeAboutStatusChipRow: View {
    var verdict: HomeConditionVerdict

    var body: some View {
        HStack(spacing: 5) {
            chip(kind: .local, systemName: "mappin.and.ellipse", title: "現地")
            chip(kind: .mail, systemName: "shippingbox", title: "郵送")
            if let payment = line(for: .payment) {
                statusChip(systemName: "yensign", title: "支払", state: state(for: payment.badge))
            }
        }
    }

    private func line(for kind: ConditionVerdictLine.Kind) -> ConditionVerdictLine? {
        verdict.lines.first { $0.kind == kind }
    }

    @ViewBuilder
    private func chip(kind: ConditionVerdictLine.Kind, systemName: String, title: String) -> some View {
        if let line = line(for: kind) {
            statusChip(systemName: systemName, title: title, state: state(for: line.badge))
        } else {
            // 相手がその方法を選んでいない＝グレーで「対象外」を示す。
            statusChip(systemName: systemName, title: title, state: .unavailable)
        }
    }

    private func state(for badge: ConditionVerdictBadge) -> HomeAboutChipState {
        switch badge {
        case .ok:
            .ok
        case .needsTalk:
            .talk
        case .check:
            .warn
        }
    }

    // ヘッダー幅が限られるためアイコンのみの円形チップにする（ラベルはaccessibilityで担保）。
    private func statusChip(systemName: String, title: String, state: HomeAboutChipState) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 10.5, weight: .bold))
            .foregroundStyle(state.foreground)
            .frame(width: 24, height: 24)
            .background(state.background, in: Circle())
            .accessibilityLabel("\(title)：\(state.accessibilityText)")
    }
}

enum HomeAboutChipState {
    case ok
    case talk
    case warn
    case unavailable

    var foreground: Color {
        switch self {
        case .ok:
            MegrumTheme.ok
        case .talk:
            MegrumTheme.conditionPossible
        case .warn:
            MegrumTheme.conditionExact
        case .unavailable:
            MegrumTheme.ink.opacity(0.28)
        }
    }

    var background: Color {
        switch self {
        case .ok:
            MegrumTheme.ok.opacity(0.11)
        case .talk:
            MegrumTheme.conditionPossible.opacity(0.11)
        case .warn:
            MegrumTheme.conditionExact.opacity(0.10)
        case .unavailable:
            MegrumTheme.ink.opacity(0.045)
        }
    }

    var accessibilityText: String {
        switch self {
        case .ok:
            "そのまま成立できます"
        case .talk:
            "取引成立までに相談が必要です"
        case .warn:
            "条件が合っていないため要確認です"
        case .unavailable:
            "この方法は対象外です"
        }
    }
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
