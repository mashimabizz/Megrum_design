import Foundation
import SwiftUI

struct ProposalMeetupCalendarRenderedCandidateBlock: Identifiable {
    var draft: ProposalMeetupCandidateDraft
    var index: Int
    var isSelected: Bool
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    var id: UUID {
        draft.id
    }
}

struct ProposalMeetupCalendarWeekCandidateBlocks: View {
    var blocks: [ProposalMeetupCalendarRenderedCandidateBlock]
    var onTap: (Int) -> Void
    var onChange: (DragGesture.Value, Int, ProposalMeetupCalendarCandidateEditAction) -> Void
    var onEnd: (DragGesture.Value, Int, ProposalMeetupCalendarCandidateEditAction) -> Void
    var onRemove: (Int) -> Void

    var body: some View {
        ForEach(blocks) { block in
            ProposalMeetupCalendarCandidateBlock(
                draft: block.draft,
                index: block.index,
                isSelected: block.isSelected,
                height: block.height,
                onTap: {
                    onTap(block.index)
                },
                onMoveChanged: { value in
                    onChange(value, block.index, .move)
                },
                onMoveEnded: { value in
                    onEnd(value, block.index, .move)
                },
                onResizeChanged: { value in
                    onChange(value, block.index, .resizeEnd)
                },
                onResizeEnded: { value in
                    onEnd(value, block.index, .resizeEnd)
                },
                onRemove: {
                    onRemove(block.index)
                }
            )
            .frame(width: block.width, height: block.height)
            .position(x: block.x + block.width / 2, y: block.y + block.height / 2)
        }
    }
}
