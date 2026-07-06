import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

/// 検索ブラウズの入口行（「ほしいものから探す ＞」「個別募集から探す ＞」）。
struct SearchEntryRow: View {
    var title: String
    var systemImageName: String
    var tint: Color
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(action)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImageName)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(MegrumTheme.muted.opacity(0.7))
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("選択画面を開きます")
    }
}

/// ほしいものから探す：自分のほしいものを画像グリッドで選ぶシート。
struct SearchWishPickerSheet: View {
    var wishes: [WishItem]
    var onSelect: (SearchSuggestionAction) -> Void

    @Environment(\.dismiss) private var dismiss

    private var items: [SearchSuggestionItem] {
        SearchSuggestionBuilder.wishItems(wishes: wishes)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 14) {
                    ForEach(items) { item in
                        Button {
                            MegrumHaptics.buttonTap()
                            dismiss()
                            onSelect(item.action)
                        } label: {
                            VStack(spacing: 6) {
                                Group {
                                    if let imageURL = item.imageURL {
                                        GoodsRemoteImage(url: imageURL, cornerRadius: 16, placeholderIconSize: 20)
                                    } else {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(MegrumTheme.lavender.opacity(0.12))
                                            .overlay {
                                                Image(systemName: "heart")
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundStyle(MegrumTheme.pink)
                                            }
                                    }
                                }
                                .frame(height: 104)
                                .frame(maxWidth: .infinity)
                                .clipped()

                                Text(item.title)
                                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                    .foregroundStyle(MegrumTheme.ink)
                                    .lineLimit(1)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 32)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle("ほしいものから探す")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

/// 個別募集から探す：募集カード＋選択肢行で検索条件を選ぶシート。
struct SearchListingPickerSheet: View {
    var listings: [IndividualListing]
    var wishes: [WishItem]
    var inventory: [GoodsItem]
    var groups: [OshiGroup]
    var goodsTypes: [GoodsType]
    var characters: [OshiCharacter]
    var onSelect: (ListingSearchCriteria) -> Void

    @Environment(\.dismiss) private var dismiss

    private var activeListings: [IndividualListing] {
        Array(listings.filter { $0.status == .active }.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if activeListings.isEmpty {
                        ContentUnavailableView(
                            "公開中の個別募集がありません",
                            systemImage: "bookmark",
                            description: Text("個別募集を作ると、その条件で相手を探せます。")
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(activeListings) { listing in
                            listingCard(listing)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 32)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle("個別募集から探す")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func listingCard(_ listing: IndividualListing) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー：譲るもの（タップで全選択肢まとめて検索）
            Button {
                MegrumHaptics.buttonTap()
                dismiss()
                onSelect(ListingSearchCriteriaBuilder.criteria(for: listing, wishes: wishes))
            } label: {
                HStack(spacing: 10) {
                    havesThumbs(listing)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("譲: \(ListingSearchCriteriaBuilder.title(for: listing, inventory: inventory))")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)
                        Text("タップで全選択肢まとめて探す")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    Spacer(minLength: 6)
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(MegrumTheme.lavender)
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().opacity(0.5)

            // 選択肢の行（タップでその選択肢だけで検索）
            ForEach(Array(listing.options.enumerated()), id: \.element.id) { index, option in
                Button {
                    MegrumHaptics.buttonTap()
                    dismiss()
                    onSelect(ListingSearchCriteriaBuilder.criteria(for: option, wishes: wishes))
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11.5, weight: .heavy))
                            .foregroundStyle(MegrumTheme.lavender.opacity(0.85))
                        Text("求: \(optionSummary(option))")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink.opacity(0.85))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 6)
                        if let thumbURL = optionThumbURL(option) {
                            GoodsRemoteImage(url: thumbURL, cornerRadius: 8, placeholderIconSize: 10)
                                .frame(width: 32, height: 32)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < listing.options.count - 1 {
                    Divider().opacity(0.35).padding(.leading, 34)
                }
            }
        }
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func havesThumbs(_ listing: IndividualListing) -> some View {
        let urls = listing.haves.prefix(2).compactMap { have in
            inventory.first { $0.id == have.itemID }?.imageURL
        }
        HStack(spacing: -10) {
            if urls.isEmpty {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(MegrumTheme.lavender.opacity(0.12))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "yensign.circle")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(MegrumTheme.lavender)
                    }
            } else {
                ForEach(Array(urls.enumerated()), id: \.offset) { _, url in
                    GoodsRemoteImage(url: url, cornerRadius: 10, placeholderIconSize: 12)
                        .frame(width: 40, height: 40)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(.white, lineWidth: 1.5)
                        }
                }
            }
        }
    }

    /// 個別募集一覧の表現に合わせた選択肢の要約。
    private func optionSummary(_ option: IndividualListingWishOption) -> String {
        if option.isCashOffer || option.cashAmount != nil {
            if let amount = option.cashAmount {
                return "定価交換（¥\(amount.formatted())）"
            }
            return "定価交換"
        }
        if option.wishes.isEmpty {
            let groupName = option.wishGroupID.flatMap { id in groups.first { $0.id == id }?.name } ?? "グループ未設定"
            let typeName = option.wishGoodsTypeID.flatMap { id in goodsTypes.first { $0.id == id }?.name } ?? "種別未設定"
            let memberText: String
            if option.wishMemberIDs.isEmpty {
                memberText = "メンバー指定なし"
            } else {
                let names = option.wishMemberIDs.compactMap { id in characters.first { $0.id == id }?.name }
                let joined = names.isEmpty ? "\(option.wishMemberIDs.count)名" : names.joined(separator: "・")
                memberText = option.excludesWishMembers ? "\(joined) 以外" : joined
            }
            let seriesText = option.wishSeriesNames.isEmpty
                ? ""
                : " " + option.wishSeriesNames.map { "#\($0)" }.joined(separator: " ")
            return "\(groupName)・\(memberText)・\(typeName)\(seriesText) ×\(option.wishQuantity)"
        }
        let wishByID = Dictionary(wishes.map { ($0.id, $0) }) { first, _ in first }
        let titles = option.wishes.compactMap { wishByID[$0.itemID]?.title }
        guard let first = titles.first else {
            return "ほしいもの \(option.wishes.count)件"
        }
        return titles.count > 1 ? "\(first)（ほか\(titles.count - 1)件）" : first
    }

    private func optionThumbURL(_ option: IndividualListingWishOption) -> URL? {
        let wishByID = Dictionary(wishes.map { ($0.id, $0) }) { first, _ in first }
        return option.wishes.compactMap { wishByID[$0.itemID]?.imageURL }.first
    }
}
