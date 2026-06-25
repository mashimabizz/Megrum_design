import MegrumDesign
import SwiftUI

struct HomeExchangeCalendarHeader: View {
    let monthTitle: String
    @Binding var selectedPrefecture: String
    var onPreviousMonth: () -> Void
    var onNextMonth: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(monthTitle)
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .frame(minWidth: 34, alignment: .leading)

            Button("前の月", systemImage: "chevron.left", action: onPreviousMonth)
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .frame(width: 32, height: 32)
                .background(MegrumTheme.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))

            Button("次の月", systemImage: "chevron.right", action: onNextMonth)
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .frame(width: 32, height: 32)
                .background(MegrumTheme.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))

            Spacer(minLength: 4)

            HomeExchangePrefectureMenu(selection: $selectedPrefecture)
                .frame(width: 118)
        }
    }
}

struct HomeExchangeCalendarLegend: View {
    var entries: [HomeExchangeCalendarLegendEntry]

    @ViewBuilder
    var body: some View {
        if !entries.isEmpty {
            HStack(spacing: 14) {
                ForEach(entries) { entry in
                    Label {
                        Text(entry.title)
                    } icon: {
                        Circle()
                            .fill(entry.color)
                            .frame(width: 10, height: 10)
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MegrumTheme.muted)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

private struct HomeExchangePrefectureMenu: View {
    @Binding var selection: String

    var body: some View {
        Menu {
            Button("未設定") {
                selection = ""
            }
            ForEach(JapanesePrefectureCatalog.all, id: \.self) { prefecture in
                Button(prefecture) {
                    selection = prefecture
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text("既定")
                    .foregroundStyle(MegrumTheme.lavender)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Text(displayPrefecture)
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .layoutPriority(1)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MegrumTheme.lavender)
                    .fixedSize()
            }
            .font(.caption.weight(.black))
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(Color.white.opacity(0.82), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(MegrumTheme.lavender.opacity(0.34), lineWidth: 1.2)
            }
        }
        .accessibilityLabel("デフォルトの都道府県、\(selection.nilIfBlank ?? "未設定")")
    }

    private var displayPrefecture: String {
        guard let selection = selection.nilIfBlank else {
            return "未設定"
        }
        return HomeExchangePrefecturePresentation.shortName(selection)
    }
}
