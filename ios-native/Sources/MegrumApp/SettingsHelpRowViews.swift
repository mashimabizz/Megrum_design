import MegrumDesign
import SwiftUI

struct HelpDetailText: View {
    var message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        Text(message)
            .font(.body)
            .foregroundStyle(MegrumTheme.ink)
            .padding(.vertical, 4)
    }
}

struct HelpDetailRow: View {
    var title: String
    var message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(MegrumTheme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct HelpRouteRow: View {
    var iconName: String
    var title: String
    var message: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MegrumTheme.ink)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(MegrumTheme.muted)
            }
            .padding(.vertical, 3)
        } icon: {
            Image(systemName: iconName)
                .foregroundStyle(MegrumTheme.lavender)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(message)
    }
}
