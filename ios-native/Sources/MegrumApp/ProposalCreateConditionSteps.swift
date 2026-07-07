import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalMeetupConditionStep: View {
    @Binding var prefecture: String
    @Binding var placeMemo: String
    @Binding var scheduleDate: Date
    var viewerConditionText: String
    var partnerConditionText: String
    var onOpenViewerCalendar: (() -> Void)?
    var onOpenPartnerCalendar: (() -> Void)?

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
                ],
                onViewerDetail: onOpenViewerCalendar,
                onPartnerDetail: onOpenPartnerCalendar
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
    /// 「自分」行の右端の「＞」から開く詳細（自分の交換カレンダー）。
    var onViewerDetail: (() -> Void)?
    /// 「相手」行の右端の「＞」から開く詳細（相手の交換カレンダー）。
    var onPartnerDetail: (() -> Void)?

    var body: some View {
        ProposalCardSection(title: title) {
            VStack(spacing: 9) {
                ForEach(rows, id: \.label) { row in
                    rowView(row)
                }
            }
        }
    }

    /// 各行の「＞」で開く詳細アクション（自分＝onViewerDetail / 相手＝onPartnerDetail）。
    private func detailAction(for row: ProposalMutualConditionRowData) -> (() -> Void)? {
        switch row.label {
        case "自分": return onViewerDetail
        case "相手": return onPartnerDetail
        default: return nil
        }
    }

    @ViewBuilder
    private func rowView(_ row: ProposalMutualConditionRowData) -> some View {
        let action = detailAction(for: row)
        let content = HStack(alignment: .top, spacing: 12) {
            Text(row.label)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 38, alignment: .leading)
            Text(row.value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .padding(11)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

        if let action {
            Button {
                MegrumHaptics.performButtonTap(action)
            } label: {
                content
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(row.label)の現地交換カレンダーを開く")
        } else {
            content
        }
    }
}


/// 個別募集エディタ準拠のステップ大見出し。
struct ProposalStepProgressTitle: View {
    var step: ProposalCreateStep

    var body: some View {
        Text(titleText)
            .font(.system(size: step == .conditions ? 27 : 29, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleText: String {
        switch step {
        case .give: "譲るものを選ぶ"
        case .receive: "受け取るものを選ぶ"
        default: "交換条件を設定する"
        }
    }
}

/// 個別募集エディタと同じ進捗ピル（「1 /3」＋ドット3つ）。
struct ProposalStepProgressPill: View {
    var step: ProposalCreateStep
    var onSelectStep: (ProposalCreateStep) -> Void

    private static let steps: [ProposalCreateStep] = [.give, .receive, .conditions]

    var body: some View {
        HStack(spacing: 12) {
            Text("\(stepNumber)")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("/3")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            ForEach(Self.steps, id: \.id) { item in
                Button {
                    onSelectStep(item)
                } label: {
                    Color.clear
                        .frame(width: 22, height: 22)
                        .overlay {
                            Circle()
                                .fill(item == step ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.22))
                                .frame(width: item == step ? 16 : 9, height: item == step ? 16 : 9)
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 40)
        .background(.white.opacity(0.92), in: Capsule())
        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 10, y: 4)
    }

    private var stepNumber: Int {
        switch step {
        case .give: 1
        case .receive: 2
        default: 3
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
                ProposalExchangeMethodCards(exchangeMethod: $exchangeMethod)
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


/// 個別募集の作成画面と同じ交換手段カード（アイコン丸＋選択枠、iter1226.347）。
struct ProposalExchangeMethodCards: View {
    @Binding var exchangeMethod: ExchangeMethod

    private static let methods: [ExchangeMethod] = [.hand, .mail, .both]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Self.methods, id: \.self) { method in
                Button {
                    exchangeMethod = method
                } label: {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill((method == .mail ? MegrumTheme.pink : MegrumTheme.lavender).opacity(0.12))
                                .frame(width: 56, height: 56)
                            if method == .both {
                                HStack(spacing: -5) {
                                    Image(systemName: "hand.raised")
                                    Image(systemName: "envelope")
                                }
                                .font(.system(size: 23, weight: .bold))
                            } else {
                                Image(systemName: method == .mail ? "envelope" : "hand.raised")
                                    .font(.system(size: 27, weight: .bold))
                            }
                        }
                        .foregroundStyle(method == .mail ? MegrumTheme.pink : MegrumTheme.lavender)

                        Text(buttonTitle(for: method))
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(method == exchangeMethod ? MegrumTheme.lavender : MegrumTheme.ink)
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
                            .stroke(
                                method == exchangeMethod ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.10),
                                lineWidth: method == exchangeMethod ? 1.6 : 1
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func buttonTitle(for method: ExchangeMethod) -> String {
        switch method {
        case .hand:
            "現地交換"
        case .mail:
            "郵送交換"
        case .both:
            "現地交換・\n郵送OK"
        }
    }
}
