@testable import MegrumApp
import CoreGraphics
import XCTest

final class MegrumInteractionFeedbackTests: XCTestCase {
    func testInteractionFeedbackPresentationStateAddsAndRemovesRipples() {
        var state = MegrumInteractionFeedbackPresentationState()

        let first = state.addRipple(at: CGPoint(x: 12, y: 24))
        let second = state.addRipple(at: CGPoint(x: 36, y: 48))

        XCTAssertEqual(state.ripples, [first, second])

        state.removeRipple(id: first.id)

        XCTAssertEqual(state.ripples, [second])

        state.removeRipple(id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!)

        XCTAssertEqual(state.ripples, [second])
    }

    func testTapRippleAnimationStateResolvesScaleOpacityAndDiameter() {
        var state = MegrumTapRippleAnimationState()

        XCTAssertEqual(state.diameter(reduceMotion: false), 174)
        XCTAssertEqual(state.diameter(reduceMotion: true), 64)
        XCTAssertEqual(state.scale(reduceMotion: false), 0.22)
        XCTAssertEqual(state.scale(reduceMotion: true), 0.98)
        XCTAssertEqual(state.opacity, 1)

        state.finish()

        XCTAssertEqual(state.scale(reduceMotion: false), 1.3)
        XCTAssertEqual(state.scale(reduceMotion: true), 0.98)
        XCTAssertEqual(state.opacity, 0)
    }
}
