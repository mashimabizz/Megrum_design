import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalMeetupConditionStep: View {
    @Binding var prefecture: String
    @Binding var placeMemo: String
    @Binding var scheduleDate: Date
    var viewerConditionText: String
    var partnerConditionText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProposalCardSection(title: "待ち合わせ") {
                VStack(spacing: 0) {
                    Picker("都道府県", selection: $prefecture) {
                        Text("未設定").tag("")
                        ForEach(OwnProfileEditValidation.japanPrefectures, id: \.self) { prefecture in
                            Text(prefecture).tag(prefecture)
                        }
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .padding(.vertical, ProposalMeetupConditionMetrics.rowVerticalPadding)
                    .frame(minHeight: ProposalMeetupConditionMetrics.rowMinHeight)
                    #if os(iOS)
                    .pickerStyle(.navigationLink)
                    #endif

                    Divider()

                    TextField("メモ（例：駅周辺、会場入口付近）", text: $placeMemo, axis: .vertical)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .lineLimit(1...3)
                        .padding(.vertical, 12)
                        .frame(minHeight: ProposalMeetupConditionMetrics.rowMinHeight)

                    Divider()

                    DatePicker(
                        "日程",
                        selection: $scheduleDate,
                        displayedComponents: [.date]
                    )
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .padding(.vertical, 10)
                    .frame(minHeight: ProposalMeetupConditionMetrics.rowMinHeight)
                }
                .padding(.horizontal, 14)
                .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
                }
            }

            ProposalMutualConditionCard(
                title: "お互いの希望条件",
                rows: [
                    ProposalMutualConditionRowData(label: "自分", value: viewerConditionText),
                    ProposalMutualConditionRowData(label: "相手", value: partnerConditionText)
                ]
            )
        }
    }
}

struct ProposalShippingConditionStep: View {
    @Binding var shippingFee: IndividualListingShippingFeeDraft
    @Binding var shippingDays: IndividualListingShippingDaysDraft
    var viewerConditionText: String
    var partnerConditionText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProposalCardSection(title: "送料") {
                VStack(spacing: 18) {
                    ProposalConditionSegmentRow(
                        title: "送料",
                        selection: $shippingFee,
                        values: IndividualListingShippingFeeDraft.selectableCases
                    )

                    Divider()

                    ProposalConditionSegmentRow(
                        title: "発送目安",
                        selection: $shippingDays,
                        values: IndividualListingShippingDaysDraft.allCases
                    )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
                }
            }

            ProposalMutualConditionCard(
                title: "お互いの希望条件",
                rows: [
                    ProposalMutualConditionRowData(label: "自分", value: viewerConditionText),
                    ProposalMutualConditionRowData(label: "相手", value: partnerConditionText)
                ]
            )
        }
    }
}

struct ProposalMutualConditionRowData: Equatable {
    var label: String
    var value: String
}

struct ProposalMutualConditionCard: View {
    var title: String
    var rows: [ProposalMutualConditionRowData]

    var body: some View {
        ProposalCardSection(title: title) {
            VStack(spacing: 9) {
                ForEach(rows, id: \.label) { row in
                    HStack(alignment: .top, spacing: 12) {
                        Text(row.label)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                            .frame(width: 38, alignment: .leading)
                        Text(row.value)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(11)
                    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}

private struct ProposalConditionSegmentRow<Value: Identifiable & Equatable>: View where Value.ID == String {
    var title: String
    @Binding var selection: Value
    var values: [Value]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 7) {
                ForEach(values) { value in
                    Button {
                        selection = value
                    } label: {
                        Text(segmentTitle(for: value))
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .foregroundStyle(selection == value ? .white : MegrumTheme.ink.opacity(0.62))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                selection == value ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.05),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == value ? .isSelected : [])
                }
            }
        }
    }

    private func segmentTitle(for value: Value) -> String {
        if let shippingFee = value as? IndividualListingShippingFeeDraft {
            return shippingFee.title
        }
        if let shippingDays = value as? IndividualListingShippingDaysDraft {
            return shippingDays.title
        }
        return value.id
    }
}
