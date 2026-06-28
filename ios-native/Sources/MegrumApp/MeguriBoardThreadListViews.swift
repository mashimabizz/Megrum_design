import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriBoardThreadListState: View {
    var threads: [BoardThread]
    var grooms: [GroomPost]
    var replyCounts: [UUID: Int]
    var isLoading: Bool
    var onOpenThread: (BoardThread) -> Void

    var body: some View {
        if isLoading {
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
        } else if threads.isEmpty {
            MeguriInlineEmptyState(
                systemImage: "bubble.left.and.bubble.right",
                title: "近くの話題はまだありません",
                message: "会場の状況や聞きたいことを投稿できます。"
            )
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    ForEach(Array(threads.enumerated()), id: \.element.id) { index, thread in
                        Button {
                            onOpenThread(thread)
                        } label: {
                            MeguriThreadListRow(
                                thread: thread,
                                grooms: grooms,
                                replyCount: max(replyCounts[thread.id, default: 0], thread.effectiveReplyCount),
                                index: index
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
