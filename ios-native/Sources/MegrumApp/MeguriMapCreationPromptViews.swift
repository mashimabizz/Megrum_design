import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriMapCreationDropPin: View {
    @State private var hasDropped = false

    var body: some View {
        VStack(spacing: 0) {
            Text("Mg")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.sky, MegrumTheme.lavender, MegrumTheme.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white, lineWidth: 3)
                }
                .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 12, y: 8)

            CreationPromptTriangle()
                .fill(.white)
                .frame(width: 14, height: 8)
                .offset(y: -1)
        }
        .offset(y: hasDropped ? 0 : -78)
        .opacity(hasDropped ? 1 : 0.18)
        .scaleEffect(hasDropped ? 1 : 0.88, anchor: .bottom)
        .onAppear {
            hasDropped = false
            withAnimation(.interpolatingSpring(stiffness: 250, damping: 17).delay(0.02)) {
                hasDropped = true
            }
        }
        .accessibilityHidden(true)
    }
}

struct MeguriMapCreationPromptLayout {
    static let calloutSize = CGSize(width: 236, height: 126)
    private static let horizontalMargin: CGFloat = 18
    private static let verticalTopMargin: CGFloat = 164
    private static let verticalBottomReserved: CGFloat = 220
    private static let horizontalOffset: CGFloat = 168
    private static let verticalOffset: CGFloat = 144
    private static let sideYOffset: CGFloat = 36
    private static let controlAvoidancePadding: CGFloat = 10
    private static let pinAvoidanceSize = CGSize(width: 84, height: 116)

    static func placement(for point: CGPoint, in size: CGSize) -> MeguriMapCreationPromptPlacement {
        bestCandidate(for: point, in: size).placement
    }

    static func position(for point: CGPoint, in size: CGSize) -> CGPoint {
        bestCandidate(for: point, in: size).center
    }

    static func calloutFrame(for point: CGPoint, in size: CGSize) -> CGRect {
        frame(centeredAt: position(for: point, in: size))
    }

    static func pointerOffset(for point: CGPoint, in size: CGSize) -> CGFloat {
        let candidate = bestCandidate(for: point, in: size)
        switch candidate.placement {
        case .leading, .trailing:
            let maximumOffset = calloutSize.height / 2 - 30
            return clamp(sidePointerTargetY(for: point) - candidate.center.y, lower: -maximumOffset, upper: maximumOffset)
        case .above, .below:
            let maximumOffset = calloutSize.width / 2 - 42
            return clamp(point.x - candidate.center.x, lower: -maximumOffset, upper: maximumOffset)
        }
    }

    static func pinAvoidanceFrame(for point: CGPoint) -> CGRect {
        CGRect(
            x: point.x - pinAvoidanceSize.width / 2,
            y: point.y - pinAvoidanceSize.height + 12,
            width: pinAvoidanceSize.width,
            height: pinAvoidanceSize.height
        )
    }

    private static func sidePointerTargetY(for point: CGPoint) -> CGFloat {
        point.y - 36
    }

    private static func bestCandidate(for point: CGPoint, in size: CGSize) -> CalloutCandidate {
        let candidates = [
            makeCandidate(
                placement: .leading,
                proposedCenter: CGPoint(x: point.x - horizontalOffset, y: point.y - sideYOffset),
                point: point,
                in: size
            ),
            makeCandidate(
                placement: .trailing,
                proposedCenter: CGPoint(x: point.x + horizontalOffset, y: point.y - sideYOffset),
                point: point,
                in: size
            ),
            makeCandidate(
                placement: .above,
                proposedCenter: CGPoint(x: point.x, y: point.y - verticalOffset),
                point: point,
                in: size
            ),
            makeCandidate(
                placement: .below,
                proposedCenter: CGPoint(x: point.x, y: point.y + verticalOffset),
                point: point,
                in: size
            )
        ]

        return candidates.min { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.placement.preference < rhs.placement.preference
            }
            return lhs.score < rhs.score
        } ?? candidates[0]
    }

    private static func makeCandidate(
        placement: MeguriMapCreationPromptPlacement,
        proposedCenter: CGPoint,
        point: CGPoint,
        in size: CGSize
    ) -> CalloutCandidate {
        let center = adjustedCenterAvoidingControls(
            proposedCenter,
            in: size
        )
        let frame = frame(centeredAt: center)
        let overlapPenalty = overlapArea(frame, pinAvoidanceFrame(for: point)) * 8
            + controlAvoidanceFrames(in: size).reduce(CGFloat.zero) { partial, avoidanceFrame in
                partial + overlapArea(frame, avoidanceFrame) * 6
            }
        let movementPenalty = abs(center.x - proposedCenter.x) * 0.8 + abs(center.y - proposedCenter.y) * 0.8
        let placementPenalty = CGFloat(placement.preference) * 18

        return CalloutCandidate(
            placement: placement,
            center: center,
            score: overlapPenalty + movementPenalty + placementPenalty
        )
    }

    private static func adjustedCenterAvoidingControls(_ proposedCenter: CGPoint, in size: CGSize) -> CGPoint {
        let bounds = centerBounds(in: size)
        var center = CGPoint(
            x: clamp(proposedCenter.x, lower: bounds.minX, upper: bounds.maxX),
            y: clamp(proposedCenter.y, lower: bounds.minY, upper: bounds.maxY)
        )

        for avoidanceFrame in controlAvoidanceFrames(in: size) {
            let calloutFrame = frame(centeredAt: center)
            guard overlapArea(calloutFrame, avoidanceFrame) > 0 else {
                continue
            }

            let shiftedX = avoidanceFrame.maxX + controlAvoidancePadding + calloutSize.width / 2
            center.x = clamp(max(center.x, shiftedX), lower: bounds.minX, upper: bounds.maxX)
        }

        return center
    }

    private static func centerBounds(in size: CGSize) -> CGRect {
        let minimumX = horizontalMargin + calloutSize.width / 2
        let maximumX = max(minimumX, size.width - horizontalMargin - calloutSize.width / 2)
        let minimumY = max(verticalTopMargin + calloutSize.height / 2, horizontalMargin + calloutSize.height / 2)
        let maximumY = max(minimumY, size.height - verticalBottomReserved - calloutSize.height / 2)

        return CGRect(
            x: minimumX,
            y: minimumY,
            width: maximumX - minimumX,
            height: maximumY - minimumY
        )
    }

    private static func controlAvoidanceFrames(in size: CGSize) -> [CGRect] {
        [
            CGRect(x: 0, y: 64, width: 164, height: 96),
            CGRect(
                x: 0,
                y: max(180, size.height - verticalBottomReserved - 250),
                width: 138,
                height: 250
            )
        ]
    }

    private static func frame(centeredAt center: CGPoint) -> CGRect {
        CGRect(
            x: center.x - calloutSize.width / 2,
            y: center.y - calloutSize.height / 2,
            width: calloutSize.width,
            height: calloutSize.height
        )
    }

    private static func overlapArea(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull, !intersection.isEmpty else {
            return 0
        }
        return intersection.width * intersection.height
    }

    private static func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        min(max(value, lower), upper)
    }

    private struct CalloutCandidate {
        var placement: MeguriMapCreationPromptPlacement
        var center: CGPoint
        var score: CGFloat
    }
}

