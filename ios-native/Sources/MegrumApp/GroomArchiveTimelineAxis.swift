import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomArchiveTimelineAxis: View {
    var grooms: [GroomPost]
    var focusedGroomID: UUID?
    var onFocus: (GroomPost) -> Void

    private var chronologicalGrooms: [GroomPost] {
        grooms.sorted { first, second in
            if first.createdAt == second.createdAt {
                return first.id.uuidString < second.id.uuidString
            }
            return first.createdAt < second.createdAt
        }
    }

    var body: some View {
        if !chronologicalGrooms.isEmpty {
            GeometryReader { proxy in
                let layout = GroomArchiveTimelineAxisLayout(size: proxy.size, itemCount: chronologicalGrooms.count)

                ZStack(alignment: .topTrailing) {
                    ForEach(Array(chronologicalGrooms.enumerated()), id: \.element.id) { index, groom in
                        let y = layout.yPosition(for: index)
                        let isFocused = groom.id == focusedGroomID

                        if index == 0 {
                            Capsule()
                                .fill(MegrumTheme.lavender)
                                .frame(width: 42, height: 4)
                                .position(x: layout.axisX - 21, y: y)
                                .allowsHitTesting(false)
                        }

                        Button {
                            onFocus(groom)
                        } label: {
                            GroomArchiveTimelineTick(isFocused: isFocused, isFirst: index == 0)
                        }
                        .buttonStyle(.plain)
                        .position(x: layout.axisX, y: y)
                        .accessibilityLabel(groom.createdAt.formatted(date: .abbreviated, time: .omitted))
                    }

                    if let focusedGroom {
                        GroomArchiveTimelineDateBadge(date: focusedGroom.createdAt)
                            .position(x: layout.badgeX, y: layout.yPosition(for: focusedIndex))
                            .transition(.opacity.combined(with: .scale(scale: 0.92)))
                            .allowsHitTesting(false)
                    }
                }
                .animation(.spring(response: 0.24, dampingFraction: 0.86), value: focusedGroomID)
            }
            .frame(width: 150)
            .accessibilityElement(children: .contain)
        }
    }

    private var focusedIndex: Int {
        guard let focusedGroomID,
              let index = chronologicalGrooms.firstIndex(where: { $0.id == focusedGroomID })
        else {
            return chronologicalGrooms.count - 1
        }
        return index
    }

    private var focusedGroom: GroomPost? {
        guard focusedGroomID != nil else {
            return nil
        }
        if chronologicalGrooms.indices.contains(focusedIndex) {
            return chronologicalGrooms[focusedIndex]
        }
        return nil
    }

}

private struct GroomArchiveTimelineAxisLayout {
    var size: CGSize
    var itemCount: Int

    var axisX: CGFloat {
        max(44, size.width - 28)
    }

    var badgeX: CGFloat {
        max(48, axisX - 74)
    }

    var verticalInset: CGFloat {
        itemCount <= 2 ? 54 : 26
    }

    func yPosition(for index: Int) -> CGFloat {
        guard itemCount > 1 else {
            return size.height / 2
        }
        let availableHeight = max(size.height - verticalInset * 2, 1)
        return verticalInset + availableHeight * CGFloat(index) / CGFloat(itemCount - 1)
    }

}

private struct GroomArchiveTimelineTick: View {
    var isFocused: Bool
    var isFirst: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isFocused ? MegrumTheme.lavender : .white)
                .frame(width: isFirst ? 18 : 14, height: isFirst ? 18 : 14)
                .overlay {
                    Circle()
                        .stroke(isFocused ? .white : MegrumTheme.ink.opacity(0.18), lineWidth: isFocused ? 3 : 1)
                }
                .shadow(color: MegrumTheme.ink.opacity(isFocused ? 0.24 : 0.10), radius: isFocused ? 10 : 4, y: 4)
        }
        .frame(width: 44, height: 44)
        .contentShape(Circle())
    }
}

private struct GroomArchiveTimelineDateBadge: View {
    var date: Date

    var body: some View {
        Text(date.formatted(.dateTime.month().day()))
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.72), lineWidth: 1))
            .shadow(color: MegrumTheme.ink.opacity(0.14), radius: 12, y: 7)
    }
}
