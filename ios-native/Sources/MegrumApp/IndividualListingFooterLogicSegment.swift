import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingFooterLogicSegment: View {
    @Binding var selection: ListingLogic
    @Binding var minimumCount: Int
    var selectedCount: Int
    var allowsMinimumLogic: Bool
    var showsSingleChoiceButton: Bool
    var allTitle: String
    @State private var showsMinimumPicker = false

    var body: some View {
        HStack(spacing: 0) {
            if showsSingleChoiceButton {
                logicButton(.one, title: "どれか1つだけ")
            }
            if allowsMinimumLogic {
                logicButton(.atLeast, title: minimumTitle)
            }
            logicButton(.all, title: allTitle)
        }
        .padding(3)
        .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
        }
    }

    private func logicButton(_ logic: ListingLogic, title: String) -> some View {
        let button = Button {
            withAnimation(.smooth(duration: 0.18)) {
                if logic == .atLeast {
                    selection = .atLeast
                    showsMinimumPicker = true
                } else {
                    selection = logic
                }
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(selection == logic ? .white : MegrumTheme.ink.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background {
                    if selection == logic {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(MegrumTheme.lavender)
                    }
                }
        }
        .buttonStyle(.plain)

        return Group {
            if logic == .atLeast {
                button
                    .popover(isPresented: $showsMinimumPicker, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
                        minimumPicker
                    }
            } else {
                button
            }
        }
    }

    private var minimumTitle: String {
        ListingLogic.minimumCountTitle(minimumCount)
    }

    private var minimumPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("何個以上にしますか？")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            ForEach(minimumChoices, id: \.self) { count in
                Button {
                    minimumCount = count
                    selection = .atLeast
                    showsMinimumPicker = false
                } label: {
                    HStack(spacing: 8) {
                        Text(ListingLogic.minimumCountTitle(count))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Spacer(minLength: 0)
                        if selection == .atLeast && minimumCount == count {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .black))
                        }
                    }
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(minWidth: 142, alignment: .leading)
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .background(
                        selection == .atLeast && minimumCount == count
                            ? MegrumTheme.lavender.opacity(0.12)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .presentationCompactAdaptation(.popover)
    }

    private var minimumChoices: [Int] {
        guard selectedCount >= 2 else {
            return []
        }
        return Array(1...selectedCount)
    }
}
