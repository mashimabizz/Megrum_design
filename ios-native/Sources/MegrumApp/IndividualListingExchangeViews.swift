import MegrumDesign
import SwiftUI

struct IndividualListingExchangeStep: View {
    @Binding var handoffMethod: IndividualListingHandoffDraft
    @Binding var localPrefecture: String
    @Binding var localPlaceMemo: String
    @Binding var localSchedule: String
    @Binding var shippingFee: IndividualListingShippingFeeDraft
    @Binding var shippingDays: IndividualListingShippingDaysDraft
    @Binding var acceptsOutsideCondition: Bool
    @Binding var note: String

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
                            VStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill((method == .mail ? MegrumTheme.pink : MegrumTheme.lavender).opacity(0.12))
                                        .frame(width: 56, height: 56)
                                    if method == .both {
                                        HStack(spacing: -5) {
                                            Image(systemName: IndividualListingHandoffDraft.local.symbolName)
                                            Image(systemName: "envelope")
                                        }
                                        .font(.system(size: 23, weight: .bold))
                                    } else {
                                        Image(systemName: method.symbolName)
                                            .font(.system(size: 27, weight: .bold))
                                    }
                                }
                                .foregroundStyle(method == .mail ? MegrumTheme.pink : MegrumTheme.lavender)

                                Text(exchangeMethodButtonTitle(for: method))
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundStyle(method == handoffMethod ? MegrumTheme.lavender : MegrumTheme.ink)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.92)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 108)
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

            if handoffMethod == .local || handoffMethod == .both {
                VStack(alignment: .leading, spacing: 14) {
                    Text("2. 現地交換の条件")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    VStack(spacing: 0) {
                        IndividualListingPrefecturePickerRow(localPrefecture: $localPrefecture)
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
                        IndividualListingLocalScheduleField(localSchedule: $localSchedule)
                    }
                    .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
                    }
                }
            }

            if handoffMethod == .mail || handoffMethod == .both {
                VStack(alignment: .leading, spacing: 14) {
                    Text("3. 郵送交換の条件")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    VStack(spacing: 18) {
                        IndividualListingSegmentRow(
                            title: "送料",
                            selection: $shippingFee,
                            values: IndividualListingShippingFeeDraft.selectableCases
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

            VStack(alignment: .leading, spacing: 14) {
                Text("5. その他要望など")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                VStack(alignment: .leading, spacing: 8) {
                    TextField("例：条件外でも写真を見て相談したいです", text: $note, axis: .vertical)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(3...6)

                    Text("一覧やマッチ候補の詳細に小さく表示されます。")
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                .padding(16)
                .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
                }
            }
        }
    }

    private func exchangeMethodButtonTitle(for method: IndividualListingHandoffDraft) -> String {
        switch method {
        case .both:
            "現地交換・\n郵送OK"
        case .local, .mail:
            method.title
        }
    }
}
