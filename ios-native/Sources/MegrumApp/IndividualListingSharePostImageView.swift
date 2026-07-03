import MegrumDesign
import SwiftUI

struct IndividualListingShareRenderRow: Identifiable {
    var id: UUID
    var title: String
    var detail: String?
    var badge: String?
    var imageData: Data?
}

struct IndividualListingSharePostImageView: View {
    static let canvasSize = CGSize(width: 1_200, height: 1_500)

    var title: String
    var sectionTitle: String
    var rows: [IndividualListingShareRenderRow]
    var conditionLines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text(title)
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(sectionTitle)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .frame(height: 58)
                .background(MegrumTheme.lavender, in: Capsule())

            VStack(spacing: 18) {
                ForEach(rows.prefix(8)) { row in
                    IndividualListingSharePostRowView(row: row)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 12) {
                Text("条件")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                ForEach(conditionLines.prefix(5), id: \.self) { line in
                    Text(line)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MegrumTheme.sky.opacity(0.14), in: RoundedRectangle(cornerRadius: 28, style: .continuous))

            HStack(spacing: 14) {
                Spacer(minLength: 0)
                Image("MegrumBrandIcon", bundle: .main)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                Image("MegrumWordmark", bundle: .main)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170)
            }
        }
        .padding(.horizontal, 72)
        .padding(.top, 78)
        .padding(.bottom, 62)
        .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
        .background(.white)
        .accessibilityHidden(true)
    }
}

private struct IndividualListingSharePostRowView: View {
    var row: IndividualListingShareRenderRow

    var body: some View {
        HStack(spacing: 18) {
            GoodsSharePostTileArtwork(data: row.imageData)
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white, lineWidth: 4)
                }

            VStack(alignment: .leading, spacing: 9) {
                if let badge = row.badge, !badge.isEmpty {
                    Text(badge)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Text(row.title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.70)

                if let detail = row.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.68))
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .leading)
        .background(MegrumTheme.canvas, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1.5)
        }
    }
}
