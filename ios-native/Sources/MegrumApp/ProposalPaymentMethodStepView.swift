import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalPaymentMethodStepView: View {
    var sections: [(section: ProposalPaymentOptionSection, options: [ProposalPaymentOption])]
    @Binding var selectedOptionID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(sections, id: \.section) { section in
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.section.title)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    VStack(spacing: 0) {
                        ForEach(Array(section.options.enumerated()), id: \.element.id) { index, option in
                            ProposalPaymentOptionRow(
                                option: option,
                                isSelected: selectedOptionID == option.id,
                                onSelect: {
                                    selectedOptionID = option.id
                                    MegrumHaptics.selectionChanged()
                                }
                            )
                            if index < section.options.count - 1 {
                                Divider()
                                    .padding(.leading, 112)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
                    }
                }
            }
        }
        .onAppear(perform: selectFirstIfNeeded)
    }

    private func selectFirstIfNeeded() {
        let options = sections.flatMap(\.options)
        guard !options.isEmpty else {
            selectedOptionID = nil
            return
        }
        if let selectedOptionID, options.contains(where: { $0.id == selectedOptionID }) {
            return
        }
        selectedOptionID = options.first?.id
    }
}
