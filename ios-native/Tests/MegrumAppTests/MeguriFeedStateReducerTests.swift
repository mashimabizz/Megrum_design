import MegrumApp
import MegrumCore
import XCTest

final class MeguriFeedStateReducerTests: XCTestCase {
    func testUpsertingGroomPostInsertsNewPostAtFront() {
        let existing = makeGroomPost(idSuffix: "001")
        let inserted = makeGroomPost(idSuffix: "002")

        let updated = MeguriFeedStateReducer.upsertingGroomPost(
            inserted,
            into: [existing]
        )

        XCTAssertEqual(updated, [inserted, existing])
    }

    func testUpsertingGroomPostReplacesExistingPostAndMovesToFront() {
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000001003")!
        let original = makeGroomPost(id: targetID, latitude: 35.0)
        let other = makeGroomPost(idSuffix: "004")
        let updatedPost = makeGroomPost(id: targetID, latitude: 36.0)

        let updated = MeguriFeedStateReducer.upsertingGroomPost(
            updatedPost,
            into: [other, original]
        )

        XCTAssertEqual(updated, [updatedPost, other])
    }

    func testUpsertingBoardThreadReplacesExistingThreadAndMovesToFront() {
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000001005")!
        let original = makeBoardThread(id: targetID, title: "古いスレッド")
        let other = makeBoardThread(idSuffix: "006", title: "そのまま")
        let updatedThread = makeBoardThread(id: targetID, title: "新しいスレッド")

        let updated = MeguriFeedStateReducer.upsertingBoardThread(
            updatedThread,
            into: [other, original]
        )

        XCTAssertEqual(updated, [updatedThread, other])
    }

    private func makeGroomPost(
        idSuffix: String,
        latitude: Double = 35.0
    ) -> GroomPost {
        makeGroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001\(idSuffix)")!,
            latitude: latitude
        )
    }

    private func makeGroomPost(
        id: UUID,
        latitude: Double = 35.0
    ) -> GroomPost {
        GroomPost(
            id: id,
            authorID: UUID(uuidString: "00000000-0000-0000-0000-000000001099")!,
            imageURL: URL(string: "https://example.com/groom.png")!,
            latitude: latitude,
            longitude: 139.0,
            createdAt: Date(timeIntervalSince1970: latitude)
        )
    }

    private func makeBoardThread(
        idSuffix: String,
        title: String
    ) -> BoardThread {
        makeBoardThread(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001\(idSuffix)")!,
            title: title
        )
    }

    private func makeBoardThread(
        id: UUID,
        title: String
    ) -> BoardThread {
        BoardThread(
            id: id,
            authorID: UUID(uuidString: "00000000-0000-0000-0000-000000001098")!,
            title: title,
            body: "本文",
            audience: .nearby3km,
            latitude: 35.0,
            longitude: 139.0,
            prefecture: "東京都",
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }
}
