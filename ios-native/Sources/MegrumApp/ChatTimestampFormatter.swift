import Foundation
import MegrumDesign
import SwiftUI

/// チャット共通の時刻表記（取引チャット・めぐりメッセージ・チャットルーム）。
/// バブル外の時刻は「何分前」「何時間前」「HH:mm」のいずれか。
/// 日を跨いだ会話は直前に「今日」「昨日」「M/d(曜)」のセパレータを挟む。
enum ChatTimestampFormatter {
    static let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    /// バブル横の時刻表記。
    /// 1分未満=たった今 / 1時間未満=N分前 / 当日=N時間前 / それ以外=HH:mm
    /// （日付はセパレータ側が示すので時刻だけを出す）。
    static func timeText(for date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        if seconds < 60 {
            return "たった今"
        }
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes)分前"
        }
        if calendar.isDate(date, inSameDayAs: now) {
            return "\(minutes / 60)時間前"
        }
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    /// 日跨ぎセパレータ。当日=今日 / 前日=昨日 / それ以前=M/d(曜)。
    static func daySeparatorText(for date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return "今日"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "昨日"
        }
        let components = calendar.dateComponents([.month, .day, .weekday], from: date)
        let weekday = components.weekday.flatMap { value -> String? in
            guard (1...7).contains(value) else {
                return nil
            }
            return weekdaySymbols[value - 1]
        } ?? ""
        return "\(components.month ?? 1)/\(components.day ?? 1)(\(weekday))"
    }

    /// previous と日付が変わっていればセパレータを出す（previous が nil = 先頭も出す）。
    static func startsNewDay(_ date: Date, after previous: Date?, calendar: Calendar = .current) -> Bool {
        guard let previous else {
            return true
        }
        return !calendar.isDate(date, inSameDayAs: previous)
    }
}


/// チャット共通の日付セパレータ（今日/昨日/M/d(曜)）。
struct ChatDaySeparator: View {
    var date: Date
    var now: Date = .now

    var body: some View {
        Text(ChatTimestampFormatter.daySeparatorText(for: date, now: now))
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(MegrumTheme.ink.opacity(0.05), in: Capsule())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .accessibilityLabel("日付 \(ChatTimestampFormatter.daySeparatorText(for: date, now: now))")
    }
}
