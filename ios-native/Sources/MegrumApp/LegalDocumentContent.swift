import MegrumDesign
import SwiftUI

struct LegalDocumentContent: View {
    var kind: LegalDocumentKind

    var body: some View {
        List {
            statusSection
            summarySection
            contactSection
        }
    }

    private var statusSection: some View {
        Section {
            Text(kind.statusMessage)
                .font(.body)
                .foregroundStyle(MegrumTheme.ink)
                .padding(.vertical, 4)
        } header: {
            Text("ステータス")
        }
    }

    private var summarySection: some View {
        Section {
            ForEach(kind.summaryItems) { item in
                LegalSummaryRow(item: item)
            }
        } header: {
            Text("主要項目")
        }
    }

    private var contactSection: some View {
        Section {
            Text("support@megrum.jp")
                .font(.body.weight(.semibold))
                .foregroundStyle(MegrumTheme.lavender)
                .textSelection(.enabled)
        } header: {
            Text("問い合わせ先")
        }
    }
}

struct LegalSummaryItem: Identifiable, Equatable {
    var title: String
    var body: String

    var id: String { title }
}

private struct LegalSummaryRow: View {
    var item: LegalSummaryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(MegrumTheme.ink)
            Text(item.body)
                .font(.subheadline)
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.title)
        .accessibilityHint(item.body)
    }
}
