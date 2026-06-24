import MegrumDesign
import SwiftUI

struct IndividualListingPrefecturePickerRow: View {
    @Binding var localPrefecture: String

    var body: some View {
        Menu {
            Picker("都道府県", selection: $localPrefecture) {
                ForEach(OwnProfileEditValidation.japanPrefectures, id: \.self) { prefecture in
                    Text(prefecture).tag(prefecture)
                }
            }
        } label: {
            IndividualListingFormValueRow(
                title: "都道府県",
                value: displayPrefecture,
                showsChevron: true
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("都道府県を選択")
    }

    private var displayPrefecture: String {
        let trimmed = localPrefecture.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未設定" : trimmed
    }
}

struct IndividualListingSegmentRow<Value: Identifiable & Equatable>: View where Value.ID == String {
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
