import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingSelectionFilter: Equatable {
    var searchText = ""
    var groupID: UUID?
    var goodsTypeID: UUID?
    var tagNames: Set<String> = []

    var isActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || groupID != nil
            || goodsTypeID != nil
            || !tagNames.isEmpty
    }

    mutating func reconcile(availableGroupIDs: Set<UUID>, availableGoodsTypeIDs: Set<UUID>, availableTagNames: Set<String>) {
        if let groupID, !availableGroupIDs.contains(groupID) {
            self.groupID = nil
        }
        if let goodsTypeID, !availableGoodsTypeIDs.contains(goodsTypeID) {
            self.goodsTypeID = nil
        }
        tagNames.formIntersection(availableTagNames)
    }

    func matches(_ item: GoodsItem) -> Bool {
        matches(
            title: item.title,
            groupID: item.groupID,
            goodsTypeID: item.goodsTypeID,
            tags: item.tags
        )
    }

    func matches(_ item: WishItem) -> Bool {
        matches(
            title: item.title,
            groupID: item.groupID,
            goodsTypeID: item.goodsTypeID,
            tags: item.tags
        )
    }

    private func matches(title: String, groupID itemGroupID: UUID?, goodsTypeID itemGoodsTypeID: UUID?, tags: [GoodsTag]) -> Bool {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            let matchesTitle = title.localizedCaseInsensitiveContains(trimmedSearch)
            let matchesTag = tags.contains { $0.name.localizedCaseInsensitiveContains(trimmedSearch) }
            guard matchesTitle || matchesTag else {
                return false
            }
        }
        if let groupID, itemGroupID != groupID {
            return false
        }
        if let goodsTypeID, itemGoodsTypeID != goodsTypeID {
            return false
        }
        if !tagNames.isEmpty {
            let itemTagNames = Set(tags.map(\.name))
            if !tagNames.isSubset(of: itemTagNames) {
                return false
            }
        }
        return true
    }
}

enum IndividualListingSelectionFilterChoices {
    static func groups(items: [GoodsItem], allGroups: [OshiGroup]) -> [OshiGroup] {
        GoodsCollectionFilterChoices.groups(items: items, allGroups: allGroups)
    }

    static func goodsTypes(items: [GoodsItem], allGoodsTypes: [GoodsType]) -> [GoodsType] {
        GoodsCollectionFilterChoices.goodsTypes(items: items, allGoodsTypes: allGoodsTypes)
    }

    static func tagNames(items: [GoodsItem], filter: IndividualListingSelectionFilter, limit: Int = 20) -> [String] {
        GoodsCollectionFilterChoices.tagNames(
            items: items,
            selectedGroupID: filter.groupID,
            selectedGoodsTypeID: filter.goodsTypeID,
            limit: limit
        )
    }

    static func groups(wishes: [WishItem], allGroups: [OshiGroup]) -> [OshiGroup] {
        let usedGroupIDs = Set(wishes.compactMap(\.groupID))
        return allGroups.filter { usedGroupIDs.contains($0.id) }
    }

    static func goodsTypes(wishes: [WishItem], allGoodsTypes: [GoodsType]) -> [GoodsType] {
        let usedGoodsTypeIDs = Set(wishes.compactMap(\.goodsTypeID))
        return allGoodsTypes.filter { usedGoodsTypeIDs.contains($0.id) }
    }

    static func tagNames(wishes: [WishItem], filter: IndividualListingSelectionFilter, limit: Int = 20) -> [String] {
        let names = wishes
            .filter { wish in
                (filter.groupID == nil || wish.groupID == filter.groupID)
                    && (filter.goodsTypeID == nil || wish.goodsTypeID == filter.goodsTypeID)
            }
            .flatMap { $0.tags.map(\.name) }
        return TagNameNormalizer.uniqueSorted(names, limit: limit)
    }
}

struct IndividualListingSelectionSearchAndFilterBar: View {
    @Binding var filter: IndividualListingSelectionFilter
    var searchPlaceholder: String
    var groups: [OshiGroup]
    var goodsTypes: [GoodsType]
    var tagNames: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            searchField
            filterRows
        }
        .onChange(of: groups.map(\.id)) { _, _ in
            reconcileFilter()
        }
        .onChange(of: goodsTypes.map(\.id)) { _, _ in
            reconcileFilter()
        }
        .onChange(of: tagNames) { _, _ in
            reconcileFilter()
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(MegrumTheme.muted.opacity(0.72))
            TextField(searchPlaceholder, text: $filter.searchText)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .disableAutocorrection(true)
            if !filter.searchText.isEmpty {
                Button {
                    filter.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(MegrumTheme.muted.opacity(0.62))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("検索語をクリア")
            }
        }
        .padding(.horizontal, 15)
        .frame(height: 50)
        .background(MegrumTheme.ink.opacity(0.045), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var filterRows: some View {
        VStack(alignment: .leading, spacing: CollectionScreenLayoutMetrics.filterBarSpacing) {
            IndividualListingFilterChoiceRow(title: "グループ") {
                ChoiceChip(title: "すべて", isSelected: filter.groupID == nil, style: .compact) {
                    filter.groupID = nil
                }
                ForEach(groups) { group in
                    ChoiceChip(title: group.name, isSelected: filter.groupID == group.id, style: .compact) {
                        filter.groupID = group.id
                    }
                }
            }

            IndividualListingFilterChoiceRow(title: "グッズ種別") {
                ChoiceChip(title: "すべて", isSelected: filter.goodsTypeID == nil, style: .compact) {
                    filter.goodsTypeID = nil
                }
                ForEach(goodsTypes) { goodsType in
                    ChoiceChip(title: goodsType.name, isSelected: filter.goodsTypeID == goodsType.id, style: .compact) {
                        filter.goodsTypeID = goodsType.id
                    }
                }
            }

            if !tagNames.isEmpty || !filter.tagNames.isEmpty {
                IndividualListingFilterChoiceRow(title: "タグ") {
                    ChoiceChip(title: "すべて", isSelected: filter.tagNames.isEmpty, style: .compact) {
                        filter.tagNames = []
                    }
                    ForEach(tagNames, id: \.self) { tagName in
                        ChoiceChip(title: "#\(tagName)", isSelected: filter.tagNames.contains(tagName), style: .compact) {
                            if filter.tagNames.contains(tagName) {
                                filter.tagNames.remove(tagName)
                            } else {
                                filter.tagNames.insert(tagName)
                            }
                        }
                    }
                }
            }
        }
    }

    private func reconcileFilter() {
        filter.reconcile(
            availableGroupIDs: Set(groups.map(\.id)),
            availableGoodsTypeIDs: Set(goodsTypes.map(\.id)),
            availableTagNames: Set(tagNames)
        )
    }
}

private struct IndividualListingFilterChoiceRow<Content: View>: View {
    var title: String
    var content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineLimit(1)
                .frame(width: CollectionScreenLayoutMetrics.filterRowLabelWidth, height: CollectionScreenLayoutMetrics.filterChipHeight, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CollectionScreenLayoutMetrics.filterRowChipSpacing) {
                    content
                }
            }
        }
    }
}
