import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingConditionTab: View {
    var inventory: [GoodsItem]
    var wishes: [WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    @Binding var selectedGroupID: UUID?
    @Binding var selectedMemberIDs: Set<UUID>
    @Binding var excludesSelectedMembers: Bool
    @Binding var selectedGoodsTypeID: UUID?
    @Binding var selectedTagNames: [String]
    @Binding var quantity: Int
    var onShowOshiPicker: () -> Void
    var onToggleMember: (UUID) -> Void

    @State private var presentationState = IndividualListingConditionPresentationState()
    @State private var googleLensErrorMessage: String?
    @State private var googleLensBrowserRoute: MegrumInAppBrowserRoute?
    @Environment(\.openURL) private var openURL

    private var selectedGroup: OshiGroup? {
        groups.first { $0.id == selectedGroupID } ?? groups.first
    }

    private var selectedGoodsType: GoodsType? {
        goodsTypes.first { $0.id == selectedGoodsTypeID } ?? goodsTypes.first
    }

    private var selectedMembers: [OshiCharacter] {
        characters.filter { selectedMemberIDs.contains($0.id) }
    }

    private var usesLogicChoice: Bool {
        selectedMemberIDs.count > 1 || excludesSelectedMembers
    }

    private var tagBuilder: IndividualListingConditionTagBuilder {
        IndividualListingConditionTagBuilder(
            inventory: inventory,
            wishes: wishes,
            selectedGroupID: selectedGroupID
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 0) {
                IndividualListingActionRow(
                    title: "グループ / 作品",
                    value: selectedGroup?.name ?? "選択",
                    action: onShowOshiPicker
                )
                Divider()
                IndividualListingActionRow(
                    title: "メンバー / キャラ",
                    value: memberSummary,
                    action: { presentationState.showMemberPicker() }
                )
                Divider()
                IndividualListingGoodsTypeRow(
                    goodsTypes: goodsTypes,
                    selectedGoodsTypeName: selectedGoodsType?.name ?? "選択",
                    selectedGoodsTypeID: $selectedGoodsTypeID
                )
                Divider()
                IndividualListingTagRow(tagSummary: tagSummary) {
                    googleLensErrorMessage = nil
                    presentationState.showTagSheet()
                }
                Divider()
                if usesLogicChoice {
                    IndividualListingLogicHintRow()
                } else {
                    IndividualListingQuantityRow(quantity: $quantity)
                }
            }
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
            }
        }
        .sheet(isPresented: $presentationState.isShowingMemberPicker) {
            IndividualListingMemberPickerSheet(
                groupName: selectedGroup?.name ?? "メンバー",
                characters: characters.filter { selectedGroupID == nil || $0.groupID == selectedGroupID },
                selectedIDs: selectedMemberIDs,
                excludesSelectedMembers: $excludesSelectedMembers,
                onToggle: onToggleMember,
                onClose: { presentationState.dismissMemberPicker() }
            )
        }
        .sheet(isPresented: $presentationState.isShowingTagSheet) {
            GoodsBulkTagSheet(
                selectedCount: max(1, selectedTagNames.count),
                candidateNames: tagCandidateNames,
                previewItemsByTag: tagPreviewItemsByTag,
                navigationTitle: "シリーズを登録",
                textFieldPlaceholder: "例：会場限定",
                footerText: "この条件にシリーズを追加します。",
                confirmationTitle: "追加",
                googleLensItems: googleLensItems,
                googleLensErrorMessage: googleLensErrorMessage,
                onOpenGoogleLens: openGoogleLensSearch
            ) { tagName in
                addConditionTag(tagName)
            }
            #if os(iOS)
            .sheet(item: $googleLensBrowserRoute) { browserRoute in
                MegrumInAppSafariView(url: browserRoute.url)
                    .ignoresSafeArea()
            }
            #endif
        }
    }

    private var memberSummary: String {
        guard !selectedMembers.isEmpty else {
            return "指定なし"
        }
        let names = selectedMembers.prefix(2).map(\.name).joined(separator: "・")
        let suffix = selectedMembers.count > 2 ? " 他\(selectedMembers.count - 2)人" : ""
        return excludesSelectedMembers ? "\(names)\(suffix)以外" : "\(names)\(suffix)"
    }

    private var tagSummary: String {
        guard !selectedTagNames.isEmpty else {
            return "追加"
        }
        return selectedTagNames.prefix(2).map { "#\($0)" }.joined(separator: " ")
            + (selectedTagNames.count > 2 ? " 他\(selectedTagNames.count - 2)" : "")
    }

    private var tagCandidateNames: [String] {
        tagBuilder.candidateNames()
    }

    private var tagPreviewItemsByTag: [String: [TagPreviewItem]] {
        tagBuilder.previewItemsByTag()
    }

    private var googleLensItems: [GoodsGoogleLensSearchItem] {
        GoodsGoogleLensSearchItemFactory.items(
            from: inventory,
            wishes: wishes,
            selectedGroupID: selectedGroupID
        )
    }

    private func addConditionTag(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !selectedTagNames.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }),
              selectedTagNames.count < 5
        else {
            return
        }
        selectedTagNames.append(trimmed)
    }

    private func openGoogleLensSearch(_ itemID: GoodsGoogleLensSearchItem.ID) {
        guard let item = googleLensItems.first(where: { $0.id == itemID }),
              case let .imageURL(imageURL) = item.source,
              let lensURL = GoogleLensSearchURLBuilder.url(forImageURL: imageURL)
        else {
            googleLensErrorMessage = "Google Lensを開けませんでした。画像を選び直してください。"
            return
        }
        googleLensErrorMessage = nil
        #if os(iOS)
        googleLensBrowserRoute = MegrumInAppBrowserRoute(url: lensURL)
        #else
        openURL(lensURL)
        #endif
    }
}