enum MeguriMapCreationPromptPlacement {
    case leading
    case trailing
    case above
    case below

    var scaleAnchor: UnitPoint {
        switch self {
        case .leading:
            .trailing
        case .trailing:
            .leading
        case .above:
            .bottom
        case .below:
            .top
        }
    }

    var preference: Int {
        switch self {
        case .leading, .trailing:
            0
        case .above:
            1
        case .below:
            2
        }
    }
}

struct MeguriMapCreationPromptCallout: View {
    var placement: MeguriMapCreationPromptPlacement
    var pointerOffset: CGFloat
    var onCreateGroom: () -> Void
    var onCreateThread: () -> Void

    @State private var isVisible = false

    var body: some View {
        calloutWithPointer
        .frame(width: MeguriMapCreationPromptLayout.calloutSize.width)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.96, anchor: placement.scaleAnchor)
        .animation(.easeOut(duration: 0.18), value: isVisible)
        .onAppear {
            isVisible = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                withAnimation(.easeOut(duration: 0.18)) {
                    isVisible = true
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("作成しますか？ グルーム・チャット")
    }

    @ViewBuilder
    private var calloutWithPointer: some View {
        switch placement {
        case .leading, .trailing:
            HStack(spacing: 0) {
                if placement == .trailing {
                    CreationPromptSideTriangle(placement: .trailing)
                        .fill(.white.opacity(0.97))
                        .frame(width: 10, height: 18)
                        .offset(y: pointerOffset)
                }

                calloutBody

                if placement == .leading {
                    CreationPromptSideTriangle(placement: .leading)
                        .fill(.white.opacity(0.97))
                        .frame(width: 10, height: 18)
                        .offset(y: pointerOffset)
                }
            }
        case .above:
            VStack(spacing: 0) {
                calloutBody
                CreationPromptSideTriangle(placement: .above)
                    .fill(.white.opacity(0.97))
                    .frame(width: 18, height: 10)
                    .offset(x: pointerOffset)
            }
        case .below:
            VStack(spacing: 0) {
                CreationPromptSideTriangle(placement: .below)
                    .fill(.white.opacity(0.97))
                    .frame(width: 18, height: 10)
                    .offset(x: pointerOffset)
                calloutBody
            }
        }
    }

    private var calloutBody: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("作成しますか？")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text("グルーム・チャット")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                HStack(spacing: 8) {
                    promptActionButton(
                        title: "グルーム",
                        systemImage: "camera.fill",
                        tint: MegrumTheme.lavender,
                        action: onCreateGroom
                    )
                    promptActionButton(
                        title: "チャット",
                        systemImage: "bubble.left.and.bubble.right.fill",
                        tint: MegrumTheme.sky,
                        action: onCreateThread
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(width: 226)
            .background(.white.opacity(0.97), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.14), radius: 18, y: 10)
        }
    }

    private func promptActionButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label {
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
            } icon: {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .black))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(tint.opacity(0.13), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tint.opacity(0.28), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct CreationPromptSideTriangle: Shape {
    var placement: MeguriMapCreationPromptPlacement

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch placement {
        case .leading:
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        case .trailing:
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        case .above:
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        case .below:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

private struct CreationPromptTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

extension MegrumLocationCoordinate {
    var creationPromptID: String {
        "\(latitude):\(longitude)"
    }
}
