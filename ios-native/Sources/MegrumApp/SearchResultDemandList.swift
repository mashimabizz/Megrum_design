import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

/// 検索結果の需要ファースト一覧の1行分。
struct SearchDemandRowEntry: Identifiable, Equatable {
    var index: Int
    var result: SearchResultItem
    /// 小見出し（メンバー×シリーズ or メンバー）。無ければ非表示。
    var subheading: String?
    var demandRank: Int

    var id: UUID { result.id }
}

/// グループ単位のセクション（大見出し）。
struct SearchDemandSection: Identifiable, Equatable {
    var groupTitle: String
    var rows: [SearchDemandRowEntry]

    var id: String { groupTitle }
}

/// フラット化した表示エントリ（3行に1つ広告を挟む）。
enum SearchDemandListEntry: Identifiable {
    case groupHeader(String)
    case row(SearchDemandRowEntry)
    case ad(slotIndex: Int)

    var id: String {
        switch self {
        case .groupHeader(let title):
            "header-\(title)"
        case .row(let entry):
            "row-\(entry.result.id.uuidString)"
        case .ad(let slotIndex):
            "ad-\(slotIndex)"
        }
    }
}

enum SearchResultDemandListBuilder {
    /// 広告の挿入間隔（データ3行ごとに1つ）。
    static let adInterval = 3

    /// グループ（大見出し）ごとに1件ずつの行へ整理する。
    /// 並びは需要順（既定）＝塊内・塊間とも需要ランク降順、新着順＝updatedAt降順。
    static func sections(
        results: [SearchResultItem],
        signals: [UUID: HomeCandidateConditionSignals],
        sort: SearchResultSort
    ) -> [SearchDemandSection] {
        let entries = results.enumerated().map { index, result in
            SearchDemandRowEntry(
                index: index,
                result: result,
                subheading: subheading(for: result.item),
                demandRank: HomeCandidateDemandPolicy.demandRank(
                    for: SearchResultHomePresentation.signals(for: result, index: index, explicitSignals: signals)
                )
            )
        }

        var grouped: [String: [SearchDemandRowEntry]] = [:]
        var groupOrder: [String] = []
        for entry in entries {
            let title = entry.result.item.groupName?.nilIfBlank ?? "その他"
            if grouped[title] == nil {
                groupOrder.append(title)
            }
            grouped[title, default: []].append(entry)
        }

        let sections = groupOrder.map { title in
            SearchDemandSection(
                groupTitle: title,
                rows: sortedRows(grouped[title] ?? [], sort: sort)
            )
        }
        return sortedSections(sections, sort: sort)
    }

    static func entries(
        sections: [SearchDemandSection],
        includesAds: Bool,
        adInterval: Int = adInterval
    ) -> [SearchDemandListEntry] {
        var entries: [SearchDemandListEntry] = []
        let totalRowCount = sections.reduce(0) { $0 + $1.rows.count }
        var rowCount = 0
        var adCount = 0

        for section in sections {
            entries.append(.groupHeader(section.groupTitle))
            for row in section.rows {
                entries.append(.row(row))
                rowCount += 1
                if includesAds,
                   adInterval > 0,
                   rowCount.isMultiple(of: adInterval),
                   rowCount < totalRowCount {
                    adCount += 1
                    entries.append(.ad(slotIndex: adCount))
                }
            }
        }
        return entries
    }

    /// 小見出し：メンバー×シリーズ ＞ メンバー ＞ シリーズのみ。
    static func subheading(for item: GoodsItem) -> String? {
        let member = item.memberName?.nilIfBlank
        let series = item.tags.first?.name.nilIfBlank
        switch (member, series) {
        case let (member?, series?):
            return "\(member) × #\(series)"
        case let (member?, nil):
            return member
        case let (nil, series?):
            return "#\(series)"
        case (nil, nil):
            return nil
        }
    }

    private static func sortedRows(_ rows: [SearchDemandRowEntry], sort: SearchResultSort) -> [SearchDemandRowEntry] {
        switch sort {
        case .demand:
            rows.enumerated().sorted { lhs, rhs in
                if lhs.element.demandRank == rhs.element.demandRank {
                    return lhs.offset < rhs.offset
                }
                return lhs.element.demandRank > rhs.element.demandRank
            }
            .map(\.element)
        case .newest:
            rows.enumerated().sorted { lhs, rhs in
                let lhsDate = lhs.element.result.item.updatedAt ?? .distantPast
                let rhsDate = rhs.element.result.item.updatedAt ?? .distantPast
                if lhsDate == rhsDate {
                    return lhs.offset < rhs.offset
                }
                return lhsDate > rhsDate
            }
            .map(\.element)
        }
    }

    private static func sortedSections(_ sections: [SearchDemandSection], sort: SearchResultSort) -> [SearchDemandSection] {
        switch sort {
        case .demand:
            sections.enumerated().sorted { lhs, rhs in
                let lhsRank = lhs.element.rows.map(\.demandRank).max() ?? 0
                let rhsRank = rhs.element.rows.map(\.demandRank).max() ?? 0
                if lhsRank == rhsRank {
                    return lhs.offset < rhs.offset
                }
                return lhsRank > rhsRank
            }
            .map(\.element)
        case .newest:
            sections.enumerated().sorted { lhs, rhs in
                let lhsDate = lhs.element.rows.compactMap(\.result.item.updatedAt).max() ?? .distantPast
                let rhsDate = rhs.element.rows.compactMap(\.result.item.updatedAt).max() ?? .distantPast
                if lhsDate == rhsDate {
                    return lhs.offset < rhs.offset
                }
                return lhsDate > rhsDate
            }
            .map(\.element)
        }
    }
}

/// 検索結果の1行（回転なしの単票・需要ファースト構成）。
struct SearchResultDemandRow: View {
    var goods: HomeMockGoods
    var signals: HomeCandidateConditionSignals
    var viewerGoodsImageURLByID: [UUID: URL]
    var onOpen: () -> Void

    var body: some View {
        let demand = HomeCandidateDemandPolicy.demandLine(for: signals)
        let logistics = HomeCandidateDemandPolicy.logisticsText(for: signals)
        let payment = HomeCandidateDemandPolicy.paymentText(for: signals)

        Button {
            MegrumHaptics.performButtonTap(onOpen)
        } label: {
            HStack(alignment: .center, spacing: 14) {
                HomeDiscoveryGoodsCard(
                    goods: goods,
                    goodsCondition: .none,
                    exchangeCondition: .warning,
                    paymentCondition: .unknown,
                    prominence: 1,
                    showsConditionOverlay: false
                )
                .frame(width: 112, height: 112)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        SearchResultPartnerAvatar(url: goods.ownerAvatarURL)
                        Text(goods.ownerDisplayName?.nilIfBlank ?? goods.ownerHandle?.nilIfBlank ?? "ユーザー")
                            .font(.system(size: 12.5, weight: .regular, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink.opacity(0.86))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }

                    HomeCandidateDemandLineView(
                        demand: demand,
                        viewerGoodsImageURLByID: viewerGoodsImageURLByID
                    )

                    Text(logistics)
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.66))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let payment {
                        Text(payment)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink.opacity(0.52))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SearchResultPartnerAvatar: View {
    var url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 20, height: 20)
        .clipShape(Circle())
        .overlay {
            Circle().strokeBorder(.white, lineWidth: 1.2)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.14), radius: 3, y: 1)
    }

    private var placeholder: some View {
        ZStack {
            Color(white: 0.90)
            Image(systemName: "person.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color(white: 0.62))
        }
    }
}
