import MegrumDesign
import SwiftUI

struct IndividualListingExchangeStep: View {
    @Binding var handoffMethod: IndividualListingHandoffDraft
    var localPrefecture: String
    @Binding var localPlaceMemo: String
    @Binding var shippingFee: IndividualListingShippingFeeDraft
    @Binding var shippingDays: IndividualListingShippingDaysDraft
    @Binding var acceptsOutsideCondition: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            IndividualListingStepTitle(step: .exchange)

            VStack(alignment: .leading, spacing: 20) {
                Text("1. 交換手段")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                HStack(spacing: 12) {
                    ForEach(IndividualListingHandoffDraft.allCases) { method in
                        Button {
                            handoffMethod = method
                        } label: {
                            VStack(spacing: 15) {
                                ZStack {
                                    Circle()
                                        .fill((method == .mail ? MegrumTheme.pink : MegrumTheme.lavender).opacity(0.12))
                                        .frame(width: 58, height: 58)
                                    if method == .both {
                                        HStack(spacing: -6) {
                                            Image(systemName: "mappin")
                                            Image(systemName: "envelope")
                                        }
                                        .font(.system(size: 25, weight: .bold))
                                    } else {
                                        Image(systemName: method.symbolName)
                                            .font(.system(size: 28, weight: .bold))
                                    }
                                }
                                .foregroundStyle(method == .mail ? MegrumTheme.pink : MegrumTheme.lavender)

                                Text(method.title)
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundStyle(method == handoffMethod ? MegrumTheme.lavender : MegrumTheme.ink)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 102)
                            .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(method == handoffMethod ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.10), lineWidth: method == handoffMethod ? 1.6 : 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("2. 現地交換の条件")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                VStack(spacing: 0) {
                    IndividualListingFormValueRow(title: "都道府県", value: localPrefecture, showsChevron: true)
                    Divider().padding(.leading, 16)
                    HStack {
                        Text("場所メモ（任意）")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                        Spacer()
                        TextField("例：会場周辺、駅周辺なら可", text: $localPlaceMemo)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(MegrumTheme.ink)
                    }
                    .frame(height: 58)
                    .padding(.horizontal, 16)
                    Divider().padding(.leading, 16)
                    IndividualListingFormValueRow(title: "日程", value: "相談して決める", showsChevron: true)
                }
                .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("3. 郵送交換の条件")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                VStack(spacing: 18) {
                    IndividualListingSegmentRow(
                        title: "送料",
                        selection: $shippingFee,
                        values: IndividualListingShippingFeeDraft.allCases
                    )
                    Divider()
                    IndividualListingSegmentRow(
                        title: "発送目安",
                        selection: $shippingDays,
                        values: IndividualListingShippingDaysDraft.allCases
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("4. 条件外の打診について")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Toggle(isOn: $acceptsOutsideCondition) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("条件外の打診も受け付ける")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                        Text("近い条件なら相談できます")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                }
                .tint(MegrumTheme.lavender)
                .padding(16)
                .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
}

struct IndividualListingStepTitle: View {
    var step: IndividualListingEditorStep

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(step.title)
                .font(.system(size: step == .exchange ? 30 : 32, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text(step.subtitle)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct IndividualListingFormValueRow: View {
    var title: String
    var value: String
    var showsChevron: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
    }
}

private struct IndividualListingSegmentRow<Value: Identifiable & Equatable>: View where Value.ID == String {
    var title: String
    @Binding var selection: Value
    var values: [Value]

    var body: some View {
        HStack(spacing: 14) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(width: 74, alignment: .leading)
            HStack(spacing: 0) {
                ForEach(values) { value in
                    Button {
                        selection = value
                    } label: {
                        Text(title(for: value))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(selection == value ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.78))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity)
                            .frame(height: 43)
                            .background {
                                if selection == value {
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .stroke(MegrumTheme.lavender, lineWidth: 1.2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(MegrumTheme.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func title(for value: Value) -> String {
        if let fee = value as? IndividualListingShippingFeeDraft {
            return fee.title
        }
        if let days = value as? IndividualListingShippingDaysDraft {
            return days.title
        }
        return value.id
    }
}
