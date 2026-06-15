import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ListingSelectableImageTile: View {
    var imageURL: URL?
    var title: String
    var isSelected: Bool

    var body: some View {
        ListingGoodsImage(url: imageURL, title: title, cornerRadius: 13)
            .aspectRatio(0.78, contentMode: .fit)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(MegrumTheme.lavender, in: Circle())
                    .overlay {
                        Circle().stroke(.white, lineWidth: 2)
                    }
                    .opacity(isSelected ? 1 : 0)
                    .padding(8)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(MegrumTheme.lavender, lineWidth: 2.5)
                }
            }
    }
}

struct IndividualListingEditorContent: View {
    @Binding var draft: IndividualListingDraft
    @Binding var havesTab: IndividualListingHavesStep.Tab
    var step: IndividualListingEditorStep
    var inventory: [GoodsItem]
    var wishes: [WishItem]
    var genres: [OshiGenre]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    var stepValidationMessage: String?
    var optionReviewCount: Int
    var onBack: () -> Void
    var onShowOptionReview: () -> Void
    var onToggleHave: (GoodsItem) -> Void
    var onToggleWish: (WishItem) -> Void
    var onLoadCharacters: (OshiGroup) -> Void
    var onCreateOshiRequest: (OshiRequestSheetPayload) -> Void

    var body: some View {
        VStack(spacing: 0) {
            IndividualListingEditorHeader(
                step: step,
                title: draft.navigationTitle,
                showsOptionReviewButton: step == .options,
                optionReviewCount: optionReviewCount,
                onShowOptionReview: onShowOptionReview,
                onBack: onBack
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    stepContent

                    if let stepValidationMessage {
                        Text(stepValidationMessage)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 126)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .haves:
            IndividualListingHavesStep(
                inventory: inventory,
                selectedIDs: draft.selectedHaveIDs,
                selectedTab: $havesTab,
                cashAmount: $draft.cashAmount,
                onToggle: onToggleHave
            )
        case .options:
            IndividualListingOptionsStep(
                optionKind: Binding(
                    get: { draft.optionKind },
                    set: { draft.setOptionKind($0) }
                ),
                inventory: inventory,
                wishes: wishes,
                selectedWishIDs: draft.selectedWishIDs,
                selectedWishLogic: $draft.wishLogic,
                genres: genres,
                groups: groups,
                characters: characters,
                goodsTypes: goodsTypes,
                selectedConditionGroupID: Binding(
                    get: { draft.conditionGroupID },
                    set: { draft.setConditionGroupID($0) }
                ),
                selectedConditionMemberIDs: $draft.conditionMemberIDs,
                excludesSelectedConditionMembers: Binding(
                    get: { draft.excludesSelectedConditionMembers },
                    set: { draft.setExcludesSelectedConditionMembers($0) }
                ),
                selectedConditionGoodsTypeID: $draft.conditionGoodsTypeID,
                selectedConditionTagNames: $draft.conditionTagNames,
                conditionQuantity: $draft.conditionQuantity,
                cashAmount: $draft.cashAmount,
                onToggleWish: onToggleWish,
                onToggleConditionMember: { draft.toggleConditionMember($0) },
                onToggleConditionTag: { draft.toggleConditionTag($0) },
                onLoadCharacters: onLoadCharacters,
                onCreateOshiRequest: onCreateOshiRequest
            )
        case .exchange:
            IndividualListingExchangeStep(
                handoffMethod: $draft.handoffMethod,
                localPrefecture: draft.localPrefecture,
                localPlaceMemo: $draft.localPlaceMemo,
                shippingFee: $draft.shippingFee,
                shippingDays: $draft.shippingDays,
                acceptsOutsideCondition: $draft.acceptsOutsideCondition
            )
        }
    }
}

struct IndividualListingEditorHeader: View {
    var step: IndividualListingEditorStep
    var title: String
    var showsOptionReviewButton: Bool
    var optionReviewCount: Int
    var onShowOptionReview: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                if showsOptionReviewButton {
                    Button(action: onShowOptionReview) {
                        HStack(spacing: 4) {
                            Text("選択肢を確認")
                            if optionReviewCount > 0 {
                                Text("\(optionReviewCount)")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 18, minHeight: 18)
                                    .background(MegrumTheme.lavender, in: Circle())
                            }
                        }
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .padding(.horizontal, 10)
                        .frame(height: 34)
                        .background(.white.opacity(0.92), in: Capsule())
                        .overlay {
                            Capsule()
                                .strokeBorder(MegrumTheme.lavender.opacity(0.22), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            HStack(spacing: 12) {
                Text("\(step.rawValue)")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text("/3")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                ForEach(IndividualListingEditorStep.allCases, id: \.id) { item in
                    Circle()
                        .fill(item == step ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.22))
                        .frame(width: item == step ? 16 : 9, height: item == step ? 16 : 9)
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 40)
            .background(.white.opacity(0.92), in: Capsule())
            .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 10, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

struct IndividualListingOptionReviewItem: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var kind: String
    var detail: String
}

struct IndividualListingOptionReviewSheet: View {
    var items: [IndividualListingOptionReviewItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if items.isEmpty {
                        Text("追加済みの選択肢はまだありません")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        ForEach(items) { item in
                            IndividualListingOptionReviewRow(item: item)
                        }
                    }
                }
                .padding(20)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle("選択肢を確認")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
    }
}

private struct IndividualListingOptionReviewRow: View {
    var item: IndividualListingOptionReviewItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(item.title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(item.kind)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 9)
                    .frame(height: 24)
                    .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
                Spacer()
            }

            Text(item.detail)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }
}

struct IndividualListingEditorBottomBar: View {
    var step: IndividualListingEditorStep
    var havesTab: IndividualListingHavesStep.Tab
    var optionKind: IndividualListingOptionKind
    var selectedHaveCount: Int
    var selectedWishCount: Int
    var stagedOptionCount: Int
    @Binding var haveLogic: ListingLogic
    @Binding var wishLogic: ListingLogic
    var usesConditionLogicChoice: Bool
    var isDisabled: Bool
    var isSaving: Bool
    var onBack: () -> Void
    var onAddOption: () -> Void
    var onPrimary: () -> Void

