import MegrumCore
import MegrumDesign
import SwiftUI

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
