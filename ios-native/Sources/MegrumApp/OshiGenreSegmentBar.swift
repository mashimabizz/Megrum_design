import Foundation
import MegrumDesign
import SwiftUI

struct OshiGenreSegmentBar: View {
    var options: [OshiCategoryOption]
    @Binding var selection: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button {
                        withAnimation(.snappy(duration: 0.16)) {
                            selection = option.id
                        }
                    } label: {
                        Text(option.title)
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .foregroundStyle(selection == option.id ? .white : MegrumTheme.ink.opacity(0.78))
                            .padding(.horizontal, 15)
                            .frame(minWidth: OshiMasterSelectLayoutMetrics.genreSegmentMinWidth)
                            .frame(height: OshiMasterSelectLayoutMetrics.genreSegmentHeight - 6)
                            .background {
                                if selection == option.id {
                                    Capsule().fill(MegrumTheme.primaryGradient)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.title)

                    if index < options.count - 1 {
                        Rectangle()
                            .fill(.black.opacity(0.08))
                            .frame(width: 0.5, height: 18)
                            .padding(.horizontal, 2)
                    }
                }
            }
            .padding(3)
            .background(.white.opacity(0.94), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.black.opacity(0.08), lineWidth: 1)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 1)
        }
    }
}