    var body: some View {
        VStack(spacing: 13) {
            if showsLogicControls {
                logicControlRow
            }

            if step == .exchange {
                HStack(spacing: 15) {
                    Button("戻る", action: onBack)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 132, height: 58)
                        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(MegrumTheme.lavender, lineWidth: 1.2)
                        }

                    primaryButton(title: "保存する")
                }
            } else if step == .options {
                HStack(spacing: 10) {
                    secondaryAddOptionButton
                    primaryButton(title: "交換条件へ進む")
                }
            } else {
                primaryButton(title: step == .haves ? "この内容で次へ" : "交換条件へ進む")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22, style: .continuous)
                .fill(.white.opacity(0.92))
                .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 18, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var showsLogicControls: Bool {
        if step == .haves {
            return havesTab == .goods
        }
        if step == .options {
            return optionKind == .wish || (optionKind == .condition && usesConditionLogicChoice)
        }
        return false
    }

    private var logicControlRow: some View {
        HStack(spacing: 14) {
            Text("選択中")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("\(displayedSelectedCount)件")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
            Spacer(minLength: 10)
            IndividualListingFooterLogicSegment(
                selection: logicBinding,
                allTitle: step == .haves ? "すべて譲る" : (optionKind == .condition ? "全部ほしい" : "すべて希望")
            )
            .frame(width: 248)
        }
    }

    private var displayedSelectedCount: Int {
        step == .haves ? selectedHaveCount : selectedWishCount
    }

    private var logicBinding: Binding<ListingLogic> {
        step == .haves ? $haveLogic : $wishLogic
    }

    private func primaryButton(title: String) -> some View {
        Button(action: onPrimary) {
            Group {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [MegrumTheme.lavender, MegrumTheme.sky],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.46 : 1)
    }

    private var secondaryAddOptionButton: some View {
        Button(action: onAddOption) {
            Text(stagedOptionCount == 0 ? "選択肢を追加" : "追加済み\(stagedOptionCount)件")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(width: 136, height: 56)
                .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.42), lineWidth: 1.2)
                }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.46 : 1)
    }
}

private struct IndividualListingFooterLogicSegment: View {
    @Binding var selection: ListingLogic
    var allTitle: String

    var body: some View {
        HStack(spacing: 0) {
            logicButton(.one, title: "どれか1つだけ")
            logicButton(.all, title: allTitle)
        }
        .padding(3)
        .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
        }
    }

    private func logicButton(_ logic: ListingLogic, title: String) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.18)) {
                selection = logic
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(selection == logic ? .white : MegrumTheme.ink.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background {
                    if selection == logic {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(MegrumTheme.lavender)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
