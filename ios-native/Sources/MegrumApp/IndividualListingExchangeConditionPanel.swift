import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingExchangeConditionPanel: View {
    var listing: IndividualListing
    var canEdit: Bool
    var onDelete: () -> Void

    private var extractedSummary: IndividualListingExchangeSummary? {
        IndividualListingExchangeSummary.extract(from: listing.note).summary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 34, height: 34)
                    .background(MegrumTheme.lavender.opacity(0.10), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("交換条件")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(extractedSummary.map { IndividualListingListPresentation.handoffMethodTitle(for: $0.handoffMethod) } ?? "未設定")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer()
            }

            if let summary = extractedSummary {
                VStack(spacing: 8) {
                    if let localDetail = summary.localDetailText {
                        IndividualListingExchangeConditionRow(
                            title: "現地",
                            detail: localDetail,
                            systemImage: "mappin.and.ellipse"
                        )
                    }

                    if let mailDetail = summary.mailDetailText {
                        IndividualListingExchangeConditionRow(
                            title: "郵送",
                            detail: mailDetail,
                            systemImage: "envelope"
                        )
                    }
                }
            } else {
                IndividualListingExchangeConditionRow(
                    title: "交換手段",
                    detail: "まだ保存されていません",
                    systemImage: "questionmark.circle"
                )
            }

            Divider()

            Text(extractedSummary?.acceptsOutsideCondition == false ? "条件外の打診は受け付けない" : "条件外の打診も受け付ける")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            if canEdit {
                Divider()

                Button(role: .destructive, action: onDelete) {
                    Text("この交換条件を削除")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.red)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.red.opacity(0.08), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("この交換条件を削除")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }
}

private struct IndividualListingExchangeConditionRow: View {
    var title: String
    var detail: String
    var systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 24, height: 24)
                .background(MegrumTheme.lavender.opacity(0.09), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                Text(detail)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(MegrumTheme.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
