import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalMeetupCalendarCandidateBlock: View {
    var draft: ProposalMeetupCandidateDraft
    var index: Int
    var isSelected: Bool
    var height: CGFloat
    var onTap: () -> Void
    var onMoveChanged: (DragGesture.Value) -> Void
    var onMoveEnded: (DragGesture.Value) -> Void
    var onResizeChanged: (DragGesture.Value) -> Void
    var onResizeEnded: (DragGesture.Value) -> Void
    var onRemove: () -> Void

    var body: some View {
        let candidateTitle = "候補\(index + 1)"
        let placeLabel = draft.normalizedPlaceName.isEmpty ? "場所未入力" : draft.normalizedPlaceName
        let editButtonHeight = max(18, height - 10)

        ZStack(alignment: .topTrailing) {
            ProposalMeetupCalendarCandidateBlockBackground(isSelected: isSelected)

            Button(action: onTap) {
                ProposalMeetupCalendarCandidateButtonContent(
                    candidateTitle: candidateTitle,
                    placeLabel: placeLabel
                )
            }
            .buttonStyle(.plain)
            .frame(height: editButtonHeight)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("proposalMeetupCalendar"))
                    .onChanged(onMoveChanged)
                    .onEnded(onMoveEnded)
            )
            .accessibilityLabel("候補\(index + 1)を編集")
            .zIndex(0)

            Rectangle()
                .fill(Color.white.opacity(0.7))
                .frame(height: 8)
                .frame(maxWidth: .infinity)
                .offset(y: max(0, height - 8))
                .overlay {
                    Capsule()
                        .fill(MegrumTheme.lavender.opacity(0.84))
                        .frame(width: 28, height: 4)
                }
                .contentShape(Rectangle())
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("proposalMeetupCalendar"))
                        .onChanged(onResizeChanged)
                        .onEnded(onResizeEnded)
                )
                .zIndex(2)

            ProposalMeetupCalendarCandidateRemoveButton(index: index, onRemove: onRemove)
                .zIndex(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct ProposalMeetupCalendarCandidateBlockBackground: View {
    var isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? MegrumTheme.lavender : MegrumTheme.sky)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(isSelected ? 0.9 : 0.62), lineWidth: isSelected ? 1.5 : 1)
        }
        .allowsHitTesting(false)
    }
}

private struct ProposalMeetupCalendarCandidateButtonContent: View {
    let candidateTitle: String
    let placeLabel: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.025))
            VStack(alignment: .leading, spacing: 4) {
                Text(candidateTitle)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(placeLabel)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }
}

private struct ProposalMeetupCalendarCandidateRemoveButton: View {
    let index: Int
    var onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(MegrumTheme.ink)
                .frame(width: 22, height: 22)
                .background(.white.opacity(0.92), in: Circle())
                .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .padding(4)
        .accessibilityLabel("候補\(index + 1)を削除")
    }
}

struct ProposalMeetupCalendarModeToggle: View {
    @Binding var selection: ProposalMeetupCalendarDisplayMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProposalMeetupCalendarDisplayMode.allCases) { mode in
                Button {
                    withAnimation(.snappy) {
                        selection = mode
                    }
                } label: {
                    Text(mode.title)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(selection == mode ? .white : MegrumTheme.muted)
                        .frame(width: 38, height: 30)
                        .background(selection == mode ? MegrumTheme.lavender : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("カレンダー\(mode.title)表示")
            }
        }
        .padding(3)
        .background(MegrumTheme.ink.opacity(0.07), in: Capsule())
    }
}

struct ProposalMeetupCalendarCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.62), lineWidth: 1)
        }
    }
}
