import MegrumDesign
import SwiftUI

struct MeguriLockedMessagePreview: View {
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<7, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(previewColor(for: index))
                    .frame(width: index.isMultiple(of: 3) ? 16 : 11, height: 12)
                    .blur(radius: 1.2)
                    .opacity(0.78)
            }

            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.leading, 2)
        }
        .frame(height: 18, alignment: .leading)
        .accessibilityHidden(true)
    }

    private func previewColor(for index: Int) -> Color {
        [MegrumTheme.sky, MegrumTheme.lavender, MegrumTheme.pink.opacity(0.72)][index % 3]
    }
}

struct MeguriLockedMessageBubbleContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .black))
                Text("Megrum プレミアムで表示")
                    .font(.system(size: 13, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)

            MeguriLockedMessageMosaicLines()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(width: 230, alignment: .leading)
        .background(
            LinearGradient(
                colors: [MegrumTheme.sky, MegrumTheme.lavender, MegrumTheme.pink.opacity(0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.42), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.lavender.opacity(0.22), radius: 14, y: 8)
    }
}

private struct MeguriLockedMessageMosaicLines: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<lineSegments(for: row), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(.white.opacity(0.76 - Double(index % 2) * 0.18))
                            .frame(width: segmentWidth(row: row, index: index), height: 10)
                            .blur(radius: 1.4)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func lineSegments(for row: Int) -> Int {
        row == 2 ? 5 : 7
    }

    private func segmentWidth(row: Int, index: Int) -> CGFloat {
        let widths: [[CGFloat]] = [
            [18, 9, 24, 13, 16, 11, 22],
            [12, 20, 10, 28, 15, 12, 18],
            [20, 12, 24, 10, 18]
        ]
        return widths[row][index]
    }
}
