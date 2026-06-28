import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomArchiveStoryScreen: View {
    var grooms: [GroomPost]
    var initialGroom: GroomPost
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var dragOffset: CGSize = .zero
    @State private var showsInsights = false

    init(grooms: [GroomPost], initialGroom: GroomPost, appState: MegrumAppState) {
        let sortedGrooms = GroomArchiveOrdering.sorted(grooms.isEmpty ? [initialGroom] : grooms)
        self.grooms = sortedGrooms
        self.initialGroom = initialGroom
        self.appState = appState
        _currentIndex = State(initialValue: sortedGrooms.firstIndex(where: { $0.id == initialGroom.id }) ?? 0)
    }

    private var currentGroom: GroomPost {
        grooms[max(0, min(currentIndex, grooms.count - 1))]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: currentGroom.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .id(currentGroom.id)
                case .failure:
                    GroomImageFailureView(message: "画像を読み込めませんでした", foregroundColor: .white)
                default:
                    ProgressView()
                        .tint(.white)
                        .controlSize(.large)
                }
            }
            .padding(.horizontal, 8)
            .offset(y: dragOffset.height * 0.20)
            .scaleEffect(max(0.92, 1 - abs(dragOffset.height) / 900))

            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { move(by: -1) }

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { move(by: 1) }
            }

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    ForEach(grooms.indices, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentIndex ? .white : .white.opacity(0.28))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentGroom.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                        Text("上にスワイプで反応を見る")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .opacity(0.72)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.28), in: Capsule())

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.28), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("閉じる")
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

                Spacer()

                GroomArchiveInsightPill(
                    likeCount: appState.groomReactions(for: currentGroom.id).count,
                    commentCount: appState.groomReplies(for: currentGroom.id).count,
                    action: { showsInsights = true }
                )
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    if value.translation.height < -76 {
                        showsInsights = true
                    } else if value.translation.height > 110 {
                        dismiss()
                    }
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        dragOffset = .zero
                    }
                }
        )
        .sheet(isPresented: $showsInsights) {
            GroomArchiveInsightsSheet(groom: currentGroom, appState: appState)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func move(by delta: Int) {
        let nextIndex = currentIndex + delta
        guard grooms.indices.contains(nextIndex) else {
            if delta > 0 {
                dismiss()
            }
            return
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            currentIndex = nextIndex
        }
    }
}
