import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalGoodsFilterBar: View {
    var groupChoices: [ProposalFilterChoice]
    var goodsTypeChoices: [ProposalFilterChoice]
    @Binding var selectedGroupID: UUID?
    @Binding var selectedGoodsTypeID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: ProposalGoodsFilterMetrics.rowSpacing) {
            ProposalFilterRow(
                title: "推し",
                choices: groupChoices,
                selectedID: $selectedGroupID
            )
            ProposalFilterRow(
                title: "種別",
                choices: goodsTypeChoices,
                selectedID: $selectedGoodsTypeID
            )
        }
    }
}

struct ProposalFilterChoice: Identifiable, Equatable {
    var id: UUID
    var title: String
}

private struct ProposalFilterRow: View {
    var title: String
    var choices: [ProposalFilterChoice]
    @Binding var selectedID: UUID?

    var body: some View {
        if !choices.isEmpty {
            HStack(alignment: .center, spacing: ProposalGoodsFilterMetrics.chipSpacing) {
                Text(title)
                    .font(.system(size: ProposalGoodsFilterMetrics.labelFontSize, weight: .black, design: .rounded))
                    .tracking(ProposalGoodsFilterMetrics.labelTracking)
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(width: ProposalGoodsFilterMetrics.labelWidth, alignment: .trailing)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ProposalGoodsFilterMetrics.chipSpacing) {
                        ProposalFilterChip(title: "すべて", isSelected: selectedID == nil) {
                            selectedID = nil
                        }
                        ForEach(choices) { choice in
                            ProposalFilterChip(title: choice.title, isSelected: selectedID == choice.id) {
                                selectedID = choice.id
                            }
                        }
                    }
                    .padding(.vertical, 1)
                }
            }
        }
    }
}

private struct ProposalFilterChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: ProposalGoodsFilterMetrics.chipFontSize, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .padding(.horizontal, ProposalGoodsFilterMetrics.chipHorizontalPadding)
                .padding(.vertical, ProposalGoodsFilterMetrics.chipVerticalPadding)
                .background(isSelected ? MegrumTheme.lavender : Color.white.opacity(0.74), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? MegrumTheme.lavender.opacity(0.5) : .white.opacity(0.68), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
