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

struct IndividualListingLogicSelector: View {
    @Binding var selection: ListingLogic

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("条件の扱い")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 0) {
                logicButton(.one)
                logicButton(.all)
            }
            .padding(3)
            .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private func logicButton(_ logic: ListingLogic) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.2)) {
                selection = logic
            }
        } label: {
            Text(logic.displayName)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(selection == logic ? .white : MegrumTheme.ink.opacity(0.72))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background {
                    if selection == logic {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(MegrumTheme.lavender)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

struct IndividualListingEditorStatusSection: View {
    @Binding var status: IndividualListingStatus

    var body: some View {
        Picker("公開状態", selection: $status) {
            ForEach([IndividualListingStatus.active, .paused, .closed]) { status in
                Text(status.displayName).tag(status)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct IndividualListingEditorContent: View {
    @Binding var draft: IndividualListingDraft
    var step: IndividualListingEditorStep
    var inventory: [GoodsItem]
    var wishes: [WishItem]
    var groups: [OshiGroup]
    var goodsTypes: [GoodsType]
    var stepValidationMessage: String?
    var onBack: () -> Void
    var onCash: () -> Void
    var onToggleHave: (GoodsItem) -> Void
    var onToggleWish: (WishItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            IndividualListingEditorHeader(
                step: step,
                title: draft.navigationTitle,
                onBack: onBack
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    stepContent

                    if draft.mode.isEditing {
                        IndividualListingEditorStatusSection(status: $draft.status)
                    }

                    if let stepValidationMessage {
                        Text(stepValidationMessage)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
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
                haveLogic: $draft.haveLogic,
                onCash: onCash,
                onToggle: onToggleHave
            )
        case .options:
            IndividualListingOptionsStep(
                optionKind: Binding(
                    get: { draft.optionKind },
                    set: { draft.setOptionKind($0) }
                ),
                wishes: wishes,
                selectedWishIDs: draft.selectedWishIDs,
                selectedWishLogic: $draft.wishLogic,
                groups: groups,
                goodsTypes: goodsTypes,
                selectedConditionGroupID: $draft.conditionGroupID,
                selectedConditionGoodsTypeID: $draft.conditionGoodsTypeID,
                cashAmount: $draft.cashAmount,
                note: $draft.note,
                onToggleWish: onToggleWish
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
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(title)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }

            HStack(spacing: 14) {
                if step == .exchange {
                    ForEach(IndividualListingEditorStep.allCases) { item in
                        Circle()
                            .fill(item.rawValue <= step.rawValue ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.22))
                            .frame(width: item == step ? 24 : 13, height: item == step ? 24 : 13)
                            .overlay(alignment: .center) {
                                if item.rawValue < step.rawValue {
                                    Circle()
                                        .fill(MegrumTheme.lavender.opacity(0.45))
                                        .frame(width: 13, height: 13)
                                }
                            }
                    }
                    Text("\(step.rawValue)/3")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.72))
                } else {
                    Text("\(step.rawValue)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text("/3")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    ForEach(IndividualListingEditorStep.allCases.filter { $0 != .haves }, id: \.id) { item in
                        Circle()
                            .fill(item == step ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.22))
                            .frame(width: item == step ? 18 : 10, height: item == step ? 18 : 10)
                    }
                }
            }
            .padding(.horizontal, 24)
            .frame(height: step == .exchange ? 36 : 52)
            .background(.white.opacity(0.92), in: Capsule())
            .shadow(color: MegrumTheme.ink.opacity(0.10), radius: 12, y: 5)
        }
        .padding(.horizontal, 24)
        .padding(.top, 25)
        .padding(.bottom, 10)
    }
}

struct IndividualListingEditorBottomBar: View {
    var step: IndividualListingEditorStep
    var selectedCount: Int
    var isDisabled: Bool
    var isSaving: Bool
    var onBack: () -> Void
    var onPrimary: () -> Void

    var body: some View {
        VStack(spacing: 13) {
            if step == .haves {
                HStack(spacing: 14) {
                    Text("選択中")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text("\(selectedCount)件")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                    Spacer()
                    HStack(spacing: 0) {
                        Text("どれか1つだけ")
                            .foregroundStyle(.white)
                            .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                        Text("すべて譲る")
                            .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(width: 234, height: 42)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
                    }
                }
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
            } else {
                primaryButton(title: step == .haves ? "この内容で次へ" : "交換条件へ進む")
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial)
    }

    private func primaryButton(title: String) -> some View {
        Button(action: onPrimary) {
            Group {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
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
}
