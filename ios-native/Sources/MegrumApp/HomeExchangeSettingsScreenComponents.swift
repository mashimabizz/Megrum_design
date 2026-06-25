import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeExchangeSettingsBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                MegrumTheme.canvas,
                MegrumTheme.lavender.opacity(0.12),
                Color.white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct HomeExchangeSettingsHeader: View {
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Text("交換条件")
                .font(.title2.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .frame(maxWidth: .infinity)

            HStack {
                Button("閉じる", action: onClose)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MegrumTheme.ink)
                    .padding(.horizontal, 17)
                    .frame(minHeight: 44)
                    .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
                    .shadow(color: MegrumTheme.lavender.opacity(0.10), radius: 16, y: 8)

                Spacer(minLength: 0)
            }
        }
    }
}

struct HomeExchangeMailConditionsCard: View {
    @Binding var shippingFee: IndividualListingShippingFeeDraft
    @Binding var shippingDays: IndividualListingShippingDaysDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("郵送交換の条件")
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.horizontal, 8)

            VStack(spacing: 14) {
                HomeExchangeMailConditionSegmentRow(
                    title: "送料の負担",
                    selection: $shippingFee,
                    values: IndividualListingShippingFeeDraft.selectableCases
                )
                Divider().overlay(MegrumTheme.ink.opacity(0.08))
                HomeExchangeMailConditionSegmentRow(
                    title: "発送目安",
                    selection: $shippingDays,
                    values: IndividualListingShippingDaysDraft.allCases
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.92), lineWidth: 1)
            }
            .shadow(color: MegrumTheme.lavender.opacity(0.09), radius: 18, y: 10)
        }
    }
}

private struct HomeExchangeMailConditionSegmentRow<Value: Identifiable & Equatable>: View where Value.ID == String {
    var title: String
    @Binding var selection: Value
    var values: [Value]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 7) {
                ForEach(values) { value in
                    Button {
                        selection = value
                    } label: {
                        Text(segmentTitle(for: value))
                            .font(.caption.weight(.black))
                            .foregroundStyle(selection == value ? .white : MegrumTheme.ink.opacity(0.68))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
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

struct HomeExchangeSettingsInstructionBanner: View {
    var body: some View {
        Label {
            Text("日付タップで場所とメモ、横ドラッグで複数日程を追加できます")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(MegrumTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "hand.tap.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(MegrumTheme.lavender)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(Color.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(MegrumTheme.lavender.opacity(0.14), lineWidth: 1)
        }
    }
}

struct HomeExchangeSettingsSaveFooter: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("保存")
                .font(.title3.weight(.black))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.lavender.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .shadow(color: MegrumTheme.lavender.opacity(0.28), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }
}

extension View {
    @ViewBuilder
    func homeExchangeSettingsNavigationBarHidden() -> some View {
        #if os(iOS)
        toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }
}
