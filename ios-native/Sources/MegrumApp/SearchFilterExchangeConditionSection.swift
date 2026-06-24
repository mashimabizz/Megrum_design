import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

private func searchFilterDateText(_ date: Date) -> String {
    date.formatted(
        .dateTime
            .locale(Locale(identifier: "ja_JP"))
            .month()
            .day()
            .weekday(.abbreviated)
    )
}

private let searchFilterJapanesePrefectures = [
    "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県",
    "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県",
    "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県",
    "岐阜県", "静岡県", "愛知県", "三重県",
    "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県",
    "鳥取県", "島根県", "岡山県", "広島県", "山口県",
    "徳島県", "香川県", "愛媛県", "高知県",
    "福岡県", "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"
]

struct SearchExchangeConditionFilterSection: View {
    @Binding var selectedExchangeMethod: ExchangeMethod?
    @Binding var selectedPrefecture: String
    @Binding var placeMemo: String
    @Binding var selectedDates: [Date]
    @Binding var dateDraft: Date
    @Binding var isDatePickerExpanded: Bool
    @Binding var shippingFee: String
    @Binding var shippingWindow: String
    @Binding var allowsOutOfConditionProposal: Bool
    var isLocked: Bool
    var onAddDate: (Date) -> Void
    var onRemoveDate: (Date) -> Void

    var body: some View {
        Section {
            Picker("交換手段", selection: $selectedExchangeMethod) {
                Text("指定なし").tag(Optional<ExchangeMethod>.none)
                ForEach(ExchangeMethod.allCases) { method in
                    Text(method.displayName).tag(Optional(method))
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            Picker("都道府県", selection: $selectedPrefecture) {
                Text("指定なし").tag("")
                ForEach(searchFilterJapanesePrefectures, id: \.self) { prefecture in
                    Text(prefecture).tag(prefecture)
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            TextField("場所メモ", text: $placeMemo)

            DisclosureGroup(isExpanded: $isDatePickerExpanded) {
                DatePicker("日程を追加", selection: $dateDraft, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                Button("この日程を追加", systemImage: "calendar.badge.plus") {
                    onAddDate(dateDraft)
                }
                .font(.system(size: 16, weight: .heavy, design: .rounded))

                ForEach(selectedDates, id: \.self) { date in
                    HStack {
                        Text(searchFilterDateText(date))
                        Spacer()
                        Button {
                            onRemoveDate(date)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                    }
                }
            } label: {
                HStack {
                    Text("日程")
                    Spacer()
                    Text(selectedDates.isEmpty ? "指定なし" : "\(selectedDates.count)件")
                        .foregroundStyle(MegrumTheme.muted)
                }
            }

            Picker("送料", selection: $shippingFee) {
                Text("指定なし").tag("")
                ForEach(IndividualListingShippingFeeDraft.selectableCases) { option in
                    Text(option.title).tag(option.title)
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            Picker("発送目安", selection: $shippingWindow) {
                Text("指定なし").tag("")
                ForEach(IndividualListingShippingDaysDraft.allCases) { option in
                    Text(option.title).tag(option.title)
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            Toggle("条件外打診", isOn: $allowsOutOfConditionProposal)
                .tint(MegrumTheme.lavender)
        } header: {
            Label("交換条件", systemImage: "mappin.circle")
        }
        .disabled(isLocked)
    }
}
