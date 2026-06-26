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
                ForEach(JapanesePrefectureCatalog.all, id: \.self) { prefecture in
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
