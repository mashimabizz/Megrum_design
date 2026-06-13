import MegrumDesign
import SwiftUI

struct GoodsEditorSectionContainer<Content: View>: View {
    var title: String
    var systemImage: String
    var hint: String?
    var required: Bool
    var content: Content

    init(
        title: String,
        systemImage: String,
        hint: String? = nil,
        required: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.hint = hint
        self.required = required
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label {
                    HStack(spacing: 2) {
                        Text(title)
                        if required {
                            Text("*")
                                .foregroundStyle(MegrumTheme.pink)
                        }
                    }
                } icon: {
                    Image(systemName: systemImage)
                }
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)

                Spacer(minLength: 8)

                if let hint {
                    Text(hint)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                }
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.58), lineWidth: 1)
        }
    }
}
