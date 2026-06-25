import MegrumDesign
import SwiftUI

#if DEBUG
struct MeguriTabBar: View {
    var mode: MeguriHomeSheetMode

    private var items: [(String, String, Bool)] {
        switch mode {
        case .normal:
            [
                ("house", "ホーム", false),
                ("magnifyingglass", "さがす", false),
                ("plus", "出品", false),
                ("mappin.and.ellipse", "めぐり", true),
                ("person", "マイページ", false)
            ]
        case .expanded:
            [
                ("house", "ホーム", false),
                ("magnifyingglass", "さがす", false),
                ("person.3.fill", "めぐり", true),
                ("bell", "お知らせ", false),
                ("person", "マイページ", false)
            ]
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                MeguriTabItem(systemName: item.0, title: item.1, isSelected: item.2, isCenterAdd: item.0 == "plus")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .frame(height: MeguriDesignMetrics.tabBarHeight)
        .background(.white.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MeguriDesignColors.border)
                .frame(height: 1)
        }
    }
}

struct MeguriTabItem: View {
    var systemName: String
    var title: String
    var isSelected: Bool
    var isCenterAdd: Bool

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemName)
                .font(.system(size: isCenterAdd ? 22 : 20, weight: .medium, design: .rounded))
                .foregroundStyle(isCenterAdd ? .white : (isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.72)))
                .frame(width: isCenterAdd ? 40 : 32, height: isCenterAdd ? 40 : 28)
                .background {
                    if isCenterAdd {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(MegrumTheme.lavender)
                    } else if isSelected {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(MegrumTheme.lavender.opacity(0.10))
                            .frame(width: 64, height: 52)
                    }
                }

            Text(title)
                .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.70))
        }
    }
}
#endif
