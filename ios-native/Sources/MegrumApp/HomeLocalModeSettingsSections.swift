import Foundation
import MegrumDesign
import SwiftUI

struct HomeLocalCarryingSelectionSection: View {
    var carryingCandidates: [HomeLocalCarryingCandidate]
    @Binding var selectedCarryingIDs: Set<UUID>

    var body: some View {
        Section {
            if carryingCandidates.isEmpty {
                Text("譲る候補なし")
                    .foregroundStyle(MegrumTheme.muted)
            } else {
                ForEach(carryingCandidates) { candidate in
                    Toggle(isOn: selectionBinding(for: candidate.id)) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(candidate.title)
                                .font(.body.weight(.semibold))
                            Text(candidate.subtitle)
                                .font(.caption)
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    }
                }
            }
        } header: {
            Text("持参するグッズ")
        }
    }

    private func selectionBinding(for id: UUID) -> Binding<Bool> {
        Binding {
            selectedCarryingIDs.contains(id)
        } set: { isSelected in
            if isSelected {
                selectedCarryingIDs.insert(id)
            } else {
                selectedCarryingIDs.remove(id)
            }
        }
    }
}
