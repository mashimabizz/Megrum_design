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


/// 個別募集エディタ準拠のステップ大見出し（1/3〜3/3）。
struct ProposalStepProgressTitle: View {
    var step: ProposalCreateStep

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(progressText)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
            Text(titleText)
                .font(.system(size: step == .conditions ? 27 : 29, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressText: String {
        switch step {
        case .give: "1/3"
        case .receive: "2/3"
        default: "3/3"
        }
    }

    private var titleText: String {
        switch step {
        case .give: "譲るものを選ぶ"
        case .receive: "受け取るものを選ぶ"
        default: "交換条件を設定する"
        }
    }
}

/// 3/3 交換条件：交換手段・現地・郵送・支払をひとつのステップにまとめる。
/// 各セクションの下に「お互いの希望条件」（現地/郵送の各サブビューが内包）を表示する。
struct ProposalExchangeConditionsStep<MeetupContent: View, ShippingContent: View, PaymentContent: View>: View {
    @Binding var exchangeMethod: ExchangeMethod
    var requiresPaymentSelection: Bool
    @ViewBuilder var meetupContent: () -> MeetupContent
    @ViewBuilder var shippingContent: () -> ShippingContent
    @ViewBuilder var paymentContent: () -> PaymentContent

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("1. 交換手段")
                ProposalExchangeMethodSelector(exchangeMethod: $exchangeMethod)
            }

            if exchangeMethod == .hand || exchangeMethod == .both {
                VStack(alignment: .leading, spacing: 14) {
                    sectionTitle("\(localSectionNumber). 現地交換の条件")
                    meetupContent()
                }
            }

            if exchangeMethod == .mail || exchangeMethod == .both {
                VStack(alignment: .leading, spacing: 14) {
                    sectionTitle("\(mailSectionNumber). 郵送交換の条件")
                    shippingContent()
                }
            }

            if requiresPaymentSelection {
                VStack(alignment: .leading, spacing: 14) {
                    sectionTitle("\(paymentSectionNumber). 支払方法")
                    paymentContent()
                }
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
    }

    private var localSectionNumber: Int { 2 }

    private var mailSectionNumber: Int {
        exchangeMethod == .both ? 3 : 2
    }

    private var paymentSectionNumber: Int {
        var number = 2
        if exchangeMethod == .hand || exchangeMethod == .both {
            number += 1
        }
        if exchangeMethod == .mail || exchangeMethod == .both {
            number += 1
        }
        return number
    }
}
