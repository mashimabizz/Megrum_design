import MegrumDesign
import SwiftUI

struct HomeSheetTitle: View {
    var icon: String
    var title: String
    var subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(subtitle)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }
}

struct HomeSheetSectionTitle: View {
    var systemName: String
    var title: String
    var subtitle: String?
    var trailing: String?

    init(systemName: String, title: String, subtitle: String? = nil, trailing: String? = nil) {
        self.systemName = systemName
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                HStack(spacing: 9) {
                    Image(systemName: systemName)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                    Text(title)
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                }
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }
}
